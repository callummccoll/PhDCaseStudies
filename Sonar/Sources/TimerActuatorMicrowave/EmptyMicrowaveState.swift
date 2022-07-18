import swiftfsm

public final class EmptyMicrowaveState: MicrowaveState {

    /**
     *  Does nothing.
     */
    public override final func onEntry() {}

    /**
     *  Does nothing.
     */
    public override final func main() {}

    /**
     *  Does nothing.
     */
    public override final func onExit() {}

    public override final func clone() -> EmptyMicrowaveState {
        return EmptyMicrowaveState(self.name, transitions: self.transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
