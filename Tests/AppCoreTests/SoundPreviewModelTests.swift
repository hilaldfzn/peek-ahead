import Testing

@testable import AppCore

@MainActor
@Suite("Sound preview")
struct SoundPreviewModelTests {
    private let player = FakeSoundPlayer()
    private let cues = [
        SoundCue(sound: .dentistDrill, label: "The little brush"),
        SoundCue(sound: .fireAlarm, label: "The fire alarm"),
    ]

    private func makeModel(soundsEnabled: Bool = true, volumeLimit: Double = 1) -> SoundPreviewModel {
        SoundPreviewModel(cues: cues, player: player, soundsEnabled: soundsEnabled, volumeLimit: volumeLimit)
    }

    @Test func everySliderStartsAtTwentyPercent() {
        let model = makeModel()
        #expect(model.level(for: .dentistDrill) == 0.2)
        #expect(model.level(for: .fireAlarm) == 0.2)
    }

    @Test func nothingPlaysUntilAsked() {
        _ = makeModel()
        #expect(player.plays.isEmpty)
    }

    @Test func nothingPlaysWhileSoundsAreOff() {
        let model = makeModel(soundsEnabled: false)
        #expect(model.play(.dentistDrill) == nil)
        #expect(player.plays.isEmpty)
        #expect(model.playing == nil)
    }

    @Test func playsQuietlyWithAFadeIn() {
        let model = makeModel()
        model.play(.dentistDrill)
        #expect(player.plays == [.init(sound: .dentistDrill, volume: 0.2, fadeIn: 1.5)])
        #expect(model.playing == .dentistDrill)
    }

    @Test func theFireAlarmIsCappedAndTheGrownUpLimitApplies() {
        let model = makeModel(volumeLimit: 0.5)
        model.setLevel(1, for: .fireAlarm)
        #expect(model.effectiveVolume(for: .fireAlarm) == 0.4 * 0.5)
        model.setLevel(5, for: .dentistDrill)
        #expect(model.level(for: .dentistDrill) == 1)
        #expect(model.effectiveVolume(for: .dentistDrill) == 0.5)
    }

    @Test func movingTheSliderWhilePlayingChangesTheVolumeAtOnce() {
        let model = makeModel()
        model.play(.dentistDrill)
        model.setLevel(0.6, for: .dentistDrill)
        #expect(player.volumes.last == 0.6)
        model.setLevel(0.9, for: .fireAlarm)  // not playing: no volume change
        #expect(player.volumes.count == 1)
    }

    @Test func playingAnotherSoundStopsTheFirst() {
        let model = makeModel()
        model.play(.dentistDrill)
        model.play(.fireAlarm)
        #expect(player.stopCount >= 1)
        #expect(model.playing == .fireAlarm)
    }

    @Test func endsWhenTheClipEnds() async {
        let model = makeModel()
        let task = model.play(.dentistDrill)
        player.finishCurrent()
        await task?.value
        #expect(model.playing == nil)
    }

    @Test func stopIsAlwaysSafe() {
        let model = makeModel()
        model.stop()
        model.play(.fireAlarm)
        model.stop()
        #expect(model.playing == nil)
    }
}
