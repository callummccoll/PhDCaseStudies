import swiftfsm
import SwiftfsmWBWrappers

public final class LightState_On: LightState {

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

    public internal(set) var fsmVars: LightVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public init(
        _ name: String,
        transitions: [Transition<LightState_On, LightState>] = [],
        gateway: FSMGateway,
        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(
            name,
            transitions: transitions.map { LightStateTransition($0) },
            snapshotSensors: ["status", "light"],
            snapshotActuators: ["status", "light"]
        )
    }

    public override func onEntry() {
        light = true
    }

    public override func onExit() {
    }

    public override func main() {
    }

    public override final func clone() -> LightState_On {
        let transitions: [Transition<LightState_On, LightState>] = self.transitions.map { $0.cast(to: LightState_On.self) }
        let state = LightState_On(
            self.name,
            transitions: transitions,
            gateway: self.gateway,
            clock: self.clock
        )
        state.Me = self.Me
        return state
    }

}

extension LightState_On: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
