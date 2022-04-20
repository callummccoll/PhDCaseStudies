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

@testable import Sonar
@testable import Verification

class SonarTests: XCTestCase {
    
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
        
    }
    
    final class TestableView: KripkeStructureView {
        
        typealias State = KripkeState
        
        let identifier: String
        
        let expectedIdentifier: String
        
        var expected: Set<KripkeState>
        
        private(set) var commits: [KripkeState] = []
        
        private(set) var result: Set<KripkeState>
        
        private(set) var finishCalled: Bool = false
        
        init(identifier: String, expectedIdentifier: String, expected: Set<KripkeState>) {
            self.identifier = identifier
            self.expectedIdentifier = expectedIdentifier
            self.expected = expected
            self.result = Set<KripkeState>(minimumCapacity: expected.count)
        }
        
        func commit(state: KripkeState) {
            commits.append(state)
            result.insert(state)
        }

        func finish() {
            finishCalled = true
        }

        func reset(usingClocks: Bool) {
            commits.removeAll(keepingCapacity: true)
            result.removeAll(keepingCapacity: true)
            finishCalled = false
        }
        
        @discardableResult
        func check(readableName: String) -> Bool {
            XCTAssertEqual(result, expected)
            if expected != result {
                explain(name: readableName + "_")
            }
            XCTAssertEqual(identifier, expectedIdentifier)
            XCTAssertEqual(commits.count, result.count) // Make sure all states are only ever committed once.
            XCTAssertTrue(finishCalled)
            return identifier == expectedIdentifier && result == expected && finishCalled
        }
        
        func explain(name: String = "") {
            guard expected != result else {
                return
            }
            let missingElements = expected.subtracting(result)
            print("missing results: \(missingElements)")
            let extraneousElements = result.subtracting(expected)
            print("extraneous results: \(extraneousElements)")
            let expectedView = GraphVizKripkeStructureView<KripkeState>(filename: "\(name)expected.gv")
            expectedView.reset(usingClocks: true)
            let resultView = GraphVizKripkeStructureView<KripkeState>(filename: "\(name)result.gv")
            resultView.reset(usingClocks: true)
            for state in expected.sorted(by: { $0.properties.description < $1.properties.description }) {
                expectedView.commit(state: state)
            }
            for state in result.sorted(by: { $0.properties.description < $1.properties.description }) {
                resultView.commit(state: state)
            }
            expectedView.finish()
            resultView.finish()
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
    
    func test_canGenerateParallelSonarMachines() {
        let wbVars = [
            ("Sonar23", kwb_Arduino2Pin_v, kwb_Arduino3Pin_v, kwb_Arduino2PinValue_v),
            ("Sonar45", kwb_Arduino4Pin_v, kwb_Arduino5Pin_v, kwb_Arduino4PinValue_v),
            ("Sonar67", kwb_Arduino6Pin_v, kwb_Arduino7Pin_v, kwb_Arduino6PinValue_v)
        ]
        let gateway = StackGateway()
        let timeslotLength: UInt = 244
        let clock = FSMClock(
            ringletLengths: Dictionary(uniqueKeysWithValues: wbVars.map { ($0.0, timeslotLength) }),
            scheduleLength: timeslotLength
        )
        let machines: [FSMType] = wbVars.map {
            let caller = gateway.id(of: $0)
            return make_Sonar(
                name: $0,
                gateway: gateway,
                clock: clock,
                caller: caller,
                echoPin: $1,
                triggerPin: $2,
                echoPinValue: $3
            ).0
        }
        let threads = wbVars.enumerated().map { (index, data) in
            IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: 0,
                            step: .takeSnapshotAndStartTimeslot(
                                timeslot: Timeslot(
                                    fsms: [data.0],
                                    callChain: CallChain(root: data.0, calls: []),
                                    startingTime: 0,
                                    duration: timeslotLength,
                                    cyclesExecuted: 0
                                )
                            )
                        ),
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .executeAndSaveSnapshot(
                                timeslot: Timeslot(
                                    fsms: [data.0],
                                    callChain: CallChain(root: data.0, calls: []),
                                    startingTime: 0,
                                    duration: timeslotLength,
                                    cyclesExecuted: 0
                                )
                            )
                        )
                    ],
                    stepLookup: []
                ),
                pool: FSMPool(fsms: [machines[index]])
            )
        }
       let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                cycleLength: timeslotLength
            )
        )
        let viewFactory = TestableViewFactory { name in
            guard nil != wbVars.first(where: { $0.0 ==  name}) else {
                XCTFail("Unexepected view name: \(name)")
                return TestableView(identifier: name, expectedIdentifier: "", expected: [])
            }
            return TestableView(identifier: name, expectedIdentifier: name, expected: [])
        }
        verifier.verify(gateway: gateway, timer: clock, viewFactory: viewFactory, cycleDetector: HashTableCycleDetector())
        let counts = viewFactory.createdViews.map(\.commits.count)
        print(counts)
        for (index, view) in viewFactory.createdViews.enumerated() {
            let outputView = GraphVizKripkeStructureView<KripkeState>(filename: "\(wbVars[index].0).gv")
            let nusmvView = NuSMVKripkeStructureView<KripkeState>(identifier: "\(wbVars[index].0)")
            outputView.reset(usingClocks: true)
            nusmvView.reset(usingClocks: true)
            for state in view.result.sorted(by: { $0.properties.description < $1.properties.description }) {
                outputView.commit(state: state)
                nusmvView.commit(state: state)
            }
            outputView.finish()
            nusmvView.finish()
        }
    }
    
    func test_canGenerateSonarMachines() {
        let wbVars = [
            ("Sonar23", kwb_Arduino2Pin_v, kwb_Arduino3Pin_v, kwb_Arduino2PinValue_v),
            ("Sonar45", kwb_Arduino4Pin_v, kwb_Arduino5Pin_v, kwb_Arduino4PinValue_v),
            ("Sonar67", kwb_Arduino6Pin_v, kwb_Arduino7Pin_v, kwb_Arduino6PinValue_v)
        ]
        let gateway = StackGateway()
        let timeslotLength: UInt = 244
        let clock = FSMClock(
            ringletLengths: Dictionary(uniqueKeysWithValues: wbVars.map { ($0.0, timeslotLength) }),
            scheduleLength: UInt(wbVars.count) * timeslotLength
        )
        let machines: [FSMType] = wbVars.map {
            let caller = gateway.id(of: $0)
            return make_Sonar(
                name: $0,
                gateway: gateway,
                clock: clock,
                caller: caller,
                echoPin: $1,
                triggerPin: $2,
                echoPinValue: $3
            ).0
        }
        let threads = wbVars.enumerated().map { (index, data) in
            IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: 0,
                            step: .takeSnapshotAndStartTimeslot(
                                timeslot: Timeslot(
                                    fsms: [data.0],
                                    callChain: CallChain(root: data.0, calls: []),
                                    startingTime: UInt(index) * timeslotLength,
                                    duration: timeslotLength,
                                    cyclesExecuted: 0
                                )
                            )
                        ),
                        VerificationMap.Step(
                            time: timeslotLength,
                            step: .executeAndSaveSnapshot(
                                timeslot: Timeslot(
                                    fsms: [data.0],
                                    callChain: CallChain(root: data.0, calls: []),
                                    startingTime: UInt(index) * timeslotLength,
                                    duration: timeslotLength,
                                    cyclesExecuted: 0
                                )
                            )
                        )
                    ],
                    stepLookup: []
                ),
                pool: FSMPool(fsms: [machines[index]])
            )
        }
       let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                cycleLength: UInt(wbVars.count) * timeslotLength
            )
        )
        let viewFactory = TestableViewFactory { name in
            guard nil != wbVars.first(where: { $0.0 ==  name}) else {
                XCTFail("Unexepected view name: \(name)")
                return TestableView(identifier: name, expectedIdentifier: "", expected: [])
            }
            return TestableView(identifier: name, expectedIdentifier: name, expected: [])
        }
        verifier.verify(gateway: gateway, timer: clock, viewFactory: viewFactory, cycleDetector: HashTableCycleDetector())
        let counts = viewFactory.createdViews.map(\.commits.count)
        print(counts)
        for (index, view) in viewFactory.createdViews.enumerated() {
            let outputView = GraphVizKripkeStructureView<KripkeState>(filename: "\(wbVars[index].0).gv")
            let nusmvView = NuSMVKripkeStructureView<KripkeState>(identifier: "\(wbVars[index].0)")
            outputView.reset(usingClocks: true)
            nusmvView.reset(usingClocks: true)
            for state in view.result.sorted(by: { $0.properties.description < $1.properties.description }) {
                outputView.commit(state: state)
                nusmvView.commit(state: state)
            }
            outputView.finish()
            nusmvView.finish()
        }
    }
    
    func test_canGenerateCombinedSonarMachines() {
        let wbVars = [
            ("Sonar23", kwb_Arduino2Pin_v, kwb_Arduino3Pin_v, kwb_Arduino2PinValue_v),
            ("Sonar45", kwb_Arduino4Pin_v, kwb_Arduino5Pin_v, kwb_Arduino4PinValue_v),
            ("Sonar67", kwb_Arduino6Pin_v, kwb_Arduino7Pin_v, kwb_Arduino6PinValue_v)
        ]
        let gateway = StackGateway()
        let timeslotLength: UInt = 244
        let clock = FSMClock(
            ringletLengths: Dictionary(uniqueKeysWithValues: wbVars.map { ($0.0, timeslotLength) }),
            scheduleLength: UInt(wbVars.count) * timeslotLength
        )
        let machines: [FSMType] = wbVars.map {
            let caller = gateway.id(of: $0)
            return make_Sonar(
                name: $0,
                gateway: gateway,
                clock: clock,
                caller: caller,
                echoPin: $1,
                triggerPin: $2,
                echoPinValue: $3
            ).0
        }
        let pool = FSMPool(fsms: machines)
        let steps = wbVars.enumerated().flatMap { (index, data) in
            [
                VerificationMap.Step(
                    time: 0,
                    step: .takeSnapshotAndStartTimeslot(
                        timeslot: Timeslot(
                            fsms: [data.0],
                            callChain: CallChain(root: data.0, calls: []),
                            startingTime: UInt(index) * timeslotLength,
                            duration: timeslotLength,
                            cyclesExecuted: 0
                        )
                    )
                ),
                VerificationMap.Step(
                    time: timeslotLength,
                    step: .executeAndSaveSnapshot(
                        timeslot: Timeslot(
                            fsms: [data.0],
                            callChain: CallChain(root: data.0, calls: []),
                            startingTime: UInt(index) * timeslotLength,
                            duration: timeslotLength,
                            cyclesExecuted: 0
                        )
                    )
                )
            ]
        }
        let threads = [
            IsolatedThread(map: VerificationMap(steps: steps, stepLookup: []), pool: pool)
        ]
        let verifier = ScheduleVerifier(
            isolatedThreads: ScheduleIsolator(
                threads: threads,
                cycleLength: UInt(wbVars.count) * timeslotLength
            )
        )
        let viewFactory = TestableViewFactory { name in
            guard nil != wbVars.first(where: { $0.0 == name}) else {
                XCTFail("Unexepected view name: \(name)")
                return TestableView(identifier: name, expectedIdentifier: "", expected: [])
            }
            return TestableView(identifier: name, expectedIdentifier: name, expected: [])
        }
        verifier.verify(gateway: gateway, timer: clock, viewFactory: viewFactory, cycleDetector: HashTableCycleDetector())
        let counts = viewFactory.createdViews.map(\.commits.count)
        print(counts)
        for (index, view) in viewFactory.createdViews.enumerated() {
            let outputView = GraphVizKripkeStructureView<KripkeState>(filename: "\(wbVars[index].0).gv")
            let nusmvView = NuSMVKripkeStructureView<KripkeState>(identifier: "\(wbVars[index].0)")
            outputView.reset(usingClocks: true)
            nusmvView.reset(usingClocks: true)
            for state in view.result.sorted(by: { $0.properties.description < $1.properties.description }) {
                outputView.commit(state: state)
                nusmvView.commit(state: state)
            }
            outputView.finish()
            nusmvView.finish()
        }
    }

}
