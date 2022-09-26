import swiftfsm

public final class State_Setup_Pin: SonarState {

    public override var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": [],
            "gateway": [],
            "clock": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "Me": []
        ]
    }

    public internal(set) var fsmVars: SonarVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public internal(set) var distance: UInt16 {
        get {
            return fsmVars.distance
        }
        set {
            fsmVars.distance = newValue
        }
    }

    public internal(set) var numLoops: UInt16 {
        get {
            return fsmVars.numLoops
        }
        set {
            fsmVars.numLoops = newValue
        }
    }

    public internal(set) var maxLoops: UInt16 {
        get {
            return fsmVars.maxLoops
        }
        set {
            fsmVars.maxLoops = newValue
        }
    }

    public var SPEED_OF_SOUND: Double {
        get {
            return fsmVars.SPEED_OF_SOUND
        }
    }

    public internal(set) var SCHEDULE_LENGTH: Double {
        get {
            return fsmVars.SCHEDULE_LENGTH
        }
        set {
            fsmVars.SCHEDULE_LENGTH = newValue
        }
    }

    public internal(set) var SONAR_OFFSET: Double {
        get {
            return fsmVars.SONAR_OFFSET
        }
        set {
            fsmVars.SONAR_OFFSET = newValue
        }
    }

    public internal(set) var echoPin: Bool {
        get {
            return Me.external_echoPin.val
        }
        set {
            Me.external_echoPin.val = newValue
        }
    }

    public internal(set) var triggerPin: Bool {
        get {
            return Me.external_triggerPin.val
        }
        set {
            Me.external_triggerPin.val = newValue
        }
    }

    public init(
        _ name: String,
        transitions: [Transition<State_Setup_Pin, SonarState>] = []
    ) {
        super.init(name, transitions: transitions.map { SonarStateTransition($0) }, snapshotSensors: [], snapshotActuators: ["echoPin", "triggerPin"])
    }

    public override func onEntry() {
        triggerPin = false
    }

    public override func onExit() {
        echoPin = false
    }

    public override func main() {
        
    }

    public override final func clone() -> State_Setup_Pin {
        var state = State_Setup_Pin(
            "Setup_Pin",
            transitions: []
        )
        self.transitions.forEach { state.addTransition($0) }
        state.Me = self.Me
        return state
    }

}

extension State_Setup_Pin: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}