import swiftfsm

public final class EmptyTimerState: TimerState {

    public init(_ name: String, transitions: [Transition<EmptyTimerState, TimerState>] = []) {
        super.init(name, transitions: transitions.map { TimerStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override final func onEntry() {}

    public override final func onExit() {}

    public override final func main() {}

    public override final func clone() -> EmptyTimerState {
        let transitions: [Transition<EmptyTimerState, TimerState>] = self.transitions.map { $0.cast(to: EmptyTimerState.self) }
        return EmptyTimerState(self.name, transitions: transitions)
    }

}
