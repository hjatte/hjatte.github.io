import SwiftUI

/// First-run tuning: a welcome card, then a Tinder-style swipe deck with a
/// filling-lemon progress indicator, then a celebration when 25 are sorted.
struct OnboardingView: View {
    @StateObject private var vm: OnboardingViewModel
    let isFirstRun: Bool
    let onFinish: () -> Void
    @State private var started = false

    private let goal = 25

    init(client: NewsAPIClient, isFirstRun: Bool, onFinish: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: OnboardingViewModel(client: client, store: InterestStore.shared))
        self.isFirstRun = isFirstRun
        self.onFinish = onFinish
    }

    private var progress: Double { min(Double(vm.swipedCount) / Double(goal), 1) }

    var body: some View {
        Group {
            if vm.swipedCount >= goal {
                CompletionView(onFinish: onFinish)
            } else if !started {
                WelcomeView { started = true; Task { await vm.load() } }
            } else {
                tuningView
            }
        }
    }

    private var tuningView: some View {
        VStack(spacing: 12) {
            LemonProgress(progress: progress)
                .frame(width: 60, height: 60)
                .padding(.top, 10)
            Text(encouragement).font(.headline)
            Text("\(vm.swipedCount) / \(goal)").font(.caption).foregroundStyle(.secondary)

            switch vm.state {
            case .loading:
                Spacer(); ProgressView("Gathering stories…"); Spacer()
            case .failed(let message):
                Spacer(); ErrorState(message: message) { Task { await vm.load() } }; Spacer()
            case .ready, .finished:
                deck
                controls
            }
        }
        .padding()
    }

    private var deck: some View {
        ZStack {
            ForEach(vm.deck.suffix(3)) { article in
                SwipeCardView(article: article) { liked in vm.swipe(article, liked: liked) }
            }
        }
        .frame(maxWidth: 520)
        .animation(.spring(duration: 0.3), value: vm.deck)
    }

    private var controls: some View {
        HStack(spacing: 48) {
            Button { if let c = vm.topCard { vm.swipe(c, liked: false) } } label: { thumb("hand.thumbsdown.fill", .red) }
            Button { if let c = vm.topCard { vm.swipe(c, liked: true) } } label: { thumb("hand.thumbsup.fill", .green) }
        }
        .padding(.bottom)
    }

    private func thumb(_ symbol: String, _ color: Color) -> some View {
        Image(systemName: symbol)
            .font(.title).frame(width: 64, height: 64)
            .background(color.opacity(0.15), in: Circle()).foregroundStyle(color)
    }

    private var encouragement: String {
        switch vm.swipedCount {
        case 0:      return "Swipe to teach Zesty your taste"
        case 1..<7:  return "Great start! 🍋"
        case 7..<13: return "Nice picks — keep going"
        case 13..<19: return "Over halfway!"
        case 19..<24: return "Almost there…"
        default:     return "Last one!"
        }
    }
}

// MARK: - Welcome

private struct WelcomeView: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            LemonProgress(progress: 1).frame(width: 96, height: 96)
            Text("Let’s find your news")
                .font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
            Text("We’ll show you a quick stack of stories. Swipe right on what interests you, left on what doesn’t — that’s how Zesty learns what to put in your feed.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            Button(action: onStart) {
                Text("Start").frame(maxWidth: .infinity)
            }
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
            JuicyLemon().frame(width: 150, height: 170)
            Text("Thanks! 🍋").font(.largeTitle.weight(.bold))
            Text("We’ve got a good idea of the news you’ll love. Your feed is ready.")
                .font(.body).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
            Spacer()
            Button(action: onFinish) {
                Text("Go to news feed").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).controlSize(.large).padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Lemon graphics

/// A lemon slice whose wedges fill up as `progress` (0…1) climbs.
struct LemonProgress: View {
    var progress: Double
    var body: some View {
        Canvas { ctx, size in
            let d = min(size.width, size.height); let r = d / 2
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let n = 10
            let filled = Int((Double(n) * progress).rounded())
            let rind = Color(red: 0.97, green: 0.79, blue: 0.18)
            let on = Color(red: 1.0, green: 0.88, blue: 0.35)
            let off = Color(red: 0.88, green: 0.88, blue: 0.84)

            ctx.fill(Circle().path(in: CGRect(x: c.x - r, y: c.y - r, width: d, height: d)), with: .color(rind))
            let fr = r * 0.82
            for i in 0..<n {
                let a0 = Double(i) / Double(n) * 2 * .pi - .pi / 2
                let a1 = Double(i + 1) / Double(n) * 2 * .pi - .pi / 2
                var p = Path()
                p.move(to: c)
                p.addArc(center: c, radius: fr, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                p.closeSubpath()
                ctx.fill(p, with: .color(i < filled ? on : off))
            }
            var seps = Path()
            for i in 0..<n {
                let a = Double(i) / Double(n) * 2 * .pi - .pi / 2
                seps.move(to: c)
                seps.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * fr, y: c.y + CGFloat(sin(a)) * fr))
            }
            ctx.stroke(seps, with: .color(.white), lineWidth: max(1, r * 0.07))
        }
        .animation(.easeOut(duration: 0.35), value: progress)
    }
}

/// A whole lemon with a leaf and a few juice drips, for the finish screen.
struct JuicyLemon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lemon = Color(red: 1.0, green: 0.83, blue: 0.20)

            // drips first (behind the lemon)
            let drip = Color(red: 1.0, green: 0.90, blue: 0.42)
            for dx in [w * 0.32, w * 0.5, w * 0.68] {
                var p = Path()
                p.move(to: CGPoint(x: dx, y: h * 0.66))
                p.addQuadCurve(to: CGPoint(x: dx - w * 0.045, y: h * 0.84),
                               control: CGPoint(x: dx - w * 0.06, y: h * 0.74))
                p.addArc(center: CGPoint(x: dx, y: h * 0.86), radius: w * 0.045,
                         startAngle: .radians(.pi), endAngle: .radians(0), clockwise: true)
                p.addQuadCurve(to: CGPoint(x: dx, y: h * 0.66),
                               control: CGPoint(x: dx + w * 0.06, y: h * 0.74))
                ctx.fill(p, with: .color(drip))
            }

            // leaf
            ctx.fill(Ellipse().path(in: CGRect(x: w * 0.55, y: h * 0.02, width: w * 0.22, height: h * 0.12)),
                     with: .color(Color(red: 0.30, green: 0.70, blue: 0.36)))
            // body
            ctx.fill(Ellipse().path(in: CGRect(x: w * 0.12, y: h * 0.10, width: w * 0.76, height: h * 0.60)),
                     with: .color(lemon))
            // highlight
            ctx.fill(Ellipse().path(in: CGRect(x: w * 0.24, y: h * 0.18, width: w * 0.26, height: h * 0.16)),
                     with: .color(.white.opacity(0.25)))
        }
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
