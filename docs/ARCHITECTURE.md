# Architecture

## Goals

1. **Submittable at any time.** `PeekAhead.swiftpm` is always a valid App Playground that builds offline with no
   third-party packages.
2. **Testable logic.** Everything that can be decided without UIKit, SwiftUI, RealityKit, AVFoundation, Vision or
   Foundation Models lives in `Core/` and is unit-tested.
3. **Replaceable platform pieces.** Speech, sound, storage, 3D and the language model sit behind small protocols, so
   each can be swapped: a fake in tests, a fallback when a framework or device can't provide it.

## Layers

```
App/          PeekAheadApp → AppDependencies (composition root) → RootView (child navigation)
                 │
Features/     Home · StoryPlayer · Practice · Reward · Feelings · NeedCard · PipStage · GrownUp
                 │            uses DesignSystem/ (tokens and components from DESIGN.md)
                 ▼
Platform/     SpeechNarrator · AudioPreviewPlayer · FoundationModelsDrafter · PhotoStore · FaceBlurrer
              FontRegistrar · AppResources · AppPaths · Log         (implement Core protocols)
                 │
                 ▼
Core/         Foundation + Observation only; compiled again as library AppCore by the root Package.swift
                 ▲
Tests/AppCoreTests
```

**Dependency rule:** arrows point down only. `Core` imports nothing but Foundation and Observation. Features never
talk to AVFoundation, the file system or the language model directly; they get protocols or models from
`AppDependencies`.

The rule is enforced, not just documented: CI compiles `Core/` on Linux, where none of the Apple UI and media
frameworks exist. An accidental `import SwiftUI` in `Core/` fails the build.

| Folder | Holds | Tested by |
|---|---|---|
| `Core/Models` | `Story`, `StoryPage` (kind, optional photo), `StoryPractice`, sounds, pictograms, calm tools | unit tests |
| `Core/Content` | Decoding, structural validation, `StoryProviding` | unit tests, including the bundled JSON |
| `Core/Narration` | `Narrating`, `NarrationEvent`, `WordSegmenter` (UTF-16 word ranges) | unit tests |
| `Core/StoryPlayer` | `StoryPlayerModel`: paging, narration state, highlighted word | unit tests, scripted narrator |
| `Core/Practice` | `StepOrderingGame` (seeded, errorless), `SoundPreviewModel` (sensory limits), `SoundPlaying` | unit tests, fake player |
| `Core/Progress` | `ProgressModel`, `ProgressState`, JSON file store, rewards, feelings, day plan, settings, `ChildJourney` | unit tests, temp files |
| `Core/Rules` | `StoryRuleChecker`: the DESIGN.md language rules in English and Indonesian | unit tests, bundled stories, all templates |
| `Core/Drafting` | `StoryDrafting`, `TemplateDrafter`, `DraftingCoordinator` (fallback, cleaning untrusted output) | unit tests, stub model |
| `Core/Editor` | `StoryEditorModel`: page edits with live rule checks | unit tests |
| `Core/Motion` | `PipMotion`: calm animation parameters, `nil` with Reduce Motion | unit tests |
| `Platform` | Apple-framework adapters | manual, on device |
| `Features` | SwiftUI screens: layout and accessibility only | manual |
| `DesignSystem` | Colour, type and spacing tokens; button styles; `ChoiceCard` | visual review |

## The child's path

`ChildJourney` decides the order: story → practice → reward → feelings → Home, skipping any step with nothing to
offer (no practice in the story, every reward already owned). Each step **replaces** the previous screen, so Back
can never return a child to a reward they already chose. "I need…" is in the same corner of every child screen.

## Concurrency

- Swift 6 language mode in both packages, so data-race checks are errors.
- UI state and services with UI effects (`StoryPlayerModel`, `SoundPreviewModel`, `ProgressModel`,
  `StoryEditorModel`, `SpeechNarrator`, `AudioPreviewPlayer`, `PipPuppet`) are `@MainActor`.
