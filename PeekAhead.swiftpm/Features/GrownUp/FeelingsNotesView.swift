import SwiftUI

/// The child's feelings check-ins, newest first. They stay on this iPad and are never judged or scored.
struct FeelingsNotesView: View {
    let progress: ProgressModel

    @State private var confirmingClear = false

    var body: some View {
        List {
            if progress.state.feelings.isEmpty {
                Text("No check-ins yet. They appear here after a story.")
                    .foregroundStyle(.secondary)
            } else {
                Section {
                    ForEach(Array(progress.state.feelings.reversed().enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 12) {
                            BundleImage(name: entry.feeling.imageName)
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.feeling.title).font(.headline)
                                Text(verbatim: entry.storyTitle).font(.subheadline)
                            }
                            Spacer()
                            Text(entry.date, format: .dateTime.day().month().hour().minute())
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                } footer: {
                    Text("Kept on this iPad only. Talk about them with the child; there are no right or wrong answers.")
                }
                Section {
                    Button("Delete all check-ins", role: .destructive) { confirmingClear = true }
                }
            }
        }
        .navigationTitle("Feelings check-ins")
        .confirmationDialog("Delete all check-ins?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { progress.clearFeelings() }
        }
    }
}
