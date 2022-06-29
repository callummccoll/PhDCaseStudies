import swiftfsm

public final class EmptyLightState: LightState {

    public init(_ name: String, transitions: [Transition<EmptyLightState, LightState>] = []) {
        super.init(name, transitions: transitions.map { LightStateTransition($0) }, snapshotSensors: [], snapshotActuators: [])
    }

    public override final func onEntry() {}

    public override final func onExit() {}

    public override final func main() {}

    public override final func clone() -> EmptyLightState {
        let transitions: [Transition<EmptyLightState, LightState>] = self.transitions.map { $0.cast(to: EmptyLightState.self) }
        return EmptyLightState(self.name, transitions: transitions)
    }

}
