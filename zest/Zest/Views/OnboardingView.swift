import SwiftUI

/// First-run tuning: a welcome card, then a swipeable list of ten varied sample
/// stories to learn from, then a simple "all set" screen.
struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel
    let isFirstRun: Bool
    let onFinish: () -> Void
    @State private var started = false

    private let goal = 10

    init(client: NewsAPIClient, isFirstRun: Bool, onFinish: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(client: client, store: InterestStore.shared))
        self.isFirstRun = isFirstRun
        self.onFinish = onFinish
    }

    private var progress: Double { Double(vm.swipedCount) / Double(goal) }

    var body: some View {
        Group {
            if vm.isComplete {
                CompletionView(onFinish: onFinish)
            } else if !started {
                WelcomeView { started = true }
            } else {
                tuningView
            }
        }
    }

    private var tuningView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text("Tap the buttons — or swipe each story — to tell Zesty what you like.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ProgressView(value: progress)
                Text("\(vm.swipedCount) of \(goal)").font(.caption).foregroundStyle(.secondary)
            }
            .padding()

            List {
                ForEach(vm.deck) { article in
                    sampleRow(article)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { vm.decide(article, liked: true) } label: {
                                Label("Interested", systemImage: "hand.thumbsup.fill")
                            }.tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button { vm.decide(article, liked: false) } label: {
                                Label("Not for me", systemImage: "hand.thumbsdown.fill")
                            }.tint(.red)
                        }
                }
            }
            .listStyle(.plain)
        }
    }

    private func sampleRow(_ article: Article) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SourceBadge(source: article.pillar ?? article.section.capitalized, category: article.section)
            Text(article.title).font(.headline)
            if let trail = article.trailText {
                Text(trail).font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Button { vm.decide(article, liked: false) } label: {
                    Label("Not for me", systemImage: "hand.thumbsdown")
                        .font(.subheadline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(.red)
                Button { vm.decide(article, liked: true) } label: {
                    Label("Interested", systemImage: "hand.thumbsup")
                        .font(.subheadline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.green)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Welcome

private struct WelcomeView: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56)).foregroundStyle(.tint)
            Text("Let’s find your news")
                .font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
            Text("We’ll show you a few sample stories. Mark the ones that interest you — that’s how Zesty learns what to put in your feed. It keeps learning from everything you read, too.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            Button(action: onStart) { Text("Start").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large).padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Completion

private struct CompletionView: View {
    let onFinish: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            Text("You’re all set").font(.largeTitle.weight(.bold))
            Text("Zesty has a good first idea of the news you’ll love — and it’ll keep refining as you read.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            Button(action: onFinish) { Text("Go to news feed").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large).padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Shared error state (also used by the feed)

struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Try again", action: retry).buttonStyle(.bordered)
        }
        .padding()
    }
}
