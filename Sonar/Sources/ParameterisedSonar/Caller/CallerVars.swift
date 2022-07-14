import swiftfsm
import SwiftfsmWBWrappers

public final class CallerVars: Variables {

    var distance23: UInt16?

    var distance45: UInt16?

    public init(distance23: UInt16? = nil, distance45: UInt16? = nil) {
        self.distance23 = distance23
        self.distance45 = distance45
    }

    public final func clone() -> CallerVars {
        return CallerVars(distance23: self.distance23, distance45: distance45)
    }

}
