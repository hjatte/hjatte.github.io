import SwiftUI

/// How taps on a story open it. Stored in UserDefaults via @AppStorage.
enum ReaderOpenMode: String, CaseIterable, Identifiable {
    case reader, web
    var id: String { rawValue }
    var label: String { self == .reader ? "Reader" : "Web page" }
}

struct SettingsView: View {
    @EnvironmentObject private var store: InterestStore
    @StateObject private var sources = SourceSettings.shared
    @StateObject private var theme = ThemeSettings.shared
    @AppStorage("readerOpenMode") private var openMode = ReaderOpenMode.reader.rawValue
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    NavigationLink {
                        FlavourPickerView(isOnboarding: false)
                    } label: {
                        HStack {
                            Text("Flavour")
                            Spacer()
                            Circle().fill(theme.flavour.accent).frame(width: 18, height: 18)
                            Text(theme.flavour.name).foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Picker("Open articles in", selection: $openMode) {
                        ForEach(ReaderOpenMode.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Reading")
                } footer: {
                    Text("Reader shows a clean, ad-free version of each story. Web shows the original page. You can also switch per-article while reading.")
                }

                Section {
                    NavigationLink {
                        SourcesView()
                    } label: {
                        LabeledContent("News sources", value: "\(sources.enabledSources.count) on")
                    }
                } header: {
                    Text("Where your news comes from")
                } footer: {
                    Text("Zesty aggregates free, open RSS feeds from multiple publishers — no account or API key needed. Turn sources on or off to shape your mix.")
                }

                Section {
                    Button("Reset learned interests", role: .destructive) { confirmingReset = true }
                } footer: {
                    Text("Clears everything Zesty has learned and your reading history. Pinned topics and your flavour are kept.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("The widget on your Home Screen shows your top stories; tap one to read it here. Widgets can't scroll, so the full feed lives in the app.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Reset learned interests?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { store.reset() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

/// Lets the user enable/disable individual feeds, grouped by category.
struct SourcesView: View {
    @ObservedObject private var settings = SourceSettings.shared

    var body: some View {
        List {
            ForEach(FeedCatalog.byCategory) { group in
                Section(group.category.capitalized) {
                    ForEach(group.sources) { source in
                        Toggle(isOn: Binding(
                            get: { settings.isEnabled(source) },
                            set: { settings.setEnabled($0, for: source) }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.name)
                                Text(source.feedURL.host ?? "")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("News sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}
