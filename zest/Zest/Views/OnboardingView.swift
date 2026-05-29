import SwiftUI

/// The Tinder-style tuning deck. Swipe right = "more like this", left = "less".
/// Used both as first-run onboarding and as the re-enterable "Tune" tab.
struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel
    let isFirstRun: Bool
    let onFinish: () -> Void

    init(client: NewsAPIClient, isFirstRun: Bool, onFinish: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(client: client, store: InterestStore.shared))
        self.isFirstRun = isFirstRun
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header

                switch vm.state {
                case .loading:
                    Spacer(); ProgressView("Gathering stories…"); Spacer()

                case .failed(let message):
                    Spacer(); ErrorState(message: message) { Task { await vm.load() } }; Spacer()

                case .finished:
                    Spacer(); FinishedState(count: vm.swipedCount, isFirstRun: isFirstRun, onDone: onFinish); Spacer()

                case .ready:
                    deck
                    controls
                }
            }
            .padding()
            .navigationTitle(isFirstRun ? "Find your feed" : "Refine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // First-run: let people finish whenever they've swiped enough,
                // rather than having to clear the whole deck.
                if isFirstRun, vm.state == .ready {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { onFinish() }
                            .fontWeight(.semibold)
                            .disabled(vm.swipedCount < 25)
                    }
                }
            }
        }
        .task { if vm.deck.isEmpty { await vm.load() } }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(isFirstRun
                 ? "Swipe right on what interests you, left on what doesn't. Sort at least 25 so we get a feel for your taste."
                 : "Top up your feed any time — swipe to nudge your interests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if isFirstRun {
                Text("\(min(vm.swipedCount, 25)) / 25 sorted")
                    .font(.caption).foregroundStyle(.tertiary)
            } else if vm.swipedCount > 0 {
                Text("\(vm.swipedCount) sorted").font(.caption).foregroundStyle(.tertiary)
            }
        }
    }

    private var deck: some View {
        ZStack {
            // Render the top few cards for a stacked look.
            ForEach(vm.deck.suffix(3)) { article in
                SwipeCardView(article: article) { liked in
                    vm.swipe(article, liked: liked)
                }
            }
        }
        .frame(maxWidth: 520)
        .animation(.spring(duration: 0.3), value: vm.deck)
    }

    private var controls: some View {
        HStack(spacing: 48) {
            Button { if let c = vm.topCard { vm.swipe(c, liked: false) } } label: {
                Image(systemName: "hand.thumbsdown.fill")
                    .font(.title).frame(width: 64, height: 64)
                    .background(.red.opacity(0.15), in: Circle()).foregroundStyle(.red)
            }
            Button { if let c = vm.topCard { vm.swipe(c, liked: true) } } label: {
                Image(systemName: "hand.thumbsup.fill")
                    .font(.title).frame(width: 64, height: 64)
                    .background(.green.opacity(0.15), in: Circle()).foregroundStyle(.green)
            }
        }
        .padding(.bottom)
    }
}

// MARK: - Empty / error states

private struct FinishedState: View {
    let count: Int
    let isFirstRun: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56)).foregroundStyle(.green)
            Text("You sorted \(count) stories").font(.headline)
            Text("Your feed is tuned to your taste. Come back to the Tune tab any time to refine it.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if isFirstRun {
                Button("See my feed", action: onDone)
                    .buttonStyle(.borderedProminent).controlSize(.large)
            }
        }
        .padding()
    }
}

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
