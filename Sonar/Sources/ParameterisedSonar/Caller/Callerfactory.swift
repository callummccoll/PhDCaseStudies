import swiftfsm
import SwiftfsmWBWrappers

public func make_Caller(name: String = "Caller", gateway: FSMGateway, clock: Timer) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Caller(name: name, gateway: gateway, clock: clock)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Caller(name machineName: String, gateway: FSMGateway, clock: Timer) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    let myID = gateway.id(of: machineName)
    let sonar23ID = gateway.id(of: "Sonar23")
    let sonar45ID = gateway.id(of: "Sonar45")
    let sonar67ID = gateway.id(of: "Sonar67")
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: CallerVars())
    // States.
    var state_Initial = CallerState_Initial(
        "Initial",
        gateway: gateway,
        clock: clock,
        Sonar23: { (echoPin, triggerPin, echoPinValue) in
            gateway.invoke(
                sonar23ID,
                withParameters: [
                    "echoPin": echoPin,
                    "triggerPin": triggerPin,
                    "echoPinValue": echoPinValue
                ],
                caller: myID
            )
        },
        Sonar45: { (echoPin, triggerPin, echoPinValue) in
            gateway.invoke(
                sonar45ID,
                withParameters: [
                    "echoPin": echoPin,
                    "triggerPin": triggerPin,
                    "echoPinValue": echoPinValue
                ],
                caller: myID
            )
        },
        Sonar67: { (echoPin, triggerPin, echoPinValue) in
            gateway.invoke(
                sonar67ID,
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
        return state.promise23.hasFinished && state.promise45.hasFinished && state.promise67.hasFinished
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
    state_Exit.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [.callableMachine(name: "Sonar")])
}



