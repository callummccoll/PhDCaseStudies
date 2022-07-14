/*
 * InitialOneMinuteMicrowaveTests.swift
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
import SwiftfsmWBWrappers

@testable import InitialOneMinuteMicrowave
@testable import Verification

class InitialOneMinuteMicrowaveTests: XCTestCase {

    public final class InMemoryStore: MutableKripkeStructure {

        public let identifier: String

        private var latestId: Int64 = 0

        private var ids: [KripkeStatePropertyList: Int64] = [:]

        private var jobs: Set<KripkeStatePropertyList> = []

        var allStates: [Int64: (KripkeStatePropertyList, Bool, Set<KripkeEdge>)] = [:]

        public var acceptingStates: AnySequence<KripkeState> {
            DispatchQueue.global(qos: .userInteractive).sync {
                AnySequence(states.filter { $0.edges.isEmpty })
            }
        }

        public var initialStates: AnySequence<KripkeState> {
            DispatchQueue.global(qos: .userInteractive).sync {
                AnySequence(states.filter { $0.isInitial })
            }
        }

        public var states: AnySequence<KripkeState> {
            DispatchQueue.global(qos: .userInteractive).sync {
                AnySequence(allStates.keys.map {
                    try! self.state(for: $0)
                })
            }
        }

        init(identifier: String) {
            self.identifier = identifier
        }

        init(identifier: String, states: Set<KripkeState>) throws {
            self.identifier = identifier
            for state in states {
                let (id, _) = try self.add(state.properties, isInitial: state.isInitial)
                for edge in state.edges {
                    try self.add(edge: edge, to: id)
                }
            }
        }

        public func add(_ propertyList: KripkeStatePropertyList, isInitial: Bool) throws -> (Int64, Bool) {
            try DispatchQueue.global(qos: .userInteractive).sync {
                let id = try id(for: propertyList)
                let inCycle = nil != allStates[id]
                if !inCycle {
                    allStates[id] = (propertyList, isInitial, [])
                }
                return (id, inCycle)
            }
        }

        public func add(edge: KripkeEdge, to id: Int64) throws {
            _ = DispatchQueue.global(qos: .userInteractive).sync {
                allStates[id]?.2.insert(edge)
            }
        }

        public func markAsInitial(id: Int64) throws {
            DispatchQueue.global(qos: .userInteractive).sync {
                self.allStates[id]?.1 = true
            }
        }

        public func exists(_ propertyList: KripkeStatePropertyList) throws -> Bool {
            DispatchQueue.global(qos: .userInteractive).sync {
                return nil != ids[propertyList]
            }
        }

        public func data(for propertyList: KripkeStatePropertyList) throws -> (Int64, KripkeState) {
            let id = try id(for: propertyList)
            return try (id, state(for: id))
        }

        public func id(for propertyList: KripkeStatePropertyList) throws -> Int64 {
            DispatchQueue.global(qos: .userInteractive).sync {
                if let id = ids[propertyList] {
                    return id
                }
                let id = latestId
                latestId += 1
                ids[propertyList] = id
                return id
            }
        }

        public func state(for id: Int64) throws -> KripkeState {
            DispatchQueue.global(qos: .userInteractive).sync {
                guard let (plist, isInitial, edges) = allStates[id] else {
                    fatalError("State does not exist")
                }
                let state = KripkeState(isInitial: isInitial, properties: plist)
                for edge in edges {
                    state.addEdge(edge)
                }
                return state
            }
        }


    }

    final class TestableViewFactory: KripkeStructureViewFactory {

        private let make: (String) -> TestableView

        private(set) var createdViews: [TestableView] = []

        var lastView: TestableView! {
            createdViews.last!
        }

        init(make: @escaping (String) -> TestableView) {
            self.make = make
        }

        func make(identifier: String) -> TestableView {
            let view = self.make(identifier)
            createdViews.append(view)
            return view
        }

        func outputViews(name: String) {
            let filemanager = FileManager.default
            let currentDirectory = URL(fileURLWithPath: filemanager.currentDirectoryPath, isDirectory: true)
            let buildDirectory = currentDirectory.appendingPathComponent("kripke_structures", isDirectory: true)
            let testDirectory = buildDirectory.appendingPathComponent(name, isDirectory: true)
            defer {
                filemanager.changeCurrentDirectoryPath(currentDirectory.path)
            }
            _ = try? filemanager.removeItem(atPath: testDirectory.path)
            guard
                let _ = try? filemanager.createDirectory(at: testDirectory, withIntermediateDirectories: true),
                true == filemanager.changeCurrentDirectoryPath(testDirectory.path)
            else {
                fatalError("Unable to create views directory")
            }
            for view in createdViews {
                let outputView = GraphVizKripkeStructureView(filename: view.identifier + ".gv")
                let nusmvView = NuSMVKripkeStructureView(identifier: view.identifier)
                try! outputView.generate(store: view.store, usingClocks: true)
                try! nusmvView.generate(store: view.store, usingClocks: true)
            }
        }

    }

    final class TestableView: KripkeStructureView {

        typealias State = KripkeState

        let identifier: String

        let expectedIdentifier: String

        var expected: Set<KripkeState>

        private(set) var store: KripkeStructure! = nil

        private(set) var result: Set<KripkeState>

        init(identifier: String, expectedIdentifier: String, expected: Set<KripkeState>) {
            self.identifier = identifier
            self.expectedIdentifier = expectedIdentifier
            self.expected = expected
            self.result = Set<KripkeState>(minimumCapacity: expected.count)
        }

        func generate(store: KripkeStructure, usingClocks: Bool) throws {
            self.store = store
            self.result = try Set(store.states)
        }

        @discardableResult
        func check(readableName: String) -> Bool {
            XCTAssertEqual(result, expected)
            if expected != result {
                explain(name: readableName + "_")
            }
            XCTAssertEqual(identifier, expectedIdentifier)
            return identifier == expectedIdentifier && result == expected
        }

        func explain(name: String = "") {
            guard expected != result else {
                return
            }
            let missingElements = expected.subtracting(result)
            print("missing results: \(missingElements)")
            let extraneousElements = result.subtracting(expected)
            print("extraneous results: \(extraneousElements)")
            let expectedView = GraphVizKripkeStructureView(filename: "\(name)expected.gv")
            let resultView = GraphVizKripkeStructureView(filename: "\(name)result.gv")
            let expectedStore = try! InMemoryStore(identifier: expectedIdentifier, states: expected)
            try! expectedView.generate(store: expectedStore, usingClocks: true)
            try! resultView.generate(store: store, usingClocks: true)
            print("Writing expected to: \(FileManager.default.currentDirectoryPath)/\(name)expected.gv")
            print("Writing result to: \(FileManager.default.currentDirectoryPath)/\(name)result.gv")
        }

    }

    var readableName: String {
        self.name.dropFirst(2).dropLast().components(separatedBy: .whitespacesAndNewlines).joined(separator: "_")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_canGenerateSeparateMicrowaveMachines() async {
        let gateway = StackGateway()
        let gap: UInt = 10
        let timeslotLength: UInt = 30
        let clock = FSMClock(
            ringletLengths: ["Timer": 30, "Alarm": 30, "Cooking": 30, "Light": 30],
            scheduleLength: gap * 4 + timeslotLength * 4
        )
        let timer = AnyControllableFiniteStateMachine(TimerFiniteStateMachine(name: "Timer", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), clock: clock))
        let alarm = AnyControllableFiniteStateMachine(AlarmFiniteStateMachine(name: "Alarm", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), sound: WhiteboardVariable(msgType: kwb_sound_v), clock: clock))
        let cooking = AnyControllableFiniteStateMachine(CookingFiniteStateMachine(name: "Cooking", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), motor: WhiteboardVariable(msgType: kwb_motor_v)))
        let light = AnyControllableFiniteStateMachine(LightFiniteStateMachine(name: "Light", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), light: WhiteboardVariable(msgType: kwb_light_v)))
        let machines: [FSMType] = [.controllableFSM(timer), .controllableFSM(alarm), .controllableFSM(cooking), .controllableFSM(light)]
        let threads: [IsolatedThread] = machines.enumerated().map { (index: Int, machine: FSMType) in
            IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: UInt(index) * 10 + UInt(index) * timeslotLength,
                            step: .takeSnapshotAndStartTimeslot(
                                timeslot: Timeslot(
                                    fsms: [machine.name],
                                    callChain: CallChain(root: machine.name, calls: []),
                                    externalDependencies: [],
                                    startingTime: UInt(index) * gap + UInt(index) * timeslotLength,
                                    duration: timeslotLength,
                                    cyclesExecuted: 0
                                )
                            )
                        ),
                        VerificationMap.Step(
                            time: UInt(index) * 10 + UInt(index) * timeslotLength + timeslotLength,
                            step: .executeAndSaveSnapshot(
                                timeslot: Timeslot(
                                    fsms: [machine.name],
                                    callChain: CallChain(root: machine.name, calls: []),
                                    externalDependencies: [],
                                    startingTime: UInt(index) * gap + UInt(index) * timeslotLength,
                                    duration: timeslotLength,
                                    cyclesExecuted: 0
                                )
                            )
                        )
                    ],
                    delegates: []
                ),
                pool: FSMPool(fsms: [machine], parameterisedFSMs: [])
            )
        }
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                parameterisedThreads: [:],
                cycleLength: UInt(machines.count) * timeslotLength + UInt(machines.count) * gap
            )
        )
        let viewFactory = TestableViewFactory { name in
            guard nil != machines.first(where: { $0.name == name}) else {
                XCTFail("Unexepected view name: \(name)")
                return TestableView(identifier: name, expectedIdentifier: "", expected: [])
            }
            return TestableView(identifier: name, expectedIdentifier: name, expected: [])
        }
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        do {
            try await verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
                try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        let counts = viewFactory.createdViews.map(\.result.count)
        print(counts)
        for (index, view) in viewFactory.createdViews.enumerated() {
            guard let machine = machines.first(where: { view.identifier.hasPrefix($0.name) }) else {
                fatalError("Unable to fetch corresponding machine from view \(view.identifier)")
            }
            let outputView = GraphVizKripkeStructureView(filename: "\(machine.name).gv")
            let nusmvView = NuSMVKripkeStructureView(identifier: "\(machine.name)")
            try! outputView.generate(store: view.store, usingClocks: true)
            try! nusmvView.generate(store: view.store, usingClocks: true)
        }
    }

    func test_canGenerateCombinedMicrowaveMachines() async {
        let gateway = StackGateway()
        let gap: UInt = 10
        let timeslotLength: UInt = 30
        let clock = FSMClock(
            ringletLengths: ["Timer": 30, "Alarm": 30, "Cooking": 30, "Light": 30],
            scheduleLength: gap * 4 + timeslotLength * 4
        )
        let timer = AnyControllableFiniteStateMachine(TimerFiniteStateMachine(name: "Timer", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), clock: clock))
        let alarm = AnyControllableFiniteStateMachine(AlarmFiniteStateMachine(name: "Alarm", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), sound: WhiteboardVariable(msgType: kwb_sound_v), clock: clock))
        let cooking = AnyControllableFiniteStateMachine(CookingFiniteStateMachine(name: "Cooking", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), motor: WhiteboardVariable(msgType: kwb_motor_v)))
        let light = AnyControllableFiniteStateMachine(LightFiniteStateMachine(name: "Light", status: WhiteboardVariable(msgType: kwb_MicrowaveStatus_v), light: WhiteboardVariable(msgType: kwb_light_v)))
        let machines: [FSMType] = [.controllableFSM(timer), .controllableFSM(alarm), .controllableFSM(cooking), .controllableFSM(light)]
        let steps: [VerificationMap.Step] = machines.enumerated().flatMap { (index: Int, machine: FSMType) -> [VerificationMap.Step] in
            [
                VerificationMap.Step(
                    time: gap * UInt(index) + timeslotLength * UInt(index),
                    step: .takeSnapshotAndStartTimeslot(
                        timeslot: Timeslot(
                            fsms: [machine.name],
                            callChain: CallChain(root: machine.name, calls: []),
                            externalDependencies: [],
                            startingTime: gap * UInt(index) + timeslotLength * UInt(index),
                            duration: timeslotLength,
                            cyclesExecuted: 0
                        )
                    )
                ),
                VerificationMap.Step(
                    time: gap * UInt(index) + timeslotLength * UInt(index) + timeslotLength,
                    step: .executeAndSaveSnapshot(
                        timeslot: Timeslot(
                            fsms: [machine.name],
                            callChain: CallChain(root: machine.name, calls: []),
                            externalDependencies: [],
                            startingTime: gap * UInt(index) + timeslotLength * UInt(index),
                            duration: timeslotLength,
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
                pool: FSMPool(fsms: machines, parameterisedFSMs: [])
            )
        ]
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                parameterisedThreads: [:],
                cycleLength: UInt(machines.count) * timeslotLength + UInt(machines.count) * gap
            )
        )
        let viewFactory = GraphVizKripkeStructureViewFactory()
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        do {
            try await verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
                try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
