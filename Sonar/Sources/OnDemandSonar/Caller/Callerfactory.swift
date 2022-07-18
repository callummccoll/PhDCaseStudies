import swiftfsm
import SharedVariables

public func make_Caller(name: String = "Caller", gateway: FSMGateway, clock: Timer) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_submachine_Caller(name: name, gateway: gateway, clock: clock)
    return (FSMType.controllableFSM(fsm), dependencies)
}

public func make_submachine_Caller(name machineName: String, gateway: FSMGateway, clock: Timer) -> (AnyControllableFiniteStateMachine, [ShallowDependency]) {
    let myID = gateway.id(of: machineName)
    let sonar23ID = gateway.id(of: "Sonar23")
    let sonar45ID = gateway.id(of: "Sonar45")
    let sonar67ID = gateway.id(of: "Sonar67")
    let Sonar23: (SonarPin, SonarPin, SonarPin) -> Promise<UInt16> = { (echoPin, triggerPin, echoPinValue) in
        gateway.invoke(
            sonar23ID,
            withParameters: [
                "echoPin": echoPin,
                "triggerPin": triggerPin,
                "echoPinValue": echoPinValue
            ],
            caller: myID
        )
    }
    let Sonar45: (SonarPin, SonarPin, SonarPin) -> Promise<UInt16> = { (echoPin, triggerPin, echoPinValue) in
        gateway.invoke(
            sonar45ID,
            withParameters: [
                "echoPin": echoPin,
                "triggerPin": triggerPin,
                "echoPinValue": echoPinValue
            ],
            caller: myID
        )
    }
    let Sonar67: (SonarPin, SonarPin, SonarPin) -> Promise<UInt16> = { (echoPin, triggerPin, echoPinValue) in
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
    // States.
    let state_Initial = CallerState_Initial(
        "Initial",
        gateway: gateway,
        clock: clock,
        Sonar23: Sonar23,
        Sonar45: Sonar45,
        Sonar67: Sonar67
    )
    // Create FSM.
    let fsm = CallerFiniteStateMachine(
        name: machineName,
        clock: clock,
        fsmVars: CallerVars(),
        initialState: state_Initial
    )
    state_Initial.Me = fsm
    return (AnyControllableFiniteStateMachine(fsm), [.callableMachine(name: "Sonar")])
}



