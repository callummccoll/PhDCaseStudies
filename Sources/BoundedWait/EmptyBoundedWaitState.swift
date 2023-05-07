import swiftfsm

public final class EmptyBoundedWaitState: BoundedWaitState {

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

    public override final func clone() -> EmptyBoundedWaitState {
        return EmptyBoundedWaitState(self.name, transitions: self.transitions, snapshotSensors: self.snapshotSensors, snapshotActuators: self.snapshotActuators)
    }

}
