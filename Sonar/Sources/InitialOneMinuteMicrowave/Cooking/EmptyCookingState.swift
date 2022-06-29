import swiftfsm

public final class EmptyCookingState: CookingState {

    public init(_ name: String, transitions: [Transition<EmptyCookingState, CookingState>] = []) {
        super.init(name, transitions: transitions.map { CookingStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override final func onEntry() {}

    public override final func onExit() {}

    public override final func main() {}

    public override final func clone() -> EmptyCookingState {
        let transitions: [Transition<EmptyCookingState, CookingState>] = self.transitions.map { $0.cast(to: EmptyCookingState.self) }
        return EmptyCookingState(self.name, transitions: transitions)
    }

}
