import swiftfsm
import SwiftfsmWBWrappers

public func make_Caller(name: String = "Caller", gateway: FSMGateway, clock: Timer, caller: FSM_ID) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Caller(name: name, gateway: gateway, clock: clock, caller: caller)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Caller(name machineName: String, gateway: FSMGateway, clock: Timer, caller: FSM_ID) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    let myID = gateway.id(of: machineName)
    let sonarID = gateway.id(of: "Sonar")
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: CallerVars())
    // States.
    var state_Initial = CallerState_Initial(
        "Initial",
        gateway: gateway,
        clock: clock,
        Sonar: { (echoPin, triggerPin, echoPinValue) in
            gateway.call(
                sonarID,
                withParameters: [
                    "echoPin": echoPin,
                    "triggerPin": triggerPin,
                    "echoPinValue": echoPinValue
                ],
                caller: myID
            )
        }
    )
    let state_Exit = EmptyCallerState("Exit")
    state_Initial.addTransition(CallerStateTransition(Transition<CallerState_Initial, CallerState>(state_Exit) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var fsmVars: CallerVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }
        return state.promise.hasFinished
    }))
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



