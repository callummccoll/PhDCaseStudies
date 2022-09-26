import swiftfsm

public struct SonarStateTransition: TransitionType {
    
    internal let base: Any

    private weak var unownedTarget: SonarState?

    private let ownedTarget: SonarState?
    
    public var target: SonarState {
        if let target = ownedTarget {
            return target
        } else {
            return unownedTarget!
        }
    }
    
    public let canTransition: (SonarState) -> Bool

    private init(base: Any, target: SonarState, isUnowned: Bool, canTransition: @escaping (SonarState) -> Bool) {
        self.base = base
        if isUnowned {
            self.unownedTarget = target
            self.ownedTarget = nil
        } else {
            self.unownedTarget = nil
            self.ownedTarget = target
        }
        self.canTransition = canTransition
    }
    
    public init<S: SonarState, Target: SonarState>(_ base: Transition<S, Target>) {
        self.init(base: base, target: base.target, isUnowned: false) {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }

    public init<S: SonarState, Target: SonarState>(_ base: UnownedTransition<S, Target>) {
        self.base = ()
        self.unownedTarget = base.target
        self.ownedTarget = nil
        self.canTransition = {
            guard let state = $0 as? S else {
                fatalError("Unable to cast source state in transition to \(S.self)")
            }
            return base.canTransition(state)
        }
    }
    
    public func cast<S: SonarState>(to type: S.Type) -> Transition<S, SonarState> {
        guard let transition = self.base as? Transition<S, SonarState> else {
            fatalError("Unable to cast bast to Transition<\(type), SonarState>")
        }
        return transition
    }

    public func unownedCast<S: SonarState>(to type: S.Type) -> UnownedTransition<S, SonarState> {
        guard let transition = self.base as? UnownedTransition<S, SonarState> else {
            fatalError("Unable to cast bast to UnownedTransition<\(type), SonarState>")
        }
        return transition
    }
    
    public func map(_ f: (SonarState) -> SonarState) -> SonarStateTransition {
        let isUnowned = unownedTarget != nil
        let newTarget: SonarState
        if isUnowned {
            newTarget = f(unownedTarget!)
        } else {
            newTarget = f(ownedTarget!)
        }
        return SonarStateTransition(base: base, target: newTarget, isUnowned: isUnowned, canTransition: self.canTransition)
    }
    
}
