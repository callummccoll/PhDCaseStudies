import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SharedVariables

final class BoundedWaitFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = BoundedWaitState
    typealias Ringlet = BoundedWaitRinglet

    var validVars: [String: [Any]] {
        [
            "clock": [],
            "currentState": [],
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
            "buttonPushed": [],
            "doorOpen": [],
            "transition": [],
            "sound": [],
            "onState": [],
            "$__lazy_storage_$_currentState": [],
            "$__lazy_storage_$_initialState": [],
            "$__lazy_storage_$_armedState": [],
            "$__lazy_storage_$_onState": []
        ]
    }

    var description: String {
        "\(KripkeStatePropertyList(self))"
    }

    var computedVars: [String: Any] {
        return [
            "sensors": Dictionary(uniqueKeysWithValues: sensors.map { ($0.name, $0.val) }),
            "actuators": Dictionary(uniqueKeysWithValues: actuators.map { ($0.name, $0.val) }),
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var transition: InMemoryVariable<Bool>

    var clock: Timer

    var sensors: [AnySnapshotController] {
        get {
            [AnySnapshotController(transition)]
        } set {
            if let val = newValue.first(where: { $0.name == transition.name })?.val {
                transition.val = val as! Bool
            }
        }
    }

    var actuators: [AnySnapshotController] = []

    var externalVariables: [AnySnapshotController] = []

    var name: String

    lazy var initialState: BoundedWaitState = {
        CallbackBoundedWaitState(
            "Wait",
            transitions: [Transition(exitState) { [unowned self] _ in self.clock.after(2) || self.transition.val }],
            snapshotSensors: [transition.name],
            snapshotActuators: []
        )
    }()

    lazy var currentState: BoundedWaitState = { initialState }()

    var previousState: BoundedWaitState = EmptyBoundedWaitState("previous")

    var suspendedState: BoundedWaitState? = nil

    var suspendState: BoundedWaitState = EmptyBoundedWaitState("suspend")

    var exitState: BoundedWaitState = EmptyBoundedWaitState("Exit", snapshotSensors: [])

    var submachines: [BoundedWaitFiniteStateMachine] = []

    var initialPreviousState: BoundedWaitState = EmptyBoundedWaitState("previous")

    var ringlet = BoundedWaitRinglet(previousState: EmptyBoundedWaitState("previous"))

    private func update<T>(keyPath: WritableKeyPath<T, BoundedWaitState>, target: inout T) {
        switch target[keyPath: keyPath].name {
        case initialState.name:
            target[keyPath: keyPath] = initialState
        case exitState.name:
            target[keyPath: keyPath] = exitState
        case initialPreviousState.name:
            target[keyPath: keyPath] = initialPreviousState
        default:
            fatalError("This should never happen.")
        }
    }

    func clone() -> BoundedWaitFiniteStateMachine {
        var fsm = BoundedWaitFiniteStateMachine(name: name, transition: transition.clone(), clock: clock)
        fsm.name = name
        fsm.ringlet = ringlet.clone()
        fsm.currentState = currentState
        fsm.previousState = previousState
        fsm.ringlet.previousState = ringlet.previousState
        fsm.update(keyPath: \.currentState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm.ringlet)
        return fsm
    }

    init(name: String, transition: InMemoryVariable<Bool>, clock: Timer) {
        self.name = name
        self.transition = transition
        self.clock = clock
    }

}
