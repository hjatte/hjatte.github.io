import SwiftUI

/// Lets the user pin specific topics on top of what the engine learns.
/// Pinned topics get a strong, non-decaying boost in the feed.
struct TopicsView: View {
    @EnvironmentObject private var store: InterestStore
    @State private var newTopic = ""

    /// What Zesty has learned you like, from your swipes and what you read.
    private var learned: [String] {
        store.topTags(limit: 10).map(\.tag).filter { !store.pinnedTags.contains($0) }
    }

    /// Quick-add suggestions: feed categories plus a few popular topics,
    /// minus anything already pinned or already shown as "learned".
    private var suggestions: [String] {
        let categories = Set(FeedCatalog.all.map(\.category))
        let popular: Set<String> = ["ukraine", "ai", "climate", "election", "apple",
                                    "space", "economy", "football", "health", "energy"]
        return categories.union(popular)
            .subtracting(store.pinnedTags)
            .subtracting(learned)
            .sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                if !learned.isEmpty {
                    Section {
                        ForEach(learned, id: \.self) { tag in
                            HStack {
                                Text("You seem interested in ") + Text(tag).bold()
                                Spacer()
                                Menu {
                                    Button { store.pin(tag) } label: { Label("Yes — pin it", systemImage: "pin") }
                                    Button { store.less(tag) } label: { Label("Less of this", systemImage: "hand.thumbsdown") }
                                    Button(role: .destructive) { store.suppress(tag) } label: {
                                        Label("Not interested", systemImage: "xmark")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle").foregroundStyle(.tint)
                                }
                            }
                        }
                    } header: {
                        Text("Learned from what you read")
                    } footer: {
                        Text("Zesty grows these from the stories you actually read. Tap ••• to confirm, see less, or remove one.")
                    }
                }

                Section {
                    HStack {
                        TextField("Add a topic — e.g. climate, arsenal, ai", text: $newTopic)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit(add)
                        Button("Add", action: add)
                            .disabled(InterestStore.tokenize(newTopic).isEmpty)
                    }
                } header: {
                    Text("Pin a topic")
                } footer: {
                    Text("Pinned topics always rise to the top of your feed and never fade, no matter how the rest of your interests change.")
                }

                if !store.pinnedTags.isEmpty {
                    Section("Pinned") {
                        ForEach(store.pinnedTags.sorted(), id: \.self) { tag in
                            HStack {
                                Image(systemName: "pin.fill").foregroundStyle(.tint)
                                Text(tag)
                                Spacer()
                            }
                        }
                        .onDelete { offsets in
                            let sorted = store.pinnedTags.sorted()
                            offsets.map { sorted[$0] }.forEach(store.unpin)
                        }
                    }
                }

                Section("More to explore") {
                    chipGrid(suggestions, icon: "plus")
                }
            }
            .navigationTitle("Interests")
        }
    }

    private func chipGrid(_ topics: [String], icon: String) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                  alignment: .leading, spacing: 8) {
            ForEach(topics, id: \.self) { topic in
                Button { store.pin(topic) } label: {
                    Label(topic, systemImage: icon)
                        .font(.caption).lineLimit(1)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func add() {
        store.pin(newTopic)
        newTopic = ""
    }
}
