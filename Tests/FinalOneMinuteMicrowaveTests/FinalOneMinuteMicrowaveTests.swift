/*
 * FinalOneMinuteMicrowaveTests.swift
 * VerificationTests
 *
 * Created by Callum McColl on 20/04/22.
 * Copyright © 2022 Callum McColl. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. All advertising materials mentioning features or use of this
 *    software must display the following acknowledgement:
 *
 *        This product includes software developed by Callum McColl.
 *
 * 4. Neither the name of the author nor the names of contributors
 *    may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * -----------------------------------------------------------------------
 * This program is free software; you can redistribute it and/or
 * modify it under the above terms or under the terms of the GNU
 * General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/
 * or write to the Free Software Foundation, Inc., 51 Franklin Street,
 * Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

import XCTest

import Gateways
import Timers
import KripkeStructure
import KripkeStructureViews
import swiftfsm
import SharedVariables

@testable import FinalOneMinuteMicrowave
@testable import Verification

class FinalOneMinuteMicrowaveTests: XCTestCase {

    var readableName: String {
        self.name.dropFirst(2).dropLast().components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
    }

    var originalPath: String!

    var testFolder: URL!

    override func setUpWithError() throws {
        let fm = FileManager.default
        originalPath = fm.currentDirectoryPath
        let filePath = URL(fileURLWithPath: #filePath, isDirectory: false)
        testFolder = filePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("kripke_structures", isDirectory: true)
            .appendingPathComponent(readableName, isDirectory: true)
        _ = try? fm.removeItem(atPath: testFolder.path)
        try fm.createDirectory(at: testFolder, withIntermediateDirectories: true)
        fm.changeCurrentDirectoryPath(testFolder.path)
    }

    override func tearDownWithError() throws {
        let fm = FileManager.default
        fm.changeCurrentDirectoryPath(originalPath)
    }

    func test_separate() {
        let gateway = StackGateway()
        let gap: UInt = 10
        let length: UInt = 80 + 50 + 30 + 30
        let cycleLength = gap * 4 + length
        let clock = FSMClock(
            ringletLengths: ["Timer": 80, "Alarm": 50, "Cooking": 30, "Light": 30],
            scheduleLength: cycleLength
        )
        let timer = AnyControllableFiniteStateMachine(TimerFiniteStateMachine(
            name: "Timer",
            buttonPushed: .buttonPushed,
            doorOpen: .doorOpen,
            timeLeft: .timeLeft,
            clock: clock
        ))
        let alarm = AnyControllableFiniteStateMachine(AlarmFiniteStateMachine(
            name: "Alarm",
            timeLeft: .timeLeft,
            sound: .sound,
            clock: clock
        ))
        let cooking = AnyControllableFiniteStateMachine(CookingFiniteStateMachine(
            name: "Cooking",
            doorOpen: .doorOpen,
            timeLeft: .timeLeft,
            motor: .motor
        ))
        let light = AnyControllableFiniteStateMachine(LightFiniteStateMachine(
            name: "Light",
            doorOpen: .doorOpen,
            timeLeft: .timeLeft,
            light: .light
        ))
        let machines: [(FSMType, UInt)] = [
            (.controllableFSM(timer), 80),
            (.controllableFSM(alarm), 50),
            (.controllableFSM(cooking), 30),
            (.controllableFSM(light), 30)
        ]
        let threads: [IsolatedThread] = machines.enumerated().map { (index: Int, machine: (FSMType, UInt)) in
            IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: UInt(index) * 10 + UInt(index) * machine.1,
                            step: .takeSnapshotAndStartTimeslot(
                                timeslot: Timeslot(
                                    fsms: [machine.0.name],
                                    callChain: CallChain(root: machine.0.name, calls: []),
                                    externalDependencies: [],
                                    startingTime: UInt(index) * gap + UInt(index) * machine.1,
                                    duration: machine.1,
                                    cyclesExecuted: 0
                                )
                            )
                        ),
                        VerificationMap.Step(
                            time: UInt(index) * 10 + UInt(index) * machine.1 + machine.1,
                            step: .executeAndSaveSnapshot(
                                timeslot: Timeslot(
                                    fsms: [machine.0.name],
                                    callChain: CallChain(root: machine.0.name, calls: []),
                                    externalDependencies: [],
                                    startingTime: UInt(index) * gap + UInt(index) * machine.1,
                                    duration: machine.1,
                                    cyclesExecuted: 0
                                )
                            )
                        )
                    ],
                    delegates: []
                ),
                pool: FSMPool(fsms: [machine.0], parameterisedFSMs: [])
            )
        }
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                parameterisedThreads: [:],
                cycleLength: cycleLength
            )
        )
        let viewFactory = AggregateKripkeStructureViewFactory(factories: [
            AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory()),
            AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory())
        ])
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: testFolder.path)
        do {
            try verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
                try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_canGenerateCombinedMicrowaveMachines() {
        let gateway = StackGateway()
        let gap: UInt = 10
        let length: UInt = 80 + 50 + 30 + 30
        let cycleLength = gap * 4 + length
        let clock = FSMClock(
            ringletLengths: ["Timer": 80, "Alarm": 50, "Cooking": 30, "Light": 30],
            scheduleLength: cycleLength
        )
        let timer = AnyControllableFiniteStateMachine(TimerFiniteStateMachine(
            name: "Timer",
            buttonPushed: .buttonPushed,
            doorOpen: .doorOpen,
            timeLeft: .timeLeft,
            clock: clock
        ))
        let alarm = AnyControllableFiniteStateMachine(AlarmFiniteStateMachine(
            name: "Alarm",
            timeLeft: .timeLeft,
            sound: .sound,
            clock: clock
        ))
        let cooking = AnyControllableFiniteStateMachine(CookingFiniteStateMachine(
            name: "Cooking",
            doorOpen: .doorOpen,
            timeLeft: .timeLeft,
            motor: .motor
        ))
        let light = AnyControllableFiniteStateMachine(LightFiniteStateMachine(
            name: "Light",
            doorOpen: .doorOpen,
            timeLeft: .timeLeft,
            light: .light
        ))
        let machines: [(FSMType, UInt)] = [
            (.controllableFSM(timer), 80),
            (.controllableFSM(alarm), 50),
            (.controllableFSM(cooking), 30),
            (.controllableFSM(light), 30)
        ]
        let steps: [VerificationMap.Step] = machines.enumerated().flatMap { (index: Int, machine: (FSMType, UInt)) -> [VerificationMap.Step] in
            [
                VerificationMap.Step(
                    time: gap * UInt(index) + machine.1 * UInt(index),
                    step: .takeSnapshotAndStartTimeslot(
                        timeslot: Timeslot(
                            fsms: [machine.0.name],
                            callChain: CallChain(root: machine.0.name, calls: []),
                            externalDependencies: [],
                            startingTime: gap * UInt(index) + machine.1 * UInt(index),
                            duration: machine.1,
                            cyclesExecuted: 0
                        )
                    )
                ),
                VerificationMap.Step(
                    time: gap * UInt(index) + machine.1 * UInt(index) + machine.1,
                    step: .executeAndSaveSnapshot(
                        timeslot: Timeslot(
                            fsms: [machine.0.name],
                            callChain: CallChain(root: machine.0.name, calls: []),
                            externalDependencies: [],
                            startingTime: gap * UInt(index) + machine.1 * UInt(index),
                            duration: machine.1,
                            cyclesExecuted: 0
                        )
                    )
                )
            ]
        }
        let threads = [
            IsolatedThread(
                map: VerificationMap(
                    steps: steps,
                    delegates: []
                ),
                pool: FSMPool(fsms: machines.map(\.0), parameterisedFSMs: [])
            )
        ]
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                parameterisedThreads: [:],
                cycleLength: cycleLength
            )
        )
        let viewFactory = GraphVizKripkeStructureViewFactory()
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: testFolder.path)
        do {
            try verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
                try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
