import swiftfsm

public struct UnownedTransition<Source, Target: AnyObject>: TransitionType {

    public let canTransition: (Source) -> Bool

    public unowned let target: Target

    public init(_ target: Target, canTransition: @escaping (Source) -> Bool) {
        self.canTransition = canTransition
        self.target = target
    }

}
