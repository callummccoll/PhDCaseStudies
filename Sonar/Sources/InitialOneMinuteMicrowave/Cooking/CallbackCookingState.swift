import swiftfsm

public final class CallbackCookingState: CookingState {

    private let _CookingEntry: () -> Void

    private let _CookingExit: () -> Void

    private let _main: () -> Void

    public init(
        _ name: String,
        transitions: [Transition<CallbackCookingState, CookingState>] = [],
        snapshotSensors: Set<String>?,
        snapshotActuators: Set<String>?,
        onEntry: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {},
        main: @escaping () -> Void = {}
    ) {
        self._CookingEntry = onEntry
        self._CookingExit = onExit
        self._main = main
        super.init(name, transitions: transitions.map { CookingStateTransition($0) }, snapshotSensors: snapshotSensors, snapshotActuators: snapshotActuators)
    }

    public final override func onEntry() {
        self._CookingEntry()
    }

    public final override func onExit() {
        self._CookingExit()
    }

    public final override func main() {
        self._main()
    }

    public override final func clone() -> CallbackCookingState {
        let transitions: [Transition<CallbackCookingState, CookingState>] = self.transitions.map { $0.cast(to: CallbackCookingState.self) }
        return CallbackCookingState(self.name, transitions: transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
