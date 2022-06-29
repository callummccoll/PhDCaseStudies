import swiftfsm
import SwiftfsmWBWrappers

public final class CookingState_Not_Cooking: CookingState {

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

    public internal(set) var fsmVars: CookingVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public init(
        _ name: String,
        transitions: [Transition<CookingState_Not_Cooking, CookingState>] = [],
        gateway: FSMGateway,
        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(name, transitions: transitions.map { CookingStateTransition($0) }, snapshotSensors: ["status", "motor"], snapshotActuators: ["status", "motor"])
    }

    public override func onEntry() {
        motor = false
    }

    public override func onExit() {
        
    }

    public override func main() {
        
    }

    public override final func clone() -> CookingState_Not_Cooking {
        let transitions: [Transition<CookingState_Not_Cooking, CookingState>] = self.transitions.map { $0.cast(to: CookingState_Not_Cooking.self) }
        let state = CookingState_Not_Cooking(
            self.name,
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock
        )
        state.Me = self.Me
        return state
    }

}

extension CookingState_Not_Cooking: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
