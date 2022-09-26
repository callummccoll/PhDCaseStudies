import swiftfsm

public final class EmptyCallerState: CallerState {

    public init(_ name: String, transitions: [Transition<EmptyCallerState, CallerState>] = []) {
        super.init(name, transitions: transitions.map { CallerStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override final func onEntry() {}

    public override final func onExit() {}

    public override final func main() {}

    public override final func clone() -> EmptyCallerState {
        let transitions: [Transition<EmptyCallerState, CallerState>] = self.transitions.map { $0.cast(to: EmptyCallerState.self) }
        return EmptyCallerState(self.name, transitions: transitions)
    }

}
