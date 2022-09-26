import swiftfsm

public final class CallbackCallerState: CallerState {

    private let _onEntry: () -> Void

    private let _onExit: () -> Void

    private let _main: () -> Void

    public init(
        _ name: String,
        transitions: [Transition<CallbackCallerState, CallerState>] = [],
        snapshotSensors: Set<String>?,
        snapshotActuators: Set<String>?,
        onEntry: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {},
        main: @escaping () -> Void = {}
    ) {
        self._onEntry = onEntry
        self._onExit = onExit
        self._main = main
        super.init(name, transitions: transitions.map { CallerStateTransition($0) }, snapshotSensors: snapshotSensors, snapshotActuators: snapshotActuators)
    }

    public final override func onEntry() {
        self._onEntry()
    }

    public final override func onExit() {
        self._onExit()
    }

    public final override func main() {
        self._main()
    }

    public override final func clone() -> CallbackCallerState {
        let transitions: [Transition<CallbackCallerState, CallerState>] = self.transitions.map { $0.cast(to: CallbackCallerState.self) }
        return CallbackCallerState(self.name, transitions: transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
