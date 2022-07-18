import swiftfsm

struct UnownedTransition<Source, Target: AnyObject>: TransitionType {

    let canTransition: (Source) -> Bool

    unowned let target: Target

    init(_ target: Target, canTransition: @escaping (Source) -> Bool) {
        self.canTransition = canTransition
        self.target = target
    }

}
