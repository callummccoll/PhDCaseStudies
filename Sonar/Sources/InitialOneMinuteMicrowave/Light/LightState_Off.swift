import swiftfsm
import SwiftfsmWBWrappers

public final class LightState_Off: LightState {

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
        transitions: [Transition<LightState_Off, LightState>] = [],
        gateway: FSMGateway,
        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(name, transitions: transitions.map { LightStateTransition($0) }, snapshotSensors: ["status", "light"], snapshotActuators: ["status", "light"])
    }

    public override func onEntry() {
        light = false
    }

    public override func onExit() {
        
    }

    public override func main() {
        
    }

    public override final func clone() -> LightState_Off {
        let transitions: [Transition<LightState_Off, LightState>] = self.transitions.map { $0.cast(to: LightState_Off.self) }
        let state = LightState_Off(
            self.name,
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock
        )
        state.Me = self.Me
        return state
    }

}

extension LightState_Off: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
