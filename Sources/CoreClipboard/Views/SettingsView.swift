import Core
import SwiftUI

struct SettingsView: View {
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @AppStorage("historyLimit") private var historyLimit = ClipboardHistoryLimit.defaultValue
    let onHistoryLimitChange: (Int) -> Void

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

            Section("History") {
                Stepper(value: $historyLimit, in: ClipboardHistoryLimit.minimum...ClipboardHistoryLimit.maximum) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saved Items")
                        Text("Keep between \(ClipboardHistoryLimit.minimum) and \(ClipboardHistoryLimit.maximum) recent clipboard entries.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(historyLimit) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: historyLimit) { _, newValue in
            onHistoryLimitChange(newValue)
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 240)
        .padding(20)
    }
}
