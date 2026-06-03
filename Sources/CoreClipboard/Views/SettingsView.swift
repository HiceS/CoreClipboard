import SwiftUI

struct SettingsView: View {
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager

    var body: some View {
        Form {
            Section("General") {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { launchAtLoginManager.isEnabled },
                        set: { launchAtLoginManager.setEnabled($0) }
                    )
                )

                if let statusMessage = launchAtLoginManager.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 160)
        .padding(20)
    }
}
