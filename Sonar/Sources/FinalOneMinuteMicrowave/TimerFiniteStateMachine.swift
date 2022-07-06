import FSM
import KripkeStructure
import Gateways
import Timers
import Verification
import swiftfsm
import SwiftfsmWBWrappers

final class TimerFiniteStateMachine: MachineProtocol, CustomStringConvertible {

    typealias _StateType = MiPalState
    typealias Ringlet = MiPalRinglet

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
            "buttonPushed": [],
            "doorOpen": [],
            "timeLeft": [],
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
            "sensors": Dictionary(uniqueKeysWithValues: sensors.map { ($0.name, $0.val) }),
            "actuators": Dictionary(uniqueKeysWithValues: actuators.map { ($0.name, $0.val) }),
            "externalVariables": Dictionary(uniqueKeysWithValues: externalVariables.map { ($0.name, $0.val) }),
            "fsmVars": ["currentTime": currentTime],
            "currentState": currentState.name,
            "isSuspended": isSuspended,
            "hasFinished": hasFinished
        ]
    }

    var clock: Timer

    var buttonPushed: WhiteboardVariable<Bool>

    var doorOpen: WhiteboardVariable<Bool>

    var timeLeft: WhiteboardVariable<Bool>

    var sensors: [AnySnapshotController] {
        get {
            [AnySnapshotController(buttonPushed), AnySnapshotController(doorOpen)]
        } set {
            if let val = newValue.first(where: { $0.name == buttonPushed.name })?.val {
                buttonPushed.val = val as! Bool
            } else if let val = newValue.first(where: { $0.name == doorOpen.name })?.val {
                doorOpen.val = val as! Bool
            }
        }
    }

    var actuators: [AnySnapshotController] {
        get {
            [AnySnapshotController(timeLeft)]
        } set {
            if let val = newValue.first(where: { $0.name == timeLeft.name })?.val {
                timeLeft.val = val as! Bool
            }
        }
    }

    var externalVariables: [AnySnapshotController] = []

    var currentTime: UInt8 = 0

    var name: String

    lazy var initialState: MiPalState = {
        CallbackMiPalState(
            "Check",
            transitions: [],
            snapshotSensors: [buttonPushed.name, doorOpen.name],
            snapshotActuators: [timeLeft.name],
            onEntry: { [unowned self] in self.timeLeft.val = 0 < self.currentTime}
        )
    }()

    lazy var addState: MiPalState = {
        CallbackMiPalState(
            "Add_1_Minute",
            transitions: [],
            snapshotSensors: [buttonPushed.name, doorOpen.name],
            snapshotActuators: [timeLeft.name],
            onEntry: { [unowned self] in self.currentTime += 1},
            onExit: { [unowned self] in self.timeLeft.val = true }
        )
    }()

    lazy var decrementState: MiPalState = {
        CallbackMiPalState(
            "Decrement_1_Minute",
            transitions: [],
            snapshotSensors: [buttonPushed.name, doorOpen.name],
            snapshotActuators: [timeLeft.name],
            onEntry: { [unowned self] in self.currentTime -= 1 }
        )
    }()

    lazy var currentState: MiPalState = { initialState }()

    var previousState: MiPalState = EmptyMiPalState("previous")

    var suspendedState: MiPalState? = nil

    var suspendState: MiPalState = EmptyMiPalState("suspend")

    var exitState: MiPalState = EmptyMiPalState("exit", snapshotSensors: [])

    var submachines: [TimerFiniteStateMachine] = []

    var initialPreviousState: MiPalState = EmptyMiPalState("previous")

    var ringlet = MiPalRinglet(previousState: EmptyMiPalState("previous"))

    private func update<T>(keyPath: WritableKeyPath<T, MiPalState>, target: inout T) {
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
        var fsm = TimerFiniteStateMachine(name: name, buttonPushed: buttonPushed.clone(), doorOpen: doorOpen.clone(), timeLeft: timeLeft.clone(), clock: clock)
        fsm.name = name
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

    init(name: String, buttonPushed: WhiteboardVariable<Bool>, doorOpen: WhiteboardVariable<Bool>, timeLeft: WhiteboardVariable<Bool>, clock: Timer) {
        self.name = name
        self.buttonPushed = buttonPushed
        self.doorOpen = doorOpen
        self.timeLeft = timeLeft
        self.clock = clock
        initialState.addTransition(Transition(decrementState) { [unowned self] _ in
            self.currentTime > 0
                && !self.doorOpen.val
                && self.timeLeft.val
                && self.clock.after(60)
        })
        initialState.addTransition(Transition(addState) { [unowned self] _ in
            self.buttonPushed.val
                && !self.doorOpen.val
                && self.currentTime < 15
        })
        addState.addTransition(Transition(initialState) { [unowned self] _ in
            !self.buttonPushed.val
        })
        decrementState.addTransition(Transition(initialState) { _ in true })
    }

}
