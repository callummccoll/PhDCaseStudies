import swiftfsm
import SwiftfsmWBWrappers

public final class TimerVars: Variables {

    public var currentTime: UInt8

    public init(currentTime: UInt8 = 0) {
        self.currentTime = currentTime
    }

    public final func clone() -> TimerVars {
        return TimerVars(currentTime: currentTime)
    }

}
