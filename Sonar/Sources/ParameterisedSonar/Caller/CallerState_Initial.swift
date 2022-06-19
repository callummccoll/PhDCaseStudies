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

    public init(
        _ name: String,
        transitions: [Transition<CallerState_Initial, CallerState>] = [],
        gateway: FSMGateway
,        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(name, transitions: transitions.map { CallerStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override func onEntry() {}

    public override func onExit() {}

    public override func main() {}

    public override final func clone() -> CallerState_Initial {
        let transitions: [Transition<CallerState_Initial, CallerState>] = self.transitions.map { $0.cast(to: CallerState_Initial.self) }
        let state = CallerState_Initial(
            "Initial",
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock
        )
        state.Me = self.Me
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
