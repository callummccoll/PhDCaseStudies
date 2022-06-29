import swiftfsm
import SwiftfsmWBWrappers

public final class AlarmState_On: AlarmState {

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

    public internal(set) var fsmVars: AlarmVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public init(
        _ name: String,
        transitions: [Transition<AlarmState_On, AlarmState>] = [],
        gateway: FSMGateway,
        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(name, transitions: transitions.map { AlarmStateTransition($0) }, snapshotSensors: ["status", "sound"], snapshotActuators: ["status", "sound"])
    }

    public override func onEntry() {
        sound = true
    }

    public override func onExit() {
    }

    public override func main() {
    }

    public override final func clone() -> AlarmState_On {
        let transitions: [Transition<AlarmState_On, AlarmState>] = self.transitions.map { $0.cast(to: AlarmState_On.self) }
        let state = AlarmState_On(
            self.name,
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock
        )
        state.Me = self.Me
        return state
    }

}

extension AlarmState_On: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
