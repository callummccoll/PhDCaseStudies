
import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SharedVariables

final class LightFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = MicrowaveState
    typealias Ringlet = MicrowaveRinglet

    var validVars: [String: [Any]] {
        [
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
            "status": [],
            "light": [],
            "onState": [],
            "$__lazy_storage_$_currentState": [],
            "$__lazy_storage_$_initialState": [],
            "$__lazy_storage_$_onState": []
        ]
    }

    var description: String {
        "\(KripkeStatePropertyList(self))"
    }

    var computedVars: [String: Any] {
        return [
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var status: InMemoryVariable<MicrowaveStatus>

    var light: InMemoryVariable<Bool>

    var sensors: [AnySnapshotController] = []

    var actuators: [AnySnapshotController] = []

    var externalVariables: [AnySnapshotController] {
        get {
            [AnySnapshotController(status), AnySnapshotController(light)]
        } set {
            if let val = newValue.first(where: { $0.name == status.name })?.val {
                status.val = val as! MicrowaveStatus
            }
            if let val = newValue.first(where: { $0.name == light.name })?.val {
                light.val = val as! Bool
            }
        }
    }

    var name: String

    lazy var initialState: MicrowaveState = {
        CallbackMicrowaveState(
            "Off",
            transitions: [Transition(onState) { [self] _ in status.val.doorOpen || status.val.timeLeft }],
            snapshotSensors: [status.name, light.name],
            snapshotActuators: [status.name, light.name],
            onEntry: { [self] in light.val = false }
        )
    }()

    lazy var onState: MicrowaveState = {
        CallbackMicrowaveState(
            "On",
            snapshotSensors: [status.name, light.name],
            snapshotActuators: [status.name, light.name],
            onEntry: { [self] in light.val = true }
        )
    }()

    lazy var currentState: MicrowaveState = { initialState }()

    var previousState: MicrowaveState = EmptyMicrowaveState("previous")

    var suspendedState: MicrowaveState? = nil

    var suspendState: MicrowaveState = EmptyMicrowaveState("suspend")

    var exitState: MicrowaveState = EmptyMicrowaveState("exit", snapshotSensors: [])

    var submachines: [LightFiniteStateMachine] = []

    var initialPreviousState: MicrowaveState = EmptyMicrowaveState("previous")

    var ringlet = MicrowaveRinglet(previousState: EmptyMicrowaveState("previous"))

    func clone() -> LightFiniteStateMachine {
        let fsm = LightFiniteStateMachine(name: name, status: status, light: light)
        fsm.name = name
        if currentState.name == initialState.name {
            fsm.currentState = fsm.initialState
        } else if currentState.name == onState.name {
            fsm.currentState = fsm.onState
        }
        if previousState.name == initialState.name {
            fsm.previousState = fsm.initialState
        } else if previousState.name == onState.name {
            fsm.previousState = fsm.onState
        }
        fsm.status = status.clone()
        fsm.light = light.clone()
        fsm.ringlet = ringlet.clone()
        if fsm.ringlet.previousState.name == initialState.name {
            fsm.ringlet.previousState = fsm.initialState
        } else if fsm.ringlet.previousState.name == onState.name {
            fsm.ringlet.previousState = fsm.onState
        }
        return fsm
    }

    init(name: String, status: InMemoryVariable<MicrowaveStatus>, light: InMemoryVariable<Bool>) {
        self.name = name
        self.status = status
        self.light = light
        self.onState.addTransition(MicrowaveTransition(UnownedTransition(initialState) { [self] _ in !self.status.val.doorOpen && !self.status.val.timeLeft }))
    }

}
