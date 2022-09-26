import swiftfsm
import SharedVariables

public final class CallerState_Initial: CallerState {

    public override var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": [],
            "gateway": [],
            "clock": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "Me": [],
            "_Sonar": []
        ]
    }

    fileprivate let gateway: FSMGateway

    public let clock: Timer

    public internal(set) var fsmVars: CallerVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public var promise23: Promise<UInt16>!

    public var promise45: Promise<UInt16>!

    public var promise67: Promise<UInt16>!

    let _Sonar23: (SonarPin, SonarPin, SonarPin) -> Promise<UInt16>

    let _Sonar45: (SonarPin, SonarPin, SonarPin) -> Promise<UInt16>

    let _Sonar67: (SonarPin, SonarPin, SonarPin) -> Promise<UInt16>

    public init(
        _ name: String,
        transitions: [Transition<CallerState_Initial, CallerState>] = [],
        gateway: FSMGateway,
        clock: Timer,
        Sonar23: @escaping (SonarPin, SonarPin, SonarPin) -> Promise<UInt16>,
        Sonar45: @escaping (SonarPin, SonarPin, SonarPin) -> Promise<UInt16>,
        Sonar67: @escaping (SonarPin, SonarPin, SonarPin) -> Promise<UInt16>
    ) {
        self.gateway = gateway
        self.clock = clock
        self._Sonar23 = Sonar23
        self._Sonar45 = Sonar45
        self._Sonar67 = Sonar67
        super.init(name, transitions: transitions.map { CallerStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override func onEntry() {
        promise23 = Sonar23(echoPin: .pin2Control, triggerPin: .pin3Control, echoPinValue: .pin2Status)
        promise45 = Sonar45(echoPin: .pin4Control, triggerPin: .pin5Control, echoPinValue: .pin4Status)
        promise67 = Sonar67(echoPin: .pin6Control, triggerPin: .pin7Control, echoPinValue: .pin6Status)
    }

    public override func onExit() {
        promise23 = nil
        promise45 = nil
        promise67 = nil
    }

    public override func main() {}

    func Sonar23(echoPin: SonarPin, triggerPin: SonarPin, echoPinValue: SonarPin) -> Promise<UInt16> {
        self._Sonar23(echoPin, triggerPin, echoPinValue)
    }

    func Sonar45(echoPin: SonarPin, triggerPin: SonarPin, echoPinValue: SonarPin) -> Promise<UInt16> {
        self._Sonar45(echoPin, triggerPin, echoPinValue)
    }

    func Sonar67(echoPin: SonarPin, triggerPin: SonarPin, echoPinValue: SonarPin) -> Promise<UInt16> {
        self._Sonar67(echoPin, triggerPin, echoPinValue)
    }

    public override final func clone() -> CallerState_Initial {
        let transitions: [Transition<CallerState_Initial, CallerState>] = self.transitions.map { $0.cast(to: CallerState_Initial.self) }
        let state = CallerState_Initial(
            "Initial",
            transitions: transitions,
            gateway: self.gateway,
            clock: self.clock,
            Sonar23: _Sonar23,
            Sonar45: _Sonar45,
            Sonar67: _Sonar67
        )
        state.Me = self.Me
        state.promise23 = self.promise23
        state.promise45 = self.promise45
        state.promise67 = self.promise67
        return state
    }

}

extension CallerState_Initial: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
