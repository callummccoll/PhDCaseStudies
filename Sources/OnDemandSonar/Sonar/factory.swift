import swiftfsm
import SharedVariables

public func make_Sonar(name: String = "Sonar", gateway: FSMGateway, clock: Timer, caller: FSM_ID, echoPin: SonarPin, triggerPin: SonarPin, echoPinValue: SonarPin) -> (FSMType, [ShallowDependency]) {
    let (fsm, dependencies) = make_parameterised_Sonar(name: name, gateway: gateway, clock: clock, caller: caller, echoPin: echoPin, triggerPin: triggerPin, echoPinValue: echoPinValue)
    return (FSMType.parameterisedFSM(fsm), dependencies)
}

public func make_parameterised_Sonar(name machineName: String, gateway: FSMGateway, clock: Timer, caller: FSM_ID, echoPin: SonarPin, triggerPin: SonarPin, echoPinValue: SonarPin) -> (AnyParameterisedFiniteStateMachine, [ShallowDependency]) {
    // External Variables.
    let external_echoPin: InMemoryVariable<Bool> = InMemoryVariable(name: echoPin.rawValue, initialValue: false)
    let external_triggerPin: InMemoryVariable<Bool> = InMemoryVariable(name: triggerPin.rawValue, initialValue: false)
    let external_echoPinValue: InMemoryVariable<Bool> = InMemoryVariable(name: echoPinValue.rawValue, initialValue: false)
    // FSM Variables.
    let fsmVars = SimpleVariablesContainer(vars: SonarVars())
    // States.
    var state_Initial = State_Initial(
        "Initial",
        gateway: gateway,
        clock: clock
    )
    var state_Setup_Pin = State_Setup_Pin(
        "Setup_Pin",
        gateway: gateway,
        clock: clock
    )
    let state_Suspend = State_Suspend(
        "Suspend",
        gateway: gateway,
        clock: clock
    )
    var state_SkipGarbage = State_SkipGarbage(
        "SkipGarbage",
        gateway: gateway,
        clock: clock
    )
    var state_SetupMeasure = State_SetupMeasure(
        "SetupMeasure",
        gateway: gateway,
        clock: clock
    )
    var state_WaitForPulseStart = State_WaitForPulseStart(
        "WaitForPulseStart",
        gateway: gateway,
        clock: clock
    )
    var state_ClearTrigger = State_ClearTrigger(
        "ClearTrigger",
        gateway: gateway,
        clock: clock
    )
    var state_WaitForPulseEnd = State_WaitForPulseEnd(
        "WaitForPulseEnd",
        gateway: gateway,
        clock: clock
    )
    var state_LostPulse = State_LostPulse(
        "LostPulse",
        gateway: gateway,
        clock: clock
    )
    var state_CalculateDistance = State_CalculateDistance(
        "CalculateDistance",
        gateway: gateway,
        clock: clock
    )
    // State Transitions.
    state_Initial.addTransition(SonarStateTransition(Transition<State_Initial, SonarState>(state_Setup_Pin) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }
        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var echoPin: SonarPin {
            parameters.echoPin
        }

        var triggerPin: SonarPin {
            parameters.triggerPin
        }

        var echoPinValue: SonarPin {
            parameters.echoPinValue
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        return true
    }))
    state_Setup_Pin.addTransition(SonarStateTransition(Transition<State_Setup_Pin, SonarState>(state_SetupMeasure) { state in
        let Me = state.Me!
        let clock: Timer = state.clock

        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        var echoPin: Bool {
            get {
                return Me.external_echoPin.val
            }
            set {
                Me.external_echoPin.val = newValue
            }
        }

        var triggerPin: Bool {
            get {
                return Me.external_triggerPin.val
            }
            set {
                Me.external_triggerPin.val = newValue
            }
        }

        return true
    }))
    state_SkipGarbage.addTransition(SonarStateTransition(Transition<State_SkipGarbage, SonarState>(state_WaitForPulseStart) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        var echoPinValue: Bool {
            get {
                return Me.external_echoPinValue.val
            }
        }

        var triggerPin: Bool {
            get {
                return Me.external_triggerPin.val
            }
            set {
                Me.external_triggerPin.val = newValue
            }
        }

        return numLoops >= maxLoops || !echoPinValue
    }))
    state_SetupMeasure.addTransition(SonarStateTransition(Transition<State_SetupMeasure, SonarState>(state_SkipGarbage) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        return true
    }))
    state_WaitForPulseStart.addTransition(SonarStateTransition(Transition<State_WaitForPulseStart, SonarState>(state_LostPulse) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        return numLoops >= maxLoops
    }))
    state_WaitForPulseStart.addTransition(SonarStateTransition(Transition<State_WaitForPulseStart, SonarState>(state_ClearTrigger) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        return clock.after_ms(1)
    }))
    state_ClearTrigger.addTransition(SonarStateTransition(Transition<State_ClearTrigger, SonarState>(state_LostPulse) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        var echoPinValue: Bool {
            get {
                return Me.external_echoPinValue.val
            }
        }

        var triggerPin: Bool {
            get {
                return Me.external_triggerPin.val
            }
            set {
                Me.external_triggerPin.val = newValue
            }
        }

        return numLoops >= maxLoops
    }))
    state_ClearTrigger.addTransition(SonarStateTransition(Transition<State_ClearTrigger, SonarState>(state_WaitForPulseEnd) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        var echoPinValue: Bool {
            get {
                return Me.external_echoPinValue.val
            }
        }

        var triggerPin: Bool {
            get {
                return Me.external_triggerPin.val
            }
            set {
                Me.external_triggerPin.val = newValue
            }
        }

        return echoPinValue
    }))
    state_WaitForPulseEnd.addTransition(SonarStateTransition(Transition<State_WaitForPulseEnd, SonarState>(state_LostPulse) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        var echoPinValue: Bool {
            get {
                return Me.external_echoPinValue.val
            }
        }

        return numLoops >= maxLoops
    }))
    state_WaitForPulseEnd.addTransition(SonarStateTransition(Transition<State_WaitForPulseEnd, SonarState>(state_CalculateDistance) { state in
        let Me = state.Me!
        let clock: Timer = state.clock
        var parameters: SonarFiniteStateMachine.Parameters.Vars {
            get {
                return Me.parameters.vars
            } set {
                Me.parameters.vars = newValue
            }
        }

        var fsmVars: SonarVars {
            get {
                return Me.fsmVars.vars
            }
            set {
                Me.fsmVars.vars = newValue
            }
        }

        var result: UInt16? {
            get {
                return Me.results.vars.result
            }
            set {
                Me.results.vars.result = newValue
            }
        }

        var numLoops: UInt16 {
            get {
                return fsmVars.numLoops
            }
            set {
                fsmVars.numLoops = newValue
            }
        }

        var maxLoops: UInt16 {
            get {
                return fsmVars.maxLoops
            }
            set {
                fsmVars.maxLoops = newValue
            }
        }

        var SPEED_OF_SOUND: Double {
            get {
                return fsmVars.SPEED_OF_SOUND
            }
        }

        var SCHEDULE_LENGTH: Double {
            get {
                return fsmVars.SCHEDULE_LENGTH
            }
            set {
                fsmVars.SCHEDULE_LENGTH = newValue
            }
        }

        var SONAR_OFFSET: Double {
            get {
                return fsmVars.SONAR_OFFSET
            }
            set {
                fsmVars.SONAR_OFFSET = newValue
            }
        }

        var echoPinValue: Bool {
            get {
                return Me.external_echoPinValue.val
            }
        }

        return !echoPinValue
    }))
    let ringlet = SonarRinglet()
    // Create FSM.
    let fsm = SonarFiniteStateMachine(
        name: machineName,
        initialState: state_Initial,
        external_echoPin: external_echoPin,
        external_triggerPin: external_triggerPin,
        external_echoPinValue: external_echoPinValue,

        fsmVars: fsmVars,
        ringlet: ringlet,
        initialPreviousState: EmptySonarState("_Previous"),
        suspendedState: nil,
        suspendState: state_Suspend,
        exitState: EmptySonarState("_Exit"),
        submachines: []
    )
    state_Initial.Me = fsm
    state_Setup_Pin.Me = fsm
    state_Suspend.Me = fsm
    state_SkipGarbage.Me = fsm
    state_SetupMeasure.Me = fsm
    state_WaitForPulseStart.Me = fsm
    state_ClearTrigger.Me = fsm
    state_WaitForPulseEnd.Me = fsm
    state_LostPulse.Me = fsm
    state_CalculateDistance.Me = fsm
    return (
        AnyParameterisedFiniteStateMachine(fsm) { parameters in
            guard
                let echoPin = parameters["echoPin"] as? SonarPin,
                let triggerPin = parameters["triggerPin"] as? SonarPin,
                let echoPinValue = parameters["echoPinValue"] as? SonarPin
            else {
                fatalError("Unable to create new machine from parameters: \(parameters)")
            }
            let newFSM = make_parameterised_Sonar(name: machineName, gateway: gateway, clock: clock, caller: caller, echoPin: echoPin, triggerPin: triggerPin, echoPinValue: echoPinValue).0
            return newFSM
        },
        []
    )
}



