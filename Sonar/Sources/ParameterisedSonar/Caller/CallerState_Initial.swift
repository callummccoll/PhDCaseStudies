import swiftfsm
import SwiftfsmWBWrappers

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

    public internal(set) var distance23: UInt16? {
        get {
            return fsmVars.distance23
        }
        set {
            fsmVars.distance23 = newValue
        }
    }

    public internal(set) var distance45: UInt16? {
        get {
            return fsmVars.distance45
        }
        set {
            fsmVars.distance45 = newValue
        }
    }

    public var promise23: Promise<UInt16>!

    public var promise45: Promise<UInt16>!

    let _Sonar23: (wb_types, wb_types, wb_types) -> Promise<UInt16>

    let _Sonar45: (wb_types, wb_types, wb_types) -> Promise<UInt16>

    public init(
        _ name: String,
        transitions: [Transition<CallerState_Initial, CallerState>] = [],
        gateway: FSMGateway,
        clock: Timer,
        Sonar23: @escaping (wb_types, wb_types, wb_types) -> Promise<UInt16>,
        Sonar45: @escaping (wb_types, wb_types, wb_types) -> Promise<UInt16>
    ) {
        self.gateway = gateway
        self.clock = clock
        self._Sonar23 = Sonar23
        self._Sonar45 = Sonar45
        super.init(name, transitions: transitions.map { CallerStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override func onEntry() {
        promise23 = Sonar23(echoPin: kwb_Arduino2Pin_v, triggerPin: kwb_Arduino3Pin_v, echoPinValue: kwb_Arduino2PinValue_v)
        promise45 = Sonar45(echoPin: kwb_Arduino4Pin_v, triggerPin: kwb_Arduino5Pin_v, echoPinValue: kwb_Arduino4PinValue_v)
    }

    public override func onExit() {
        distance23 = promise23.result
        distance45 = promise23.result
        promise23 = nil
        promise45 = nil
    }

    public override func main() {}

    func Sonar23(echoPin: wb_types, triggerPin: wb_types, echoPinValue: wb_types) -> Promise<UInt16> {
        self._Sonar23(echoPin, triggerPin, echoPinValue)
    }

    func Sonar45(echoPin: wb_types, triggerPin: wb_types, echoPinValue: wb_types) -> Promise<UInt16> {
        self._Sonar45(echoPin, triggerPin, echoPinValue)
    }

    public override final func clone() -> CallerState_Initial {
        let transitions: [Transition<CallerState_Initial, CallerState>] = self.transitions.map { $0.cast(to: CallerState_Initial.self) }
        let state = CallerState_Initial(
            "Initial",
            transitions: transitions,
            gateway: self.gateway,
            clock: self.clock,
            Sonar23: _Sonar23,
            Sonar45: _Sonar45
        )
        state.Me = self.Me
        state.promise23 = self.promise23
        state.promise45 = self.promise45
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
