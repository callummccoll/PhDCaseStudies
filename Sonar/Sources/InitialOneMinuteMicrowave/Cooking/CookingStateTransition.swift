import swiftfsm

public struct CookingStateTransition: TransitionType {
    
    internal let base: Any
    
    public let target: CookingState
    
    public let canTransition: (CookingState) -> Bool
    
    public init<S: CookingState>(_ base: Transition<S, CookingState>) {
        self.base = base
        self.target = base.target
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    internal init(base: Any, target: CookingState, canTransition: @escaping (CookingState) -> Bool) {
        self.base = base
        self.target = target
        self.canTransition = canTransition
    }
    
    public func cast<S: CookingState>(to type: S.Type) -> Transition<S, CookingState> {
        guard let transition = self.base as? Transition<S, CookingState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (CookingState) -> CookingState) -> CookingStateTransition {
        return CookingStateTransition(base: base, target: f(self.target), canTransition: self.canTransition)
    }
    
}
