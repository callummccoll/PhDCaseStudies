import swiftfsm

public struct TimerStateTransition: TransitionType {
    
    internal let base: Any
    
    public let target: TimerState
    
    public let canTransition: (TimerState) -> Bool
    
    public init<S: TimerState>(_ base: Transition<S, TimerState>) {
        self.base = base
        self.target = base.target
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    internal init(base: Any, target: TimerState, canTransition: @escaping (TimerState) -> Bool) {
        self.base = base
        self.target = target
        self.canTransition = canTransition
    }
    
    public func cast<S: TimerState>(to type: S.Type) -> Transition<S, TimerState> {
        guard let transition = self.base as? Transition<S, TimerState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (TimerState) -> TimerState) -> TimerStateTransition {
        return TimerStateTransition(base: base, target: f(self.target), canTransition: self.canTransition)
    }
    
}
