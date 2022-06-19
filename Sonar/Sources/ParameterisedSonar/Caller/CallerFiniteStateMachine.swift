import swiftfsm
import SwiftfsmWBWrappers

public final class CallerFiniteStateMachine: MachineProtocol {

    public typealias _StateType = CallerState

    fileprivate var allStates: [String: CallerState] {
        var stateCache: [String: CallerState] = [:]
        func fetchAllStates(fromState state: CallerState) {
            if stateCache[state.name] != nil {
                return
            }
            stateCache[state.name] = state
            state.transitions.forEach {
                fetchAllStates(fromState: $0.target)
            }
        }
        fetchAllStates(fromState: self.initialState)
        fetchAllStates(fromState: self.suspendState)
        fetchAllStates(fromState: self.exitState)
        return stateCache
    }

    public var computedVars: [String: Any] {
        return [
            "sensors": Dictionary<String, Any>(uniqueKeysWithValues: self.sensors.map {
                ($0.name, $0.val)
            }),
            "actuators": Dictionary<String, Any>(uniqueKeysWithValues: self.actuators.map {
                ($0.name, $0.val)
            }),
            "externalVariables": Dictionary<String, Any>(uniqueKeysWithValues: self.externalVariables.map {
                ($0.name, $0.val)
            }),
            "currentState": self.currentState.name,
            "fsmVars": self.fsmVars.vars,
            "states": self.allStates,
        ]
    }

    /**
     * All external variables used by the machine.
     */
    public var externalVariables: [AnySnapshotController] {
        get {
            return []
        } set {
            for external in newValue {
                switch external.name {
                default:
                    continue
                }
            }
        }
    }

    public var sensors: [AnySnapshotController] {
        get {
            return []
        } set {
        }
    }

    public var actuators: [AnySnapshotController] {
        get {
            return []
        } set {
        }
    }

    public var snapshotSensors: [AnySnapshotController] {
        []
    }

    public var snapshotActuators: [AnySnapshotController] {
        []
    }

    public var validVars: [String: [Any]] {
        return [
            "currentState": [],
            "exitState": [],
            "externalVariables": [],
            "sensors": [],
            "actuators": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "fsmVars": [],
            "initialPreviousState": [],
            "initialState": [],
            "name": [],
            "previousState": [],
            "submachineFunctions": [],
            "submachines": [],
            "suspendedState": [],
            "suspendState": [],
            "external_echoPin": [],
            "external_triggerPin": [],
            "external_echoPinValue": [],
        ]
    }

    /**
     *  The state that is currently executing.
     */
    public var currentState: CallerState

    /**
     *  The state that is used to exit the FSM.
     */
    public private(set) var exitState: CallerState

    /**
     * All FSM variables used by the machine.
     */
    public let fsmVars: SimpleVariablesContainer<CallerVars>

    /**
     *  The initial state of the previous state.
     *
     *  `previousState` is set to this value on restart.
     */
    public private(set) var initialPreviousState: CallerState

    /**
     *  The starting state of the FSM.
     */
    public private(set) var initialState: CallerState

    /**
     *  The name of the FSM.
     *
     *  - Warning: This must be unique between FSMs.
     */
    public let name: String

    /**
     *  The last state that was executed.
     */
    public var previousState: CallerState

    /**
     *  An instance of `Ringlet` that is used to execute the states.
     */
    public fileprivate(set) var ringlet: CallerRinglet

    fileprivate let submachineFunctions: [() -> AnyControllableFiniteStateMachine]

    /**
     * All submachines of this machine.
     */
    public var submachines: [AnyControllableFiniteStateMachine] {
        get {
            return self.submachineFunctions.map { $0() }
        } set {}    }

    /**
     *  The state that was the `currentState` before the FSM was suspended.
     */
    public var suspendedState: CallerState?

    /**
     *  The state that is set to `currentState` when the FSM is suspended.
     */
    public private(set) var suspendState: CallerState

    internal init(
        name: String,
        initialState: CallerState,
        fsmVars: SimpleVariablesContainer<CallerVars>,
        ringlet: CallerRinglet,
        initialPreviousState: CallerState,
        suspendedState: CallerState?,
        suspendState: CallerState,
        exitState: CallerState,
        submachines: [() -> AnyControllableFiniteStateMachine]
    ) {
        self.currentState = initialState
        self.exitState = exitState
        self.fsmVars = fsmVars
        self.initialState = initialState
        self.initialPreviousState = initialPreviousState
        self.name = name
        self.previousState = initialPreviousState
        self.ringlet = ringlet
        self.submachineFunctions = submachines
        self.suspendedState = suspendedState
        self.suspendState = suspendState
        self.allStates.forEach { $1.Me = self }
        self.ringlet.Me = self
    }

    public func clone() -> CallerFiniteStateMachine {
        var stateCache: [String: CallerState] = [:]
        let allStates = self.allStates
        self.fsmVars.vars = self.fsmVars.vars.clone()
        var fsm = CallerFiniteStateMachine(
            name: self.name,
            initialState: self.initialState.clone(),
            fsmVars: SimpleVariablesContainer(vars: self.fsmVars.vars.clone()),
            ringlet: self.ringlet.clone(),
            initialPreviousState: self.initialPreviousState.clone(),
            suspendedState: self.suspendedState.map { $0.clone() },
            suspendState: self.suspendState.clone(),
            exitState: self.exitState.clone(),
            submachines: self.submachineFunctions
        )
        func apply(_ state: CallerState) -> CallerState {
            if let s = stateCache[state.name] {
                return s
            }
            var state = state
            state.Me = fsm
            stateCache[state.name] = state
            state.transitions = state.transitions.map {
                if $0.target == state {
                    return $0
                }
                guard let target = allStates[$0.target.name] else {
                    return $0
                }
                return $0.map { _ in apply(target.clone()) }
            }
            return state
        }
        fsm.initialState = apply(fsm.initialState)
        fsm.initialPreviousState = apply(fsm.initialPreviousState)
        fsm.suspendedState = fsm.suspendedState.map { apply($0) }
        fsm.suspendState = apply(fsm.suspendState)
        fsm.exitState = apply(fsm.exitState)
        fsm.currentState = apply(self.currentState.clone())
        fsm.previousState = apply(self.previousState.clone())
        return fsm
    }

}

extension CallerFiniteStateMachine: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                fsmVars: \(self.fsmVars.vars),
                initialState: \(self.initialState.name),
                currentState: \(self.currentState.name),
                previousState: \(self.previousState.name),
                suspendState: \(self.suspendState.name),
                suspendedState: \(self.suspendedState.map { $0.name }),
                exitState: \(self.exitState.name),
                states: \(self.allStates)
            }
            """
    }

}
