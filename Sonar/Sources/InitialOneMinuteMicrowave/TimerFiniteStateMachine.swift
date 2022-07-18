import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SharedVariables

final class TimerFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = MicrowaveState
    typealias Ringlet = MicrowaveRinglet

    var validVars: [String: [Any]] {
        [
            "clock": [],
            "currentState": [],
            "currentTime": [],
            "exitState": [],
            "externalVariables": [],
            "sensors": [],
            "actuators": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "fsmVars": [],
            "initialPreviousState": [],
            "initialState": [],
            "name": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "status": [],
            "addState": [],
            "decrementState": [],
            "$__lazy_storage_$_currentState": [],
            "$__lazy_storage_$_initialState": [],
            "$__lazy_storage_$_addState": [],
            "$__lazy_storage_$_decrementState": []
        ]
    }

    var description: String {
        "\(KripkeStatePropertyList(self))"
    }

    var computedVars: [String: Any] {
        return [
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "fsmVars": ["currentTime": currentTime],
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var clock: Timer

    var status: InMemoryVariable<MicrowaveStatus>

    var sensors: [AnySnapshotController] = []

    var actuators: [AnySnapshotController] = []

    var externalVariables: [AnySnapshotController] {
        get {
            [AnySnapshotController(status)]
        } set {
            if let val = newValue.first(where: { $0.name == status.name })?.val {
                status.val = val as! MicrowaveStatus
            }
        }
    }

    var currentTime: UInt8 = 0

    var name: String

    lazy var initialState: MicrowaveState = {
        CallbackMicrowaveState(
            "Check",
            snapshotSensors: [status.name],
            snapshotActuators: [status.name],
            onEntry: { [unowned self] in status.val.timeLeft = 0 < currentTime}
        )
    }()

    lazy var addState: MicrowaveState = {
        CallbackMicrowaveState(
            "Add_1_Minute",
            snapshotSensors: [status.name],
            snapshotActuators: [status.name],
            onEntry: { [unowned self] in currentTime += 1},
            onExit: { [unowned self] in status.val.timeLeft = true }
        )
    }()

    lazy var decrementState: MicrowaveState = {
        CallbackMicrowaveState(
            "Decrement_1_Minute",
            snapshotSensors: [status.name],
            snapshotActuators: [status.name],
            onEntry: { [unowned self] in currentTime -= 1 }
        )
    }()

    lazy var currentState: MicrowaveState = { initialState }()

    var previousState: MicrowaveState = EmptyMicrowaveState("previous")

    var suspendedState: MicrowaveState? = nil

    var suspendState: MicrowaveState = EmptyMicrowaveState("suspend")

    var exitState: MicrowaveState = EmptyMicrowaveState("exit", snapshotSensors: [])

    var submachines: [TimerFiniteStateMachine] = []

    var initialPreviousState: MicrowaveState = EmptyMicrowaveState("previous")

    var ringlet = MicrowaveRinglet(previousState: EmptyMicrowaveState("previous"))

    private func update<T>(keyPath: WritableKeyPath<T, MicrowaveState>, target: inout T) {
        switch target[keyPath: keyPath].name {
        case initialState.name:
            target[keyPath: keyPath] = initialState
        case addState.name:
            target[keyPath: keyPath] = addState
        case decrementState.name:
            target[keyPath: keyPath] = decrementState
        case initialPreviousState.name:
            target[keyPath: keyPath] = initialPreviousState
        default:
            fatalError("This should never happen.")
        }
    }

    func clone() -> TimerFiniteStateMachine {
        var fsm = TimerFiniteStateMachine(name: name, status: status, clock: clock)
        fsm.name = name
        fsm.status = status.clone()
        fsm.ringlet = ringlet.clone()
        fsm.currentTime = currentTime
        fsm.currentState = currentState
        fsm.previousState = previousState
        fsm.ringlet.previousState = ringlet.previousState
        fsm.update(keyPath: \.currentState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm.ringlet)
        return fsm
    }

    init(name: String, status: InMemoryVariable<MicrowaveStatus>, clock: Timer) {
        self.name = name
        self.status = status
        self.clock = clock
        initialState.addTransition(MicrowaveTransition(Transition(decrementState) { [unowned self] _ in
            self.currentTime > 0
                && !self.status.val.doorOpen
                && self.status.val.timeLeft
                && self.clock.after(60)
        }))
        initialState.addTransition(MicrowaveTransition(Transition(addState) { [unowned self] _ in
            self.status.val.buttonPushed
                && !self.status.val.doorOpen
                && self.currentTime < 15
        }))
        addState.addTransition(MicrowaveTransition(UnownedTransition(initialState) { [unowned self] _ in
            !self.status.val.buttonPushed
        }))
        decrementState.addTransition(MicrowaveTransition(UnownedTransition(initialState) { _ in true }))
    }

}
