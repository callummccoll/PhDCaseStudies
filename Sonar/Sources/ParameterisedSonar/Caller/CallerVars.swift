import swiftfsm
import SwiftfsmWBWrappers

public final class CallerVars: Variables {

    var distance: UInt16?

    public init(distance: UInt16? = nil) {
        self.distance = distance
    }

    public final func clone() -> CallerVars {
        return CallerVars(distance: self.distance)
    }

}
