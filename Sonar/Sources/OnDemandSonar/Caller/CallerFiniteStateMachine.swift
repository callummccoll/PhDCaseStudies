import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SharedVariables

final class CallerFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = CallerState
    typealias Ringlet = CallerRinglet

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
            "name": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "buttonPushed": [],
            "doorOpen": [],
            "timeLeft": [],
            "sound": [],
            "onState": [],
            "$__lazy_storage_$_currentState": [],
            "$__lazy_storage_$_initialState": [],
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

    var clock: Timer

    var sensors: [AnySnapshotController] = []

    var actuators: [AnySnapshotController] = []

    var externalVariables: [AnySnapshotController] = []

    /**
     * All FSM variables used by the machine.
     */
    public let fsmVars: SimpleVariablesContainer<CallerVars>

    var name: String

    var initialState: CallerState

    lazy var currentState: CallerState = { initialState }()

    var previousState: CallerState = EmptyCallerState("previous")

    var suspendedState: CallerState? = nil

    var suspendState: CallerState = EmptyCallerState("suspend")

    var exitState: CallerState = EmptyCallerState("exit")

    var submachines: [CallerFiniteStateMachine] = []

    var initialPreviousState: CallerState = EmptyCallerState("previous")

    var ringlet = CallerRinglet()

    private func update<T>(keyPath: WritableKeyPath<T, CallerState>, target: inout T) {
        let name = target[keyPath: keyPath].name
        switch name {
        case initialState.name:
            target[keyPath: keyPath] = initialState
        case initialPreviousState.name:
            target[keyPath: keyPath] = initialPreviousState
        case exitState.name:
            target[keyPath: keyPath] = exitState
        default:
            fatalError("This should never happen.")
        }
    }

    func clone() -> CallerFiniteStateMachine {
        var fsm = CallerFiniteStateMachine(name: name, clock: clock, fsmVars: fsmVars.vars.clone(), initialState: initialState.clone() as! CallerState_Initial)
        fsm.name = name
        fsm.initialState.Me = fsm
        fsm.ringlet = ringlet.clone()
        fsm.currentState = currentState
        fsm.previousState = previousState
        fsm.ringlet.previousState = ringlet.previousState
        fsm.update(keyPath: \.currentState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm.ringlet)
        return fsm
    }

    init(name: String, clock: Timer, fsmVars: CallerVars, initialState: CallerState_Initial) {
        self.name = name
        self.clock = clock
        self.fsmVars = SimpleVariablesContainer(vars: fsmVars)
        self.initialState = initialState
        self.initialState.addTransition(CallerStateTransition(Transition<CallerState_Initial, CallerState>(exitState) { state in
            state.promise23.hasFinished && state.promise45.hasFinished && state.promise67.hasFinished
        }))
    }

}
