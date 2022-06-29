import swiftfsm

public struct AlarmStateTransition: TransitionType {
    
    internal let base: Any
    
    public let target: AlarmState
    
    public let canTransition: (AlarmState) -> Bool
    
    public init<S: AlarmState>(_ base: Transition<S, AlarmState>) {
        self.base = base
        self.target = base.target
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    internal init(base: Any, target: AlarmState, canTransition: @escaping (AlarmState) -> Bool) {
        self.base = base
        self.target = target
        self.canTransition = canTransition
    }
    
    public func cast<S: AlarmState>(to type: S.Type) -> Transition<S, AlarmState> {
        guard let transition = self.base as? Transition<S, AlarmState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (AlarmState) -> AlarmState) -> AlarmStateTransition {
        return AlarmStateTransition(base: base, target: f(self.target), canTransition: self.canTransition)
    }
    
}
