import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SharedVariables

final class AlarmFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = MiPalState
    typealias Ringlet = MiPalRinglet

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
            "timeLeft": [],
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

    var buttonPushed: InMemoryVariable<Bool>

    var doorOpen: InMemoryVariable<Bool>

    var timeLeft: InMemoryVariable<Bool>

    var sound: InMemoryVariable<Bool>

    var clock: Timer

    var sensors: [AnySnapshotController] {
        get {
            [AnySnapshotController(timeLeft)]
        } set {
            if let val = newValue.first(where: { $0.name == timeLeft.name })?.val {
                timeLeft.val = val as! Bool
            }
        }
    }

    var actuators: [AnySnapshotController] = []

    var externalVariables: [AnySnapshotController] {
        get {
            [AnySnapshotController(buttonPushed), AnySnapshotController(doorOpen), AnySnapshotController(sound)]
        } set {
            if let val = newValue.first(where: { $0.name == buttonPushed.name })?.val {
                buttonPushed.val = val as! Bool
            }
            if let val = newValue.first(where: { $0.name == doorOpen.name })?.val {
                doorOpen.val = val as! Bool
            }
            if let val = newValue.first(where: { $0.name == sound.name })?.val {
                sound.val = val as! Bool
            }
        }
    }

    var name: String

    lazy var initialState: MiPalState = {
        CallbackMiPalState(
            "Off",
            transitions: [Transition(armedState) { [unowned self] _ in self.timeLeft.val }],
            snapshotSensors: [buttonPushed.name, doorOpen.name, timeLeft.name, sound.name],
            snapshotActuators: [buttonPushed.name, doorOpen.name, sound.name],
            onEntry: { [unowned self] in sound.val = false }
        )
    }()

    lazy var armedState: MiPalState = {
        CallbackMiPalState(
            "Armed",
            transitions: [],
            snapshotSensors: [buttonPushed.name, doorOpen.name, timeLeft.name, sound.name],
            snapshotActuators: [buttonPushed.name, doorOpen.name, sound.name]
        )
    }()

    lazy var onState: MiPalState = {
        CallbackMiPalState(
            "On",
            transitions: [],
            snapshotSensors: [buttonPushed.name, doorOpen.name, timeLeft.name, sound.name],
            snapshotActuators: [buttonPushed.name, doorOpen.name, sound.name],
            onEntry: { [unowned self] in self.sound.val = true }
        )
    }()

    lazy var currentState: MiPalState = { initialState }()

    var previousState: MiPalState = EmptyMiPalState("previous")

    var suspendedState: MiPalState? = nil

    var suspendState: MiPalState = EmptyMiPalState("suspend")

    var exitState: MiPalState = EmptyMiPalState("exit", snapshotSensors: [])

    var submachines: [AlarmFiniteStateMachine] = []

    var initialPreviousState: MiPalState = EmptyMiPalState("previous")

    var ringlet = MiPalRinglet(previousState: EmptyMiPalState("previous"))

    private func update<T>(keyPath: WritableKeyPath<T, MiPalState>, target: inout T) {
        switch target[keyPath: keyPath].name {
        case initialState.name:
            target[keyPath: keyPath] = initialState
        case armedState.name:
            target[keyPath: keyPath] = armedState
        case onState.name:
            target[keyPath: keyPath] = onState
        case initialPreviousState.name:
            target[keyPath: keyPath] = initialPreviousState
        default:
            fatalError("This should never happen.")
        }
    }

    func clone() -> AlarmFiniteStateMachine {
        var fsm = AlarmFiniteStateMachine(name: name, buttonPushed: buttonPushed.clone(), doorOpen: doorOpen.clone(), timeLeft: timeLeft.clone(), sound: sound.clone(), clock: clock)
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

    init(name: String, buttonPushed: InMemoryVariable<Bool>, doorOpen: InMemoryVariable<Bool>, timeLeft: InMemoryVariable<Bool>, sound: InMemoryVariable<Bool>, clock: Timer) {
        self.name = name
        self.buttonPushed = buttonPushed
        self.doorOpen = doorOpen
        self.timeLeft = timeLeft
        self.sound = sound
        self.clock = clock
        self.armedState.addTransition(Transition(onState) { [unowned self] _ in !self.timeLeft.val })
        self.onState.addTransition(Transition(initialState) { [unowned self] _ in self.clock.after(2) })
    }

}
