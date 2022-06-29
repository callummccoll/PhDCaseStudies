import swiftfsm
import SwiftfsmWBWrappers

public func make_Cooking(name: String = "Cooking", gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>, motor: WhiteboardVariable<Bool>) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Cooking(name: name, gateway: gateway, clock: clock, status: status, motor: motor)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Cooking(name machineName: String, gateway: FSMGateway, clock: Timer, status: WhiteboardVariable<MicrowaveStatus>, motor: WhiteboardVariable<Bool>) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    // External Variables.
    var external_status = status
    var external_motor = motor
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: CookingVars())
    // States.
    var state_Not_Cooking = CookingState_Not_Cooking(
        "Not_Cooking",
        gateway: gateway,
        clock: clock
    )
    var state_Cooking = CookingState_Cooking(
        "Cooking",
        gateway: gateway,
        clock: clock
    )
    // State Transitions.
    state_Not_Cooking.addTransition(CookingStateTransition(Transition<CookingState_Not_Cooking, CookingState>(state_Cooking) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var motor: Bool {
            get {
                Me.external_motor.val
            } set {
                Me.external_motor.val = newValue
            }
        }

        var fsmVars: CookingVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return !status.doorOpen && status.timeLeft
    }))
    state_Cooking.addTransition(CookingStateTransition(Transition<CookingState_Cooking, CookingState>(state_Not_Cooking) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var status: MicrowaveStatus {
            get {
                Me.external_status.val
            } set {
                Me.external_status.val = newValue
            }
        }

        var motor: Bool {
            get {
                Me.external_motor.val
            } set {
                Me.external_motor.val = newValue
            }
        }

        var fsmVars: CookingVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        return status.doorOpen || !status.timeLeft
    }))
    let ringlet = CookingRinglet()
    // Create FSM.
    let fsm = CookingFiniteStateMachine(
        name: machineName,
        initialState: state_Not_Cooking,
        external_status: external_status,
        external_motor: external_motor,
        fsmVars: fsmVars,
        ringlet: ringlet,
        initialPreviousState: EmptyCookingState("_Previous"),
        suspendedState: nil,
        suspendState: EmptyCookingState("_Suspend"),
        exitState: EmptyCookingState("_Exit"),
        submachines: []
    )
    state_Not_Cooking.Me = fsm
    state_Cooking.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [])
}



