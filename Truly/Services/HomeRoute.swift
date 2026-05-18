import Foundation

enum HomeRoute: Hashable {
    case timer(ActionItem)
    case done(Int, Bool) // minutes, isMilestone
    case between(Int, Int) // lastMin, totalMin
}
