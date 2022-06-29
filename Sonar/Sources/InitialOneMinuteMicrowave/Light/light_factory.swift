import swiftfsm
import SwiftfsmWBWrappers

public func make_Light(name: String = "Light", gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>, light: WhiteboardVariable<Bool>) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Light(name: name, gateway: gateway, clock: clock, status: status, light: light)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Light(name machineName: String, gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>, light: WhiteboardVariable<Bool>) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    // External Variables.
    var external_status = status
    var external_light = light
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: LightVars())
    // States.
    var state_Off = LightState_Off(
        "Off",
        gateway: gateway,
        clock: clock
    )
    var state_On = LightState_On(
        "On",
        gateway: gateway,
        clock: clock
    )
    // State Transitions.
    state_Off.addTransition(LightStateTransition(Transition<LightState_Off, LightState>(state_On) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var light: Bool {
            get {
                Me.external_light.val
            } set {
                Me.external_light.val = newValue
            }
        }

        var fsmVars: LightVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return status.doorOpen || status.timeLeft
    }))
    state_On.addTransition(LightStateTransition(Transition<LightState_On, LightState>(state_Off) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var light: Bool {
            get {
                Me.external_light.val
            } set {
                Me.external_light.val = newValue
            }
        }

        var fsmVars: LightVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return !status.doorOpen && !status.timeLeft
    }))
    let ringlet = LightRinglet()
    // Create FSM.
    let fsm = LightFiniteStateMachine(
        name: machineName,
        initialState: state_Off,
        external_status: external_status,
        external_light: external_light,
        fsmVars: fsmVars,
        ringlet: ringlet,
        initialPreviousState: EmptyLightState("_Previous"),
        suspendedState: nil,
        suspendState: EmptyLightState("_Suspend"),
        exitState: EmptyLightState("_Exit"),
        submachines: []
    )
    state_Off.Me = fsm
    state_On.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [])
}



