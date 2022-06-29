import swiftfsm
import SwiftfsmWBWrappers

internal final class TimerFiniteStateMachine: MachineProtocol {

    public typealias _StateType = TimerState

    fileprivate var allStates: [String: TimerState] {
        var stateCache: [String: TimerState] = [:]
        func fetchAllStates(fromState state: TimerState) {
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
            return [external_status].map(AnySnapshotController.init)
        } set {
            for external in newValue {
                switch external.name {
                case self.external_status.name:
                    self.external_status.val = external.val as! WhiteboardVariable<MicrowaveStatus>.Class
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
        guard let snapshotSensors = self.currentState.snapshotSensors else {
            return []
        }
        return snapshotSensors.map { (label: String) -> AnySnapshotController in
            switch label {
            case "status":
                return AnySnapshotController(self.external_status)
            default:
                fatalError("Unable to find sensor \(label).")
            }
        }
    }

    public var snapshotActuators: [AnySnapshotController] {
        guard let snapshotActuators = self.currentState.snapshotActuators else {
            return []
        }
        return snapshotActuators.map { (label: String) -> AnySnapshotController in
            switch label {
            case "status":
                return AnySnapshotController(self.external_status)
            default:
                fatalError("Unable to find actuator \(label).")
            }
        }
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
            "external_status": []
        ]
    }

    /**
     *  The state that is currently executing.
     */
    public var currentState: TimerState

    /**
     *  The state that is used to exit the FSM.
     */
    public private(set) var exitState: TimerState

    /**
     * All FSM variables used by the machine.
     */
    public let fsmVars: SimpleVariablesContainer<TimerVars>

    /**
     *  The initial state of the previous state.
     *
     *  `previousState` is set to this value on restart.
     */
    public private(set) var initialPreviousState: TimerState

    /**
     *  The starting state of the FSM.
     */
    public private(set) var initialState: TimerState

    /**
     *  The name of the FSM.
     *
     *  - Warning: This must be unique between FSMs.
     */
    public let name: String

    /**
     *  The last state that was executed.
     */
    public var previousState: TimerState

    /**
     *  An instance of `Ringlet` that is used to execute the states.
     */
    public fileprivate(set) var ringlet: TimerRinglet

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
    public var suspendedState: TimerState?

    /**
     *  The state that is set to `currentState` when the FSM is suspended.
     */
    public private(set) var suspendState: TimerState

    public var external_status: WhiteboardVariable<MicrowaveStatus>

    internal init(
        name: String,
        initialState: TimerState,
        external_status: WhiteboardVariable<MicrowaveStatus>,
        fsmVars: SimpleVariablesContainer<TimerVars>,
        ringlet: TimerRinglet,
        initialPreviousState: TimerState,
        suspendedState: TimerState?,
        suspendState: TimerState,
        exitState: TimerState,
        submachines: [() -> AnyControllableFiniteStateMachine]
    ) {
        self.currentState = initialState
        self.exitState = exitState
        self.external_status = external_status
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

    public func clone() -> TimerFiniteStateMachine {
        var stateCache: [String: TimerState] = [:]
        let allStates = self.allStates
        self.fsmVars.vars = self.fsmVars.vars.clone()
        var fsm = TimerFiniteStateMachine(
            name: self.name,
            initialState: self.initialState.clone(),
            external_status: self.external_status.clone(),
            fsmVars: SimpleVariablesContainer(vars: self.fsmVars.vars.clone()),
            ringlet: self.ringlet.clone(),
            initialPreviousState: self.initialPreviousState.clone(),
            suspendedState: self.suspendedState.map { $0.clone() },
            suspendState: self.suspendState.clone(),
            exitState: self.exitState.clone(),
            submachines: self.submachineFunctions
        )
        func apply(_ state: TimerState) -> TimerState {
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

extension TimerFiniteStateMachine: CustomStringConvertible {

    var description: String {
        return """
            {
                name: \(self.name),
                external_status: \(self.external_status),
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
