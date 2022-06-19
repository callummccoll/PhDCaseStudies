import swiftfsm
import SwiftfsmWBWrappers

public func make_Caller(name: String = "Caller", gateway: FSMGateway, clock: Timer, caller: FSM_ID) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Caller(name: name, gateway: gateway, clock: clock, caller: caller)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Caller(name machineName: String, gateway: FSMGateway, clock: Timer, caller: FSM_ID) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: CallerVars())
    // States.
    var state_Initial = CallerState_Initial(
        "Initial",
        gateway: gateway,
        clock: clock
    )
    let ringlet = CallerRinglet()
    // Create FSM.
    let fsm = CallerFiniteStateMachine(
        name: machineName,
        initialState: state_Initial,
        fsmVars: fsmVars,
        ringlet: ringlet,
        initialPreviousState: EmptyCallerState("_Previous"),
        suspendedState: nil,
        suspendState: EmptyCallerState("_Suspend"),
        exitState: EmptyCallerState("_Exit"),
        submachines: []
    )
    state_Initial.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [])
}



