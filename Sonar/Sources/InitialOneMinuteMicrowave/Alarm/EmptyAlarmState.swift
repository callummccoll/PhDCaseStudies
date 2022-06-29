import swiftfsm

public final class EmptyAlarmState: AlarmState {

    public init(_ name: String, transitions: [Transition<EmptyAlarmState, AlarmState>] = []) {
        super.init(name, transitions: transitions.map { AlarmStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override final func onEntry() {}

    public override final func onExit() {}

    public override final func main() {}

    public override final func clone() -> EmptyAlarmState {
        let transitions: [Transition<EmptyAlarmState, AlarmState>] = self.transitions.map { $0.cast(to: EmptyAlarmState.self) }
        return EmptyAlarmState(self.name, transitions: transitions)
    }

}