- Progress from AVFoundation is an `AsyncStream`. Delegate callbacks are `nonisolated` and hop to the main actor.
- Narration and sound previews carry a generation number, so late events from an older narration or clip are
  ignored. Tests cover both races.
- Drafters are `Sendable` and `async`; the model runs off the main actor.

## Data

- **Progress** (Pip's room, check-ins, calm tools, day plan, settings, grown-up stories) is one JSON file in
  Application Support, written atomically after every change.
- An unreadable file is moved aside and never deleted; a file written by a newer app version is never overwritten.
  Missing keys load with defaults, so older files keep working.
- **Photos** live in `Application Support/PeekAhead/Photos` with complete file protection. They are removed when no
  saved story refers to them, but never while the progress file is unreadable.
- Nothing leaves the device: no accounts, no network calls, no analytics.

## Resources

`.process("Resources")` copies every file to the top level of the app bundle, so **file names must be unique
across the `Resources/` subfolders**. `AppResources` looks resources up by name (main bundle first). Fonts are
registered at launch by `FontRegistrar`, because App Playgrounds have no Info.plist font list. Unit tests check that
every scene, sound, pictogram, room item and feeling has its file.

## Decisions

Short records of choices that would otherwise be re-argued. Add one when you make a choice that is hard to undo.

### D1. One App Playground plus a dev-only package for tests
The submission must be a single `.swiftpm` App Playground. Unit tests live outside it: the root `Package.swift`
compiles `PeekAhead.swiftpm/Core` as `AppCore`, and `Tests/` tests it. The submitted folder stays clean, and the
logic is tested on any machine, including Linux CI.
*Cost:* `Core` code is compiled twice, and must not use anything outside Foundation and Observation.

### D2. Story scenes are pre-rendered pictures for now; 3D only in `PipStageView`
RealityKit is the largest technical risk (Simulator performance, Swift Playgrounds on iPad). The story player shows
rendered PNGs of the same dioramas, so reading never waits on 3D. `PipStageView` on Home proves the 3D path. If it
holds up on device, scenes (and Pip's room) move to 3D one at a time; if not, the PNGs stay.

### D3. Narration uses `.playback`; sound previews use `.ambient`
Narration only starts when the child taps Read, so it should be heard even with the silent switch on. Sound
previews of noisy places respect the silent switch, and stay off until a grown-up turns them on (DESIGN.md).

### D4. Child mode uses the Calm (light) theme only
The Night theme in `DESIGN.md` defines only a few colours, and following the system appearance would change the
look without warning. The theme will become a grown-up setting; until then the app forces light appearance.

### D5. No third-party packages
Every dependency is an Apple framework, so the playground always builds offline and meets the submission rules.

### D6. Progress is a JSON file, not SwiftData
The data is small and simple. A Codable file is readable, easy to migrate (missing keys get defaults), and fully
tested on every platform, which SwiftData can't be in this setup. Revisit if the data grows or needs queries.

### D7. Model output is untrusted input
The on-device model may be unavailable, refuse, or produce something unusable. `DraftingCoordinator` always has a
template fallback, and cleans every model draft: trimmed, renumbered, capped at 8 pages, no invented photos, marked
as not yet reviewed, validated like any other story. Then the rule checker runs. The grown-up reviews every page,
and the editor says when and why a template was used.

### D8. Errorless practice
Practice has no fail state: cards in place get a check, "Help me" places a card, and Done is always available.
Rewards come in a fixed order, the child chooses one of three, and nothing can be lost (DESIGN.md).

## Known gaps

- **The app target has not been built in Xcode or Swift Playgrounds yet.** Only `Core/` is compiled and tested in
  CI. The first local build will likely need small fixes in `Platform/` and `Features/`, especially the
  `FoundationModels` `@Generable` types, which have not been compiled against the iOS 26 SDK.
- The Pip wave axis and angle are first guesses; tune them after looking at the model in Reality Composer Pro.
- The rule checker's word lists (both languages) need the expert reviewer's eye.
- Fire drill and new-place templates have no step cards until there are pictograms for school, alarm and walking.
- Strings are not in a String Catalog yet; the UI is English, while stories can be English or Indonesian.
