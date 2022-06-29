import swiftfsm

public final class CallbackAlarmState: AlarmState {

    private let _onEntry: () -> Void

    private let _onExit: () -> Void

    private let _main: () -> Void

    public init(
        _ name: String,
        transitions: [Transition<CallbackAlarmState, AlarmState>] = [],
        snapshotSensors: Set<String>?,
        snapshotActuators: Set<String>?,
        onEntry: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {},
        main: @escaping () -> Void = {}
    ) {
        self._onEntry = onEntry
        self._onExit = onExit
        self._main = main
        super.init(name, transitions: transitions.map { AlarmStateTransition($0) }, snapshotSensors: snapshotSensors, snapshotActuators: snapshotActuators)
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

    public override final func clone() -> CallbackAlarmState {
        let transitions: [Transition<CallbackAlarmState, AlarmState>] = self.transitions.map { $0.cast(to: CallbackAlarmState.self) }
        return CallbackAlarmState(self.name, transitions: transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
