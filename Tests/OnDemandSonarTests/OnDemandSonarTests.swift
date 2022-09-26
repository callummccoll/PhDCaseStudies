/*
 * SonarTests.swift
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

@testable import OnDemandSonar
@testable import Verification

class OnDemandSonarTests: XCTestCase {
    
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
    
    func test_separate() async {
        let gateway = StackGateway()
        let timeslotLength: UInt = 244
        let clock = FSMClock(
            ringletLengths: [
                "Caller": timeslotLength,
                "Sonar23": timeslotLength,
                "Sonar45": timeslotLength,
                "Sonar67": timeslotLength,
            ],
            scheduleLength: timeslotLength * 2
        )
        let caller = make_Caller(gateway: gateway, clock: clock).0
        let callerID = gateway.id(of: caller.name)
        let sonar23 = make_Sonar(name: "Sonar23", gateway: gateway, clock: clock, caller: callerID, echoPin: .pin2Control, triggerPin: .pin3Control, echoPinValue: .pin2Status).0
        let sonar45 = make_Sonar(name: "Sonar45", gateway: gateway, clock: clock, caller: callerID, echoPin: .pin4Control, triggerPin: .pin5Control, echoPinValue: .pin4Status).0
        let sonar67 = make_Sonar(name: "Sonar67", gateway: gateway, clock: clock, caller: callerID, echoPin: .pin6Control, triggerPin: .pin7Control, echoPinValue: .pin6Status).0
        let callerTimeslot = Timeslot(
            fsms: [caller.name],
            callChain: CallChain(root: caller.name, calls: []),
            externalDependencies: [],
            startingTime: 0,
            duration: timeslotLength,
            cyclesExecuted: 0
        )
        let sonar23Timeslot = Timeslot(
            fsms: [sonar23.name],
            callChain: CallChain(root: sonar23.name, calls: []),
            externalDependencies: [],
            startingTime: timeslotLength,
            duration: timeslotLength,
            cyclesExecuted: 0
        )
        let sonar45Timeslot = Timeslot(
            fsms: [sonar45.name],
            callChain: CallChain(root: sonar45.name, calls: []),
            externalDependencies: [],
            startingTime: timeslotLength,
            duration: timeslotLength,
            cyclesExecuted: 0
        )
        let sonar67Timeslot = Timeslot(
            fsms: [sonar67.name],
            callChain: CallChain(root: sonar67.name, calls: []),
            externalDependencies: [],
            startingTime: timeslotLength,
            duration: timeslotLength,
            cyclesExecuted: 0
        )
        let threads = [
            IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: 0,
                            step: .takeSnapshotAndStartTimeslot(timeslot: callerTimeslot)
                        ),
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .executeAndSaveSnapshot(timeslot: callerTimeslot)
                        ),
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .startDelegates(fsms: [sonar23Timeslot, sonar45Timeslot, sonar67Timeslot])
                        ),
                        VerificationMap.Step(
                            time: timeslotLength * 2,
                            step: .endDelegates(fsms: [sonar23Timeslot, sonar45Timeslot, sonar67Timeslot])
                        )
                    ],
                    delegates: [sonar23.name, sonar45.name, sonar67.name]
                ),
                pool: FSMPool(fsms: [caller, sonar23, sonar45, sonar67], parameterisedFSMs: [sonar23.name, sonar45.name, sonar67.name])
            )
        ]
        let parameterisedThreads = [
            sonar23.name: IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .takeSnapshotAndStartTimeslot(timeslot: sonar23Timeslot)
                        ),
                        VerificationMap.Step(
                            time: timeslotLength * 2,
                            step: .executeAndSaveSnapshot(timeslot: sonar23Timeslot)
                        )
                    ],
                    delegates: []
                ),
                pool: FSMPool(fsms: [sonar23], parameterisedFSMs: [])
            ),
            sonar45.name: IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .takeSnapshotAndStartTimeslot(timeslot: sonar45Timeslot)
                        ),
                        VerificationMap.Step(
                            time: timeslotLength * 2,
                            step: .executeAndSaveSnapshot(timeslot: sonar45Timeslot)
                        )
                    ],
                    delegates: []
                ),
                pool: FSMPool(fsms: [sonar45], parameterisedFSMs: [])
            ),
            sonar67.name: IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .takeSnapshotAndStartTimeslot(timeslot: sonar67Timeslot)
                        ),
                        VerificationMap.Step(
                            time: timeslotLength * 2,
                            step: .executeAndSaveSnapshot(timeslot: sonar67Timeslot)
                        )
                    ],
                    delegates: []
                ),
                pool: FSMPool(fsms: [sonar67], parameterisedFSMs: [])
            )
        ]
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                parameterisedThreads: parameterisedThreads,
                cycleLength: timeslotLength * 2
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

}
