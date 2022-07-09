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
import SwiftfsmWBWrappers

@testable import ParameterisedSonar
@testable import Verification

class ParameterisedSonarTests: XCTestCase {
    
    final class InMemoryStore: MutableKripkeStructure {

        let identifier: String

        private var latestId: Int64 = 0

        private var ids: [KripkeStatePropertyList: Int64] = [:]

        var allStates: [Int64: (KripkeStatePropertyList, Bool, Set<KripkeEdge>)] = [:]

        var acceptingStates: AnySequence<KripkeState> {
            AnySequence(states.filter { $0.edges.isEmpty })
        }

        var initialStates: AnySequence<KripkeState> {
            AnySequence(states.filter { $0.isInitial })
        }

        var states: AnySequence<KripkeState> {
            AnySequence(allStates.keys.map {
                try! self.state(for: $0)
            })
        }

        init(identifier: String, states: Set<KripkeState>) {
            self.identifier = identifier
            for state in states {
                let id = try! self.add(state.properties, isInitial: state.isInitial)
                for edge in state.edges {
                    try! self.add(edge: edge, to: id)
                }
            }
        }

        func add(_ propertyList: KripkeStatePropertyList, isInitial: Bool) throws -> Int64 {
            let id = try id(for: propertyList)
            if nil == allStates[id] {
                allStates[id] = (propertyList, isInitial, [])
            }
            return id
        }

        func add(edge: KripkeEdge, to id: Int64) throws {
            allStates[id]?.2.insert(edge)
        }

        func markAsInitial(id: Int64) throws {
            allStates[id]?.1 = true
        }

        func exists(_ propertyList: KripkeStatePropertyList) throws -> Bool {
            return nil != ids[propertyList]
        }

        func data(for propertyList: KripkeStatePropertyList) throws -> (Int64, KripkeState) {
            let id = try id(for: propertyList)
            return try (id, state(for: id))
        }

        func id(for propertyList: KripkeStatePropertyList) throws -> Int64 {
            if let id = ids[propertyList] {
                return id
            }
            let id = latestId
            latestId += 1
            ids[propertyList] = id
            return id
        }

        func state(for id: Int64) throws -> KripkeState {
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
            let expectedStore = InMemoryStore(identifier: expectedIdentifier, states: expected)
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
    
    func test_canGenerateSonarMachines() {
        let gateway = StackGateway()
        let timeslotLength: UInt = 244
        let clock = FSMClock(
            ringletLengths: [
                "Caller": timeslotLength,
                "Sonar23": timeslotLength,
                "Sonar45": timeslotLength,
                "Sonar67": timeslotLength
            ],
            scheduleLength: timeslotLength * 2
        )
        let caller = make_Caller(gateway: gateway, clock: clock).0
        let callerID = gateway.id(of: caller.name)
        let sonar23 = make_Sonar(name: "Sonar23", gateway: gateway, clock: clock, caller: callerID, echoPin: kwb_Arduino2Pin_v, triggerPin: kwb_Arduino3Pin_v, echoPinValue: kwb_Arduino2PinValue_v).0
        let sonar45 = make_Sonar(name: "Sonar45", gateway: gateway, clock: clock, caller: callerID, echoPin: kwb_Arduino4Pin_v, triggerPin: kwb_Arduino4Pin_v, echoPinValue: kwb_Arduino5PinValue_v).0
        let sonar67 = make_Sonar(name: "Sonar67", gateway: gateway, clock: clock, caller: callerID, echoPin: kwb_Arduino4Pin_v, triggerPin: kwb_Arduino6Pin_v, echoPinValue: kwb_Arduino7PinValue_v).0
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
                cycleLength: timeslotLength
            )
        )
        let viewFactory = TestableViewFactory { name in
            switch name {
            case caller.name, sonar23.name, sonar45.name, sonar67.name:
                return TestableView(identifier: name, expectedIdentifier: name, expected: [])
            default:
                XCTFail("Unexepected view name: \(name)")
                return TestableView(identifier: name, expectedIdentifier: "", expected: [])
            }
        }
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: "/tmp/swiftfsm/\(readableName)")
        do {
            try verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
                try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
        let counts = viewFactory.createdViews.map(\.result.count)
        print(counts)
        for view in viewFactory.createdViews {
            let outputView = GraphVizKripkeStructureView(filename: "\(view.identifier)_result.gv")
            let nusmvView = NuSMVKripkeStructureView(identifier: "\(view.identifier)_result")
            try! outputView.generate(store: view.store, usingClocks: true)
            try! nusmvView.generate(store: view.store, usingClocks: true)
        }
    }

}
