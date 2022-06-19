import swiftfsm

public struct CallerStateTransition: TransitionType {
    
    internal let base: Any
    
    public let target: CallerState
    
    public let canTransition: (CallerState) -> Bool
    
    public init<S: CallerState>(_ base: Transition<S, CallerState>) {
        self.base = base
        self.target = base.target
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    internal init(base: Any, target: CallerState, canTransition: @escaping (CallerState) -> Bool) {
        self.base = base
        self.target = target
        self.canTransition = canTransition
    }
    
    public func cast<S: CallerState>(to type: S.Type) -> Transition<S, CallerState> {
        guard let transition = self.base as? Transition<S, CallerState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (CallerState) -> CallerState) -> CallerStateTransition {
        return CallerStateTransition(base: base, target: f(self.target), canTransition: self.canTransition)
    }
    
}
