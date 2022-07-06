import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SwiftfsmWBWrappers

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
            "status": [],
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
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var clock: Timer

    var status = WhiteboardVariable<MicrowaveStatus>(msgType: kwb_MicrowaveStatus_v)

    var sound = WhiteboardVariable<Bool>(msgType: kwb_sound_v)

    var sensors: [AnySnapshotController] = []

    var actuators: [AnySnapshotController] = []

    var externalVariables: [AnySnapshotController] {
        get {
            [AnySnapshotController(status), AnySnapshotController(sound)]
        } set {
            if let val = newValue.first(where: { $0.name == status.name })?.val {
                status.val = val as! MicrowaveStatus
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
            transitions: [Transition(armedState) { [self] _ in status.val.timeLeft }],
            snapshotSensors: [status.name, sound.name],
            snapshotActuators: [status.name, sound.name],
            onEntry: { [self] in sound.val = false }
        )
    }()

    lazy var armedState: MiPalState = {
        CallbackMiPalState(
            "Armed",
            transitions: [],
            snapshotSensors: [status.name, sound.name],
            snapshotActuators: [status.name, sound.name]
        )
    }()

    lazy var onState: MiPalState = {
        CallbackMiPalState(
            "On",
            transitions: [],
            snapshotSensors: [status.name, sound.name],
            snapshotActuators: [status.name, sound.name],
            onEntry: { [self] in sound.val = true }
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
        var fsm = AlarmFiniteStateMachine(name: name, status: status, sound: sound, clock: clock)
        fsm.name = name
        fsm.status = status.clone()
        fsm.sound = sound.clone()
        fsm.ringlet = ringlet.clone()
        fsm.currentState = currentState
        fsm.previousState = previousState
        fsm.ringlet.previousState = ringlet.previousState
        fsm.update(keyPath: \.currentState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm)
        fsm.update(keyPath: \.previousState, target: &fsm.ringlet)
        return fsm
    }

    init(name: String, status: WhiteboardVariable<MicrowaveStatus>, sound: WhiteboardVariable<Bool>, clock: Timer) {
        self.name = name
        self.status = status
        self.sound = sound
        self.clock = clock
        self.armedState.addTransition(Transition(onState) { [self] _ in !self.status.val.timeLeft })
        self.onState.addTransition(Transition(initialState) { [self] _ in self.clock.after(2) })
    }

}
