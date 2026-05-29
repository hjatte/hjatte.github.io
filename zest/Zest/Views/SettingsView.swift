import SwiftUI

struct SettingsView: View {
    @StateObject private var sources = SourceSettings.shared
    @StateObject private var theme = ThemeSettings.shared

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
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("The widget on your Home Screen shows your top stories; tap one to read it here. Widgets can't scroll, so the full feed lives in the app.")
                }
            }
            .navigationTitle("Settings")
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
