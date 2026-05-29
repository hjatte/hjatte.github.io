import SwiftUI

struct SettingsView: View {
    @State private var key = APIConfig.guardianKey
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Guardian API key", text: $key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save") {
                        APIConfig.setRuntimeKey(key)
                        saved = true
                    }
                    .disabled(key.isEmpty)
                } header: {
                    Text("News source")
                } footer: {
                    Text("Zest uses The Guardian's free Open Platform API. Get a key in about a minute at open-platform.theguardian.com/access. You can also bake it in via Configs/Secrets.xcconfig.")
                }

                if saved {
                    Section { Label("Key saved", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
                }

                Section {
                    LabeledContent("Status", value: APIConfig.hasKey ? "Connected" : "No key")
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
