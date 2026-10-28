# Architecture

## Goals

1. **Submittable at any time.** `PeekAhead.swiftpm` is always a valid App Playground that builds offline with no
   third-party packages.
2. **Testable logic.** Everything that can be decided without UIKit, SwiftUI, RealityKit or AVFoundation lives
   in `Core/` and is unit-tested.
3. **Replaceable platform pieces.** Speech, story storage and 3D sit behind small protocols, so each can be
   swapped (a fake in tests, a fallback when a framework is unavailable).

## Layers

```
            ┌──────────────────────────── PeekAhead.swiftpm (module AppModule) ─────────────────────┐
            │                                                                                       │
 App/       │  PeekAheadApp ── AppDependencies (composition root) ── RootView (navigation)          │
            │        │                         │                                                    │
 Features/  │        ▼                         ▼                                                    │
            │  HomeView, StoryPlayerScreen, PipStageView      ◀── DesignSystem/ (tokens, components)│
            │        │                         │                                                    │
 Platform/  │        │        SpeechNarrator, FileStoryProvider.bundled, FontRegistrar, AppResources│
            │        ▼                         ▼  (implement Core protocols)                        │
 Core/      │  Story, StoryValidator, StoryProviding, Narrating, WordSegmenter,                     │
            │  StoryPlayerModel, PipMotion            (Foundation + Observation only)               │
            └───────────────────────────────────────────────────────────────────────────────────────┘
                     ▲
                     │ the same files, compiled as library AppCore by the root Package.swift
             Tests/AppCoreTests
```

**Dependency rule:** arrows point down only. `Core` imports nothing but Foundation and Observation. Features
never talk to AVFoundation or the file system directly; they receive protocols from `AppDependencies`.

The rule is enforced, not just documented: CI compiles `Core/` on Linux, where SwiftUI, UIKit, RealityKit and
AVFoundation don't exist. An accidental `import SwiftUI` in `Core/` fails the build.

| Folder | Holds | Tested by |
|---|---|---|
| `Core/Models` | `Story`, `StoryPage`, `StoryScene`, `ReviewStatus` (Codable value types) | unit tests |
| `Core/Content` | Decoding, structural validation, `StoryProviding` | unit tests, plus a test that loads the bundled JSON |
| `Core/Narration` | `Narrating` protocol, `NarrationEvent`, `WordSegmenter` (UTF-16 word ranges) | unit tests |
| `Core/StoryPlayer` | `StoryPlayerModel`: paging, narration state, highlighted word | unit tests with a scripted narrator |
| `Core/Motion` | `PipMotion`: calm animation parameters, `nil` with Reduce Motion | unit tests |
| `Platform` | `SpeechNarrator` (AVSpeechSynthesizer), font registration, resource lookup, logging | manual (device) |
| `Features` | SwiftUI views; layout and accessibility only | manual and previews |
| `DesignSystem` | Colour, type, spacing tokens from `DESIGN.md`; button styles | visual review |

## Concurrency

- Swift 6 language mode in both packages, so data-race checks are errors.
- UI state (`StoryPlayerModel`, `PipPuppet`, `SpeechNarrator`) is `@MainActor`.
- Narration progress is an `AsyncStream<NarrationEvent>`. `AVSpeechSynthesizerDelegate` callbacks are
  `nonisolated` and hop to the main actor explicitly.
- Each narration gets a generation number. Events from an older narration (for example a late "cancelled" after
  the child taps Read twice) are ignored. A test covers this race.

## Resources

`.process("Resources")` copies every file to the top level of the app bundle, so **file names must be unique
across the `Resources/` subfolders**. `AppResources` looks resources up by name (main bundle first). Fonts are
registered at launch by `FontRegistrar`, because App Playgrounds have no Info.plist font list.

## Decisions

Short records of choices that would otherwise be re-argued. Add one when you make a choice that is hard to undo.

### D1. One App Playground plus a dev-only package for tests
The submission must be a single `.swiftpm` App Playground. Unit tests live outside it: the root `Package.swift`
compiles `PeekAhead.swiftpm/Core` as `AppCore`, and `Tests/` tests it. The submitted folder stays clean, and the
logic is tested on any machine, including Linux CI.
*Cost:* `Core` code is compiled twice (once per package), and must not use anything outside Foundation and
Observation.

### D2. Story scenes are pre-rendered pictures for now; 3D only in `PipStageView`
RealityKit is the largest technical risk (Simulator performance, Swift Playgrounds on iPad). The story player
shows rendered PNGs of the same dioramas, so reading never waits on 3D. `PipStageView` on Home proves the 3D
path. If it holds up on device, scenes move to 3D one at a time; if not, the PNGs stay.

### D3. Narration uses the `.playback` audio category
Narration only starts when the child taps Read, so it should be heard even with the silent switch on. Sound
*previews* (noisy places) will use `.ambient` instead and respect the silent switch, as `DESIGN.md` says.

### D4. Child mode uses the Calm (light) theme only
The Night theme in `DESIGN.md` defines only a few colours, and following the system appearance would change the
look without warning. The theme will become a grown-up setting; until then the app forces light appearance.

### D5. No persistence and no third-party packages yet
Stories are bundled JSON and the app keeps no user data. Persistence (SwiftData) arrives with the reward room
and feelings check-in. Third-party packages are avoided entirely so the playground always builds offline.

## Known gaps

- The app target has not yet been built in Xcode or Swift Playgrounds; only `Core/` is compiled in CI.
  The first local build may need small fixes in `Platform/` and `Features/`.
- The Pip wave axis and angle are first guesses; tune them after looking at the model in Reality Composer Pro.
- Strings are not in a String Catalog yet (planned for the Indonesian/English work).
