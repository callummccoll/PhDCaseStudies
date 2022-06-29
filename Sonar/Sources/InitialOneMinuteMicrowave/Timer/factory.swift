import swiftfsm
import SwiftfsmWBWrappers

public func make_Timer(name: String = "Timer", gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Timer(name: name, gateway: gateway, clock: clock, status: status)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Timer(name machineName: String, gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    // External Variables.
    var external_status = status
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: TimerVars())
    // States.
    var state_Initial = State_Initial(
        "Check",
        gateway: gateway,
        clock: clock
    )
    var state_Add_1_Minute = State_Add_1_Minute(
        "Add_1_Minute",
        gateway: gateway,
        clock: clock
    )
    var state_Decrement_1_Minute = State_Decrement_1_Minute(
        "Decrement_1_Minute",
        gateway: gateway,
        clock: clock
    )
    // State Transitions.
    state_Initial.addTransition(TimerStateTransition(Transition<State_Initial, TimerState>(state_Decrement_1_Minute) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var fsmVars: TimerVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var currentTime: UInt8 {
            get {
                return fsmVars.currentTime
            }
            set {
                fsmVars.currentTime = newValue
            }
        }

        return currentTime > 0 && !status.doorOpen && status.timeLeft && clock.after(60)
    }))
    state_Initial.addTransition(TimerStateTransition(Transition<State_Initial, TimerState>(state_Add_1_Minute) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var fsmVars: TimerVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var currentTime: UInt8 {
            get {
                return fsmVars.currentTime
            }
            set {
                fsmVars.currentTime = newValue
            }
        }

        return status.buttonPushed && !status.doorOpen && currentTime < 15
    }))
    state_Add_1_Minute.addTransition(TimerStateTransition(Transition<State_Add_1_Minute, TimerState>(state_Initial) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var fsmVars: TimerVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var currentTime: UInt8 {
            get {
                return fsmVars.currentTime
            }
            set {
                fsmVars.currentTime = newValue
            }
        }

        return !status.buttonPushed
    }))
    state_Decrement_1_Minute.addTransition(TimerStateTransition(Transition<State_Decrement_1_Minute, TimerState>(state_Initial) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var fsmVars: TimerVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var currentTime: UInt8 {
            get {
                return fsmVars.currentTime
            }
            set {
                fsmVars.currentTime = newValue
            }
        }

        return true
    }))
    let ringlet = TimerRinglet()
    // Create FSM.
    let fsm = TimerFiniteStateMachine(
        name: machineName,
        initialState: state_Initial,
        external_status: external_status,
        fsmVars: fsmVars,
        ringlet: ringlet,
        initialPreviousState: EmptyTimerState("_Previous"),
        suspendedState: nil,
        suspendState: EmptyTimerState("_Suspend"),
        exitState: EmptyTimerState("_Exit"),
        submachines: []
    )
    state_Initial.Me = fsm
    state_Add_1_Minute.Me = fsm
    state_Decrement_1_Minute.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [])
}



