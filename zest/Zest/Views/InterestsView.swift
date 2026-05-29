import SwiftUI
import Charts

/// Shows the live interest profile so you can see what the app has learned,
/// and adjust how fast it forgets.
struct InterestsView: View {
    @EnvironmentObject private var store: InterestStore
    @State private var confirmingReset = false

    private var top: [TagScore] {
        store.topTags(limit: 18)
    }

    var body: some View {
        NavigationStack {
            Group {
                if top.isEmpty {
                    ContentUnavailableView(
                        "No interests yet",
                        systemImage: "chart.bar",
                        description: Text("Swipe through stories in the Tune tab and tap things you like in the feed.")
                    )
                } else {
                    List {
                        Section("What you're into right now") {
                            Chart(top) { item in
                                BarMark(
                                    x: .value("Score", item.score),
                                    y: .value("Tag", item.tag)
                                )
                                .foregroundStyle(.tint)
                                .annotation(position: .trailing) {
                                    Text("\(Int(item.score))").font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .chartXAxis(.hidden)
                            .frame(height: CGFloat(top.count) * 26 + 20)
                        }

                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Forget speed")
                                    Spacer()
                                    Text("\(Int(store.profile.halfLifeDays)) day half-life")
                                        .foregroundStyle(.secondary)
                                }
                                Slider(
                                    value: Binding(
                                        get: { store.profile.halfLifeDays },
                                        set: { store.setHalfLife($0) }
                                    ),
                                    in: 3...45, step: 1
                                )
                                Text("Interests fade over the days you actually open the app (not calendar days). Lower = forgets faster.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } header: {
                            Text("How fast the feed adapts")
                        }

                        Section {
                            Button("Reset everything", role: .destructive) { confirmingReset = true }
                        }
                    }
                }
            }
            .navigationTitle("Interests")
            .confirmationDialog("Reset all learned interests?",
                                isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { store.reset() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
