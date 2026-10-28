import SwiftUI

/// The child's sensory profile and the app's data, in one place.
struct SettingsView: View {
    let progress: ProgressModel

    @State private var confirmingDelete = false

    var body: some View {
        Form {
            Section {
                TextField(
                    "Child\u{2019}s first name (optional)",
                    text: Binding(
                        get: { progress.settings.childName ?? "" },
                        set: { name in progress.updateSettings { $0.childName = name.isEmpty ? nil : name } }
                    )
                )
                .textContentType(.givenName)
            } header: {
                Text("Child")
            } footer: {
                Text("Used only to say hello on Home.")
            }

            Section {
                Toggle(
                    "Sound previews",
                    isOn: Binding(
                        get: { progress.settings.soundsEnabled },
                        set: { on in progress.updateSettings { $0.soundsEnabled = on } }
                    )
                )
                LabeledContent("Loudest preview") {
                    Slider(
                        value: Binding(
                            get: { progress.settings.previewVolumeLimit },
                            set: { value in progress.updateSettings { $0.previewVolumeLimit = value } }
                        ),
                        in: 0.2...1
                    )
                    .frame(maxWidth: 260)
                }
                .disabled(!progress.settings.soundsEnabled)
                Picker(
                    "Reading speed",
                    selection: Binding(
                        get: { progress.settings.narrationSpeed },
                        set: { speed in progress.updateSettings { $0.narrationSpeed = speed } }
                    )
                ) {
                    Text("Calm (0.9\u{00D7})").tag(NarrationSpeed.calm)
                    Text("Slower (0.75\u{00D7})").tag(NarrationSpeed.slower)
                }
            } header: {
                Text("Sound and reading")
            } footer: {
                Text("Previews always start at 20% of this limit and fade in. The fire alarm never goes above 40%.")
            }

            Section {
                Button("Delete all data", role: .destructive) { confirmingDelete = true }
            } header: {
                Text("Data")
            } footer: {
                Text("Everything stays on this iPad: no accounts, no network, no analytics.")
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Delete all data?", isPresented: $confirmingDelete, titleVisibility: .visible
        ) {
            Button("Delete everything", role: .destructive) {
                progress.deleteAllData()
                PhotoStore.removeUnreferenced(keeping: [])
            }
        } message: {
            Text("Pip\u{2019}s room, check-ins, your stories, today\u{2019}s plan and settings will be removed.")
        }
    }
}
