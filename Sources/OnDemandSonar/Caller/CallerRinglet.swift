import swiftfsm

/**
 *  A standard ringlet.
 *
 *  Firstly calls onEntry if we have just transitioned to this state.  If a
 *  transition is possible then the states onExit method is called and the new
 *  state is returned.  If no transitions are possible then the main method is
 *  called and the state is returned.
 */
public final class CallerRinglet: Ringlet, Cloneable, KripkeVariablesModifier {

    var previousState: CallerState

    var shouldExecuteOnEntry: Bool = true

    public var computedVars: [String: Any] {
        return [:]
    }

    public var manipulators: [String: (Any) -> Any] {
        return [:]
    }

    public var validVars: [String: [Any]] {
        return [
            "previousState": []
        ]
    }

    /**
     *  Create a new `CallerRinglet`.
     *
     *  - Parameter previousState:  The last `CallerState` that was executed.
     *  This is used to check whether the `CallerState.onEntry()` should run.
     */
    public init(previousState: CallerState = EmptyCallerState("previous")) {
        self.previousState = previousState
    }

    /**
     *  Execute the ringlet.
     *
     *  - Parameter state: The `CallerState` that is being executed.
     *
     *  - Returns: A state representing the next state to execute.
     */
    public func execute(state: CallerState) -> CallerState {
        // Call onEntry if we have just transitioned to this state.
        if state != self.previousState {
            state.onEntry()
        }
        self.previousState = state
        // Can we transition to another state?
        if let t = state.transitions.lazy.filter({ $0.canTransition(state) }).first {
            // Yes - Exit state and return the new state.
            state.onExit()
            self.shouldExecuteOnEntry = self.previousState != t.target
            return t.target
        }
        // No - Execute main method and return state.
        state.main()
        self.shouldExecuteOnEntry = false
        return state
    }

    public func clone() -> CallerRinglet {
        let r = CallerRinglet(previousState: self.previousState.clone())
        r.shouldExecuteOnEntry = self.shouldExecuteOnEntry
        return r
    }

}
