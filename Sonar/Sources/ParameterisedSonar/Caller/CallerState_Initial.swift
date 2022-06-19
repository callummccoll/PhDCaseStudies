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
            "Me": []
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

    public var promise: Promise<UInt16>!

    let _Sonar: (wb_types, wb_types, wb_types) -> Promise<UInt16>

    public init(
        _ name: String,
        transitions: [Transition<CallerState_Initial, CallerState>] = [],
        gateway: FSMGateway
,        clock: Timer,
        Sonar: @escaping (wb_types, wb_types, wb_types) -> Promise<UInt16>
    ) {
        self.gateway = gateway
        self.clock = clock
        self._Sonar = Sonar
        super.init(name, transitions: transitions.map { CallerStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override func onEntry() {}

    public override func onExit() {}

    public override func main() {}

    func Sonar(echoPin: wb_types, triggerPin: wb_types, echoPinValue: wb_types) -> Promise<UInt16> {
        self._Sonar(echoPin, triggerPin, echoPinValue)
    }

    public override final func clone() -> CallerState_Initial {
        let transitions: [Transition<CallerState_Initial, CallerState>] = self.transitions.map { $0.cast(to: CallerState_Initial.self) }
        let state = CallerState_Initial(
            "Initial",
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock,
            Sonar: _Sonar
        )
        state.Me = self.Me
        state.promise = self.promise
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
