import swiftfsm
import SwiftfsmWBWrappers

public func make_Alarm(name: String = "Alarm", gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>, sound: WhiteboardVariable<Bool>) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Alarm(name: name, gateway: gateway, clock: clock, status: status, sound: sound)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Alarm(name machineName: String, gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>, sound: WhiteboardVariable<Bool>) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    // External Variables.
    var external_status = status
    var external_sound = sound
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: AlarmVars())
    // States.
    var state_Off = AlarmState_Off(
        "Off",
        gateway: gateway,
        clock: clock
    )
    var state_Armed = AlarmState_Armed(
        "Armed",
        gateway: gateway,
        clock: clock
    )
    var state_On = AlarmState_On(
        "On",
        gateway: gateway,
        clock: clock
    )
    // State Transitions.
    state_Off.addTransition(AlarmStateTransition(Transition<AlarmState_Off, AlarmState>(state_Armed) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var sound: Bool {
            get {
                Me.external_sound.val
            } set {
                Me.external_sound.val = newValue
            }
        }

        var fsmVars: AlarmVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return status.timeLeft
    }))
    state_Armed.addTransition(AlarmStateTransition(Transition<AlarmState_Armed, AlarmState>(state_On) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var sound: Bool {
            get {
                Me.external_sound.val
            } set {
                Me.external_sound.val = newValue
            }
        }

        var fsmVars: AlarmVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return !status.timeLeft
    }))
    state_On.addTransition(AlarmStateTransition(Transition<AlarmState_Armed, AlarmState>(state_Off) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var sound: Bool {
            get {
                Me.external_sound.val
            } set {
                Me.external_sound.val = newValue
            }
        }

        var fsmVars: AlarmVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return clock.after(2)
    }))
    let ringlet = AlarmRinglet()
    // Create FSM.
    let fsm = AlarmFiniteStateMachine(
        name: machineName,
        initialState: state_Off,
        external_status: external_status,
        external_sound: external_sound,
        fsmVars: fsmVars,
        ringlet: ringlet,
        initialPreviousState: EmptyAlarmState("_Previous"),
        suspendedState: nil,
        suspendState: EmptyAlarmState("_Suspend"),
        exitState: EmptyAlarmState("_Exit"),
        submachines: []
    )
    state_Off.Me = fsm
    state_Armed.Me = fsm
    state_On.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [])
}



