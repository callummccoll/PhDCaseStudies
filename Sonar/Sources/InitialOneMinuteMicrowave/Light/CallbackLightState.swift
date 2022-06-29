import swiftfsm

public final class CallbackLightState: LightState {

    private let _LightEntry: () -> Void

    private let _LightExit: () -> Void

    private let _main: () -> Void

    public init(
        _ name: String,
        transitions: [Transition<CallbackLightState, LightState>] = [],
        snapshotSensors: Set<String>?,
        snapshotActuators: Set<String>?,
        onEntry: @escaping () -> Void = {},
        onExit: @escaping () -> Void = {},
        main: @escaping () -> Void = {}
    ) {
        self._LightEntry = onEntry
        self._LightExit = onExit
        self._main = main
        super.init(name, transitions: transitions.map { LightStateTransition($0) }, snapshotSensors: snapshotSensors, snapshotActuators: snapshotActuators)
    }

    public final override func onEntry() {
        self._LightEntry()
    }

    public final override func onExit() {
        self._LightExit()
    }

    public final override func main() {
        self._main()
    }

    public override final func clone() -> CallbackLightState {
        let transitions: [Transition<CallbackLightState, LightState>] = self.transitions.map { $0.cast(to: CallbackLightState.self) }
        return CallbackLightState(self.name, transitions: transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
