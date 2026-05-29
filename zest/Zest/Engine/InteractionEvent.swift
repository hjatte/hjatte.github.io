import Foundation

/// Every way the user can signal interest, with the point delta each one
/// applies to a tag's score. Tune these to make the feed more/less reactive.
enum InteractionEvent {
    case onboardingLike      // swiped right in the tuning deck
    case onboardingDislike   // swiped left in the tuning deck
    case openArticle         // tapped a story open (the strongest signal)
    case readToEnd           // scrolled/stayed long enough to "read" it
    case hideArticle         // explicitly "show me less like this"

    /// Points added to each of an article's tags. Negative = suppress.
    var delta: Double {
        switch self {
        case .openArticle:       return 10   // your example: click → +10
        case .readToEnd:         return 4
        case .onboardingLike:    return 6
        case .onboardingDislike: return -4
        case .hideArticle:       return -12
        }
    }
}
