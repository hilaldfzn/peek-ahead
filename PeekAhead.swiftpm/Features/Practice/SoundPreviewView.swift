import SwiftUI

/// "Hear it quietly first": each sound has its own Play button and volume slider. Stop is always on screen.
struct SoundPreviewView: View {
    @State private var model: SoundPreviewModel
    let onDone: () -> Void

    init(
        cues: [SoundCue],
        player: any SoundPlaying,
        soundsEnabled: Bool,
        volumeLimit: Double,
        onDone: @escaping () -> Void
    ) {
        _model = State(
            initialValue: SoundPreviewModel(
                cues: cues, player: player, soundsEnabled: soundsEnabled, volumeLimit: volumeLimit
            )
        )
        self.onDone = onDone
    }

    var body: some View {
        PracticeScaffold(
            title: "Hear it quietly first",
            instruction: Text("You choose how loud. Stop is always here.")
        ) {
            VStack(spacing: AppSpace.lg) {
                if model.soundsEnabled {
                    ForEach(model.cues) { cue in
                        SoundCueRow(cue: cue, model: model)
                    }
                } else {
                    Text("Sounds are off. A grown-up can turn them on in Grown-up mode.")
                        .font(AppFont.note)
                        .foregroundStyle(AppColor.sky)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpace.lg)
                        .background(AppColor.skyTint, in: RoundedRectangle(cornerRadius: AppRadius.md))
                }
            }
        } buttons: {
            Button("Stop") { model.stop() }
                .buttonStyle(.childSecondary)
            Button("Done") {
                model.stop()
                onDone()
            }
            .buttonStyle(.childPrimary)
        }
        .onDisappear { model.stop() }
    }
}

private struct SoundCueRow: View {
    let cue: SoundCue
    let model: SoundPreviewModel

    var body: some View {
        let isPlaying = model.playing == cue.sound
        HStack(spacing: AppSpace.lg) {
            CircleIconButton(
                title: isPlaying ? "Stop" : "Play",
                systemImage: isPlaying ? "stop.fill" : "play.fill"
            ) {
                if isPlaying { model.stop() } else { model.play(cue.sound) }
            }
            VStack(alignment: .leading, spacing: AppSpace.sm) {
                Text(verbatim: cue.label)
                    .font(AppFont.labelChild)
                    .foregroundStyle(AppColor.ink)
                Slider(
                    value: Binding(
                        get: { model.level(for: cue.sound) },
                        set: { model.setLevel($0, for: cue.sound) }
                    ),
                    in: 0...1
                ) {
                    Text("How loud")
                } minimumValueLabel: {
                    Image(systemName: "speaker.fill").accessibilityHidden(true)
                } maximumValueLabel: {
                    Image(systemName: "speaker.wave.3.fill").accessibilityHidden(true)
                }
                .tint(AppColor.primary)
                .frame(minHeight: 64)
                .accessibilityValue(Text("\(Int(model.level(for: cue.sound) * 100)) percent"))
            }
        }
        .padding(AppSpace.lg)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}
