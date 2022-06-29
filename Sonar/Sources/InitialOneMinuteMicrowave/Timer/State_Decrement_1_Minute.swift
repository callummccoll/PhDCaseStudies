import swiftfsm
import SwiftfsmWBWrappers

public final class State_Decrement_1_Minute: TimerState {

    public override var validVars: [String: [Any]] {
        return [
            "name": [],
            "transitions": [],
            "gateway": [],
            "clock": [],
            "snapshotSensors": [],
            "snapshotActuators": [],
            "Me": []
        ]
    }

    fileprivate let gateway: FSMGateway

    public let clock: Timer

    public internal(set) var fsmVars: TimerVars {
        get {
            return Me.fsmVars.vars
        }
        set {
            Me.fsmVars.vars = newValue
        }
    }

    public internal(set) var currentTime: UInt8 {
        get {
            return fsmVars.currentTime
        }
        set {
            fsmVars.currentTime = newValue
        }
    }

    public init(
        _ name: String,
        transitions: [Transition<State_Decrement_1_Minute, TimerState>] = [],
        gateway: FSMGateway,
        clock: Timer
    ) {
        self.gateway = gateway
        self.clock = clock
        super.init(name, transitions: transitions.map { TimerStateTransition($0) }, snapshotSensors: ["status"], snapshotActuators: ["status"])
    }

    public override func onEntry() {
    }

    public override func onExit() {
        currentTime -= 1
    }

    public override func main() {

    }

    public override final func clone() -> State_Decrement_1_Minute {
        let transitions: [Transition<State_Decrement_1_Minute, TimerState>] = self.transitions.map { $0.cast(to: State_Decrement_1_Minute.self) }
        let state = State_Decrement_1_Minute(
            self.name,
            transitions: transitions,
            gateway: self.gateway
,            clock: self.clock
        )
        state.Me = self.Me
        return state
    }

}

extension State_Decrement_1_Minute: CustomStringConvertible {

    public var description: String {
        return """
            {
                name: \(self.name),
                transitions: \(self.transitions.map { $0.target.name })
            }
            """
    }

}
