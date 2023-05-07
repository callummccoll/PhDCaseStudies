import swiftfsm

/**
 *  The base class for all states that conform to `MiPalAction`s.
 */
//swiftlint:disable:next colon
open class BoundedWaitState:
    StateType,
    CloneableState,
    MiPalActions,
    Transitionable,
    KripkeVariablesModifier,
    SnapshotListContainer
{

    /**
     *  The name of the state.
     *
     *  - Requires: Must be unique for each state.
     */
    public let name: String

    /**
     *  An array of transitions that this state may use to move to another
     *  state.
     */
    public var transitions: [BoundedWaitTransition]

    public var snapshotSensors: Set<String>?

    public var snapshotActuators: Set<String>?

    open var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": []
        ]
    }

    /**
     *  Create a new `BoundedWaitState`.
     *
     *  - Parameter name: The name of the state.
     *
     *  - transitions: All transitions to other states that this state can use.
     */
    public init(_ name: String, transitions: [BoundedWaitTransition] = [], snapshotSensors: Set<String>? = nil, snapshotActuators: Set<String>? = nil) {
        self.name = name
        self.transitions = transitions
        self.snapshotSensors = snapshotSensors
        self.snapshotActuators = snapshotActuators
    }

    /**
     *  Does nothing.
     */
    open func onEntry() {}

    /**
     *  Does nothing.
     */
    open func main() {}

    /**
     *  Does nothing.
     */
    open func onExit() {}

    /**
     *  Create a copy of `self`.
     *
     *  - Warning: Child classes should override this method.  If they do not
     *  then the application will crash when trying to generate
     *  `KripkeStructures`.
     */
    open func clone() -> Self {
        fatalError("Please implement your own clone")
    }

}
