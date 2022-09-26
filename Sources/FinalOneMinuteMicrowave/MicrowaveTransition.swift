import swiftfsm

public struct MicrowaveTransition: TransitionType {

    public let canTransition: (MicrowaveState) -> Bool

    let _target: () -> MicrowaveState

    public var target: MicrowaveState {
        _target()
    }

    public init<Base: TransitionType>(_ base: Base) where Base.Source: MicrowaveState, Base.Target: MicrowaveState {
        self.canTransition = { base.canTransition($0 as! Base.Source) }
        self._target = { base.target as MicrowaveState }
    }

}
