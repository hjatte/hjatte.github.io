import SwiftUI

/// Lets the user pin specific topics on top of what the engine learns.
/// Pinned topics get a strong, non-decaying boost in the feed.
struct TopicsView: View {
    @EnvironmentObject private var store: InterestStore
    @State private var newTopic = ""

    /// Quick-add suggestions: feed categories plus a few popular topics,
    /// minus anything already pinned.
    private var suggestions: [String] {
        let categories = Set(FeedCatalog.all.map(\.category))
        let popular: Set<String> = ["ukraine", "ai", "climate", "election", "apple",
                                    "space", "economy", "football", "health", "energy"]
        return categories.union(popular)
            .subtracting(store.pinnedTags)
            .sorted()
    }

    var body: some View {
        NavigationStack {
            List {
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

                Section("Suggestions") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)],
                              alignment: .leading, spacing: 8) {
                        ForEach(suggestions, id: \.self) { topic in
                            Button {
                                store.pin(topic)
                            } label: {
                                Label(topic, systemImage: "plus")
                                    .font(.caption).lineLimit(1)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(.quaternary, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Topics")
        }
    }

    private func add() {
        store.pin(newTopic)
        newTopic = ""
    }
}
