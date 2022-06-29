import swiftfsm

public struct LightStateTransition: TransitionType {
    
    internal let base: Any
    
    public let target: LightState
    
    public let canTransition: (LightState) -> Bool
    
    public init<S: LightState>(_ base: Transition<S, LightState>) {
        self.base = base
        self.target = base.target
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    internal init(base: Any, target: LightState, canTransition: @escaping (LightState) -> Bool) {
        self.base = base
        self.target = target
        self.canTransition = canTransition
    }
    
    public func cast<S: LightState>(to type: S.Type) -> Transition<S, LightState> {
        guard let transition = self.base as? Transition<S, LightState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (LightState) -> LightState) -> LightStateTransition {
        return LightStateTransition(base: base, target: f(self.target), canTransition: self.canTransition)
    }
    
}
