import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published private(set) var deck: [Article] = Article.onboardingSamples
    @Published var swipedCount = 0

    private let store: InterestStore

    /// `client` kept for signature compatibility; onboarding now uses a fixed
    /// set of varied sample stories instead of fetching real ones.
    init(client: NewsAPIClient, store: InterestStore) {
        self.store = store
    }

    var isComplete: Bool { deck.isEmpty }

    func decide(_ article: Article, liked: Bool) {
        store.record(liked ? .onboardingLike : .onboardingDislike, for: article)
        swipedCount += 1
        deck.removeAll { $0.id == article.id }
    }
}
