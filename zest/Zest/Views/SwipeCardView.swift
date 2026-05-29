import SwiftUI

/// A single draggable story card with the like/nope overlay.
struct SwipeCardView: View {
    let article: Article
    let onSwipe: (_ liked: Bool) -> Void

    @State private var offset: CGSize = .zero
    private let threshold: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            thumbnail
            VStack(alignment: .leading, spacing: 8) {
                SourceBadge(source: article.pillar ?? article.section.capitalized,
                            category: article.section,
                            domain: URL(string: article.url)?.host)
                Text(article.title)
                    .font(.title3.weight(.semibold)).lineLimit(3)
                if let trail = article.trailText {
                    Text(trail).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                }
                Spacer(minLength: 0)
                TagChips(tags: article.tags)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 460)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.quaternary))
        .overlay(alignment: .topLeading) { stamp("INTERESTED", .green, visible: offset.width > 40) }
        .overlay(alignment: .topTrailing) { stamp("PASS", .red, visible: offset.width < -40) }
        .shadow(radius: 6, y: 4)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 18)))
        .gesture(
            DragGesture()
                .onChanged { offset = $0.translation }
                .onEnded { value in
                    if abs(value.translation.width) > threshold {
                        let liked = value.translation.width > 0
                        withAnimation(.spring) {
                            offset = CGSize(width: liked ? 600 : -600, height: value.translation.height)
                        }
                        onSwipe(liked)
                    } else {
                        withAnimation(.spring) { offset = .zero }
                    }
                }
        )
    }

    @ViewBuilder private var thumbnail: some View {
        if let urlString = article.thumbnailURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(.quaternary)
            }
            .frame(height: 200).frame(maxWidth: .infinity).clipped()
        } else {
            Rectangle().fill(.quaternary).frame(height: 200)
                .overlay(Image(systemName: "newspaper").font(.largeTitle).foregroundStyle(.secondary))
        }
    }

    private func stamp(_ text: String, _ color: Color, visible: Bool) -> some View {
        Text(text)
            .font(.headline.weight(.heavy)).foregroundStyle(color)
            .padding(8).overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(color, lineWidth: 3))
            .rotationEffect(.degrees(-12)).padding(24)
            .opacity(visible ? 1 : 0)
    }
}

/// Small wrapped chips showing an article's interest tokens.
struct TagChips: View {
    let tags: [String]

    var body: some View {
        ViewThatFits {
            row(Array(tags.prefix(4)))
            row(Array(tags.prefix(3)))
            row(Array(tags.prefix(2)))
        }
    }

    private func row(_ items: [String]) -> some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { tag in
                Text(tag)
                    .font(.caption2).padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}
