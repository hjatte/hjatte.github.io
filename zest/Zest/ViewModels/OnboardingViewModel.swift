import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum LoadState: Equatable {
        case loading, ready, finished
        case failed(String)
    }

    @Published private(set) var deck: [Article] = []
    @Published private(set) var state: LoadState = .loading
    @Published var swipedCount = 0

    private let client: NewsAPIClient
    private let store: InterestStore

    init(client: NewsAPIClient, store: InterestStore) {
        self.client = client
        self.store = store
    }

    /// The card currently on top of the stack.
    var topCard: Article? { deck.last }

    func load() async {
        state = .loading
        do {
            deck = try await client.fetchTuningDeck()
            state = deck.isEmpty ? .finished : .ready
        } catch {
            state = .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }

    func swipe(_ article: Article, liked: Bool) {
        store.record(liked ? .onboardingLike : .onboardingDislike, for: article)
        swipedCount += 1
        if let idx = deck.firstIndex(of: article) { deck.remove(at: idx) }
        if deck.isEmpty { state = .finished }
    }
}
