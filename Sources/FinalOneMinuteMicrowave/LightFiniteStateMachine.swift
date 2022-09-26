
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
            "buttonPushed": [],
            "doorOpen": [],
            "timeLeft": [],
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
            "sensors": Dictionary(uniqueKeysWithValues: sensors.map { ($0.name, $0.val) }),
            "actuators": Dictionary(uniqueKeysWithValues: actuators.map { ($0.name, $0.val) }),
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var doorOpen: InMemoryVariable<Bool>

    var timeLeft: InMemoryVariable<Bool>

    var light: InMemoryVariable<Bool>

    var sensors: [AnySnapshotController]{
        get {
            [AnySnapshotController(doorOpen), AnySnapshotController(timeLeft)]
        } set {
            if let val = newValue.first(where: { $0.name == doorOpen.name })?.val {
                doorOpen.val = val as! Bool
            }
            if let val = newValue.first(where: { $0.name == timeLeft.name })?.val {
                timeLeft.val = val as! Bool
            }
        }
    }

    var actuators: [AnySnapshotController] {
        get {
            [AnySnapshotController(light)]
        } set {
            if let val = newValue.first(where: { $0.name == light.name })?.val {
                light.val = val as! Bool
            }
        }
    }

    var externalVariables: [AnySnapshotController] = []

    var name: String

    lazy var initialState: MicrowaveState = {
        CallbackMicrowaveState(
            "Off",
            transitions: [Transition(onState) { [unowned self] _ in self.doorOpen.val || self.timeLeft.val }],
            snapshotSensors: [doorOpen.name, timeLeft.name],
            snapshotActuators: [light.name],
            onEntry: { [unowned self] in self.light.val = false }
        )
    }()

    lazy var onState: MicrowaveState = {
        CallbackMicrowaveState(
            "On",
            snapshotSensors: [doorOpen.name, timeLeft.name],
            snapshotActuators: [light.name],
            onEntry: { [unowned self] in self.light.val = true }
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
        let fsm = LightFiniteStateMachine(name: name, doorOpen: doorOpen.clone(), timeLeft: timeLeft.clone(), light: light)
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
        fsm.light = light.clone()
        fsm.ringlet = ringlet.clone()
        if fsm.ringlet.previousState.name == initialState.name {
            fsm.ringlet.previousState = fsm.initialState
        } else if fsm.ringlet.previousState.name == onState.name {
            fsm.ringlet.previousState = fsm.onState
        }
        return fsm
    }

    init(name: String, doorOpen: InMemoryVariable<Bool>, timeLeft: InMemoryVariable<Bool>, light: InMemoryVariable<Bool>) {
        self.name = name
        self.doorOpen = doorOpen
        self.timeLeft = timeLeft
        self.light = light
        self.onState.addTransition(MicrowaveTransition(UnownedTransition(initialState) { [unowned self] _ in !self.doorOpen.val && !self.timeLeft.val }))
    }

}
