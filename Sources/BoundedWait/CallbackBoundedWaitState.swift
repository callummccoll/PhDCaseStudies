import swiftfsm

public final class CallbackBoundedWaitState: BoundedWaitState {

    public override var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": [],
            "_onEntry": [],
            "_main": [],
            "_onExit": []
        ]
    }

    /**
     *  The actual onEntry implementation.
     */
    public let _onEntry: () -> Void

    /**
     *  The actual main implementation.
     */
    public let _main: () -> Void

    /**
     *  The actual onExit implementation.
     */
    public let _onExit: () -> Void

    private init(
        _ name: String,
        microwaveTransitions: [BoundedWaitTransition] = [],
        snapshotSensors: Set<String>? = nil,
        snapshotActuators: Set<String>? = nil,
        onEntry: @escaping () -> Void = {},
        main: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {}
    ) {
        self._onEntry = onEntry
        self._main = main
        self._onExit = onExit
        super.init(
            name,
            transitions: microwaveTransitions,
            snapshotSensors: snapshotSensors,
            snapshotActuators: snapshotActuators
        )
    }

    public init(
        _ name: String,
        snapshotSensors: Set<String>? = nil,
        snapshotActuators: Set<String>? = nil,
        onEntry: @escaping () -> Void = {},
        main: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {}
    ) {
        self._onEntry = onEntry
        self._main = main
        self._onExit = onExit
        super.init(
            name,
            transitions: [],
            snapshotSensors: snapshotSensors,
            snapshotActuators: snapshotActuators
        )
    }

    /**
     *  Create a new `CallbackBoundedWaitState`.
     */
    public init<Transition: TransitionType>(
        _ name: String,
        transitions: [Transition] = [],
        snapshotSensors: Set<String>? = nil,
        snapshotActuators: Set<String>? = nil,
        onEntry: @escaping () -> Void = {},
        main: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {}
    ) where Transition.Source == CallbackBoundedWaitState, Transition.Target: BoundedWaitState {
        self._onEntry = onEntry
        self._main = main
        self._onExit = onExit
        super.init(
            name,
            transitions: transitions.map(BoundedWaitTransition.init),
            snapshotSensors: snapshotSensors,
            snapshotActuators: snapshotActuators
        )
    }

    /**
     *  This method delegates to `_onEntry`.
     */
    public override final func onEntry() {
        self._onEntry()
    }

    /**
     *  This method delegates to `_main`.
     */
    public override final func main() {
        self._main()
    }

    /**
     *  This method delegates to `_onExit`.
     */
    public override final func onExit() {
        self._onExit()
    }

    /**
     *  Create a new `CallbackBoundedWaitState` that is an exact copy of `self`.
     */
    public override final func clone() -> CallbackBoundedWaitState {
        return CallbackBoundedWaitState(
            self.name,
            microwaveTransitions: self.transitions,
            snapshotSensors: self.snapshotSensors,
            snapshotActuators: self.snapshotActuators,
            onEntry: self._onEntry,
            main: self._main,
            onExit: self._onExit
        )
    }

}
