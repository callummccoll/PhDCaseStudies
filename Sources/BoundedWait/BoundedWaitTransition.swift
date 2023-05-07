import swiftfsm

public struct BoundedWaitTransition: TransitionType {

    public let canTransition: (BoundedWaitState) -> Bool

    let _target: () -> BoundedWaitState

    public var target: BoundedWaitState {
        _target()
    }

    public init<Base: TransitionType>(_ base: Base) where Base.Source: BoundedWaitState, Base.Target: BoundedWaitState {
        self.canTransition = { base.canTransition($0 as! Base.Source) }
        self._target = { base.target as BoundedWaitState }
    }

}
