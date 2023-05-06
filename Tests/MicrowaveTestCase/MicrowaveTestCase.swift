import Foundation
import Gateways
import Timers
import KripkeStructure
import KripkeStructureTestCase
import KripkeStructureViews
import swiftfsm
import SharedVariables

@testable import Verification

open class MicrowaveTestCase: KripkeStructureTestCase {

    open var gap: UInt { 10 }

    open var length: UInt { 80 + 50 + 30 + 30 }

    open var cycleLength: UInt { gap * 4 + length }

    open var parallelCycleLength: UInt { 150 }

    open var clock: FSMClock!

    open var parallelClock: FSMClock!

    open override func setUpWithError() throws {
        try super.setUpWithError()
        self.clock = FSMClock(
            ringletLengths: ["Timer": 80, "Alarm": 50, "Cooking": 30, "Light": 30],
            scheduleLength: cycleLength
        )
        self.parallelClock = FSMClock(
            ringletLengths: ["Timer": 80, "Alarm": 50, "Cooking": 30, "Light": 30],
            scheduleLength: parallelCycleLength
        )
    }

    open func generate_combined(
        timer: AnyControllableFiniteStateMachine,
        alarm: AnyControllableFiniteStateMachine,
        cooking: AnyControllableFiniteStateMachine,
        light: AnyControllableFiniteStateMachine
    ) throws {
        let gateway = StackGateway()
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
        let viewFactory = AggregateKripkeStructureViewFactory(factories: [
            AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory()),
            AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory())
        ])
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: testFolder.path)
        try verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
            try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
        }
    }

    open func generate_separate(
        timer: AnyControllableFiniteStateMachine,
        alarm: AnyControllableFiniteStateMachine,
        cooking: AnyControllableFiniteStateMachine,
        light: AnyControllableFiniteStateMachine
    ) throws {
        let gateway = StackGateway()
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
        try verifier.verify(gateway: gateway, timer: clock, factory: factory).forEach {
            try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
        }
    }

    open func generate_parallel(
        timer: AnyControllableFiniteStateMachine,
        alarm: AnyControllableFiniteStateMachine,
        cooking: AnyControllableFiniteStateMachine,
        light: AnyControllableFiniteStateMachine
    ) throws {
        let gateway = StackGateway()
        let machines: [(FSMType, UInt, UInt)] = [
            (.controllableFSM(timer), 80, 10),
            (.controllableFSM(alarm), 50, 100),
            (.controllableFSM(cooking), 30, 100),
            (.controllableFSM(light), 30, 100)
        ]
        let threads: [IsolatedThread] = machines.map { (machine: (FSMType, UInt, UInt)) in
            IsolatedThread(
                map: VerificationMap(
                    steps: [
                        VerificationMap.Step(
                            time: machine.2,
                            step: .takeSnapshotAndStartTimeslot(
                                timeslot: Timeslot(
                                    fsms: [machine.0.name],
                                    callChain: CallChain(root: machine.0.name, calls: []),
                                    externalDependencies: [],
                                    startingTime: machine.2,
                                    duration: machine.1,
                                    cyclesExecuted: 0
                                )
                            )
                        ),
                        VerificationMap.Step(
                            time: machine.2 + machine.1,
                            step: .executeAndSaveSnapshot(
                                timeslot: Timeslot(
                                    fsms: [machine.0.name],
                                    callChain: CallChain(root: machine.0.name, calls: []),
                                    externalDependencies: [],
                                    startingTime: machine.2,
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
                cycleLength: parallelCycleLength
            )
        )
        let viewFactory = AggregateKripkeStructureViewFactory(factories: [
            AnyKripkeStructureViewFactory(GraphVizKripkeStructureViewFactory()),
            AnyKripkeStructureViewFactory(NuSMVKripkeStructureViewFactory())
        ])
        let factory = SQLiteKripkeStructureFactory(savingInDirectory: testFolder.path)
        try verifier.verify(gateway: gateway, timer: parallelClock, factory: factory).forEach {
            try viewFactory.make(identifier: $0.identifier).generate(store: $0, usingClocks: true)
        }
    }

}
