import Foundation

/// Every way the user can signal interest, with the point delta each one
/// applies to a tag's score. Tune these to make the feed more/less reactive.
enum InteractionEvent {
    case onboardingLike      // swiped right in the tuning deck
    case onboardingDislike   // swiped left in the tuning deck
    case openArticle         // tapped a story open — a weak, gameable signal
    case readToEnd           // read ~70%+ of it — the real positive signal
    case hideArticle         // explicitly "show me less like this"

    /// Points added to each of an article's tags. Negative = suppress.
    /// We optimise for *completion*, not clicks: opening alone scores nothing;
    /// actually reading the story is what counts.
    var delta: Double {
        switch self {
        case .openArticle:       return 0    // a click is not a real signal
        case .readToEnd:         return 10   // read ~70%+ → strong positive
        case .onboardingLike:    return 6
        case .onboardingDislike: return -4
        case .hideArticle:       return -12
        }
    }
}
