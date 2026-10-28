# Peek Ahead

**Peek Ahead** lets an autistic child see a new or noisy event before it happens: the dentist, a haircut,
Lebaran at Grandma's, a fire drill. The child reads a short picture story that is read aloud, peeks into the
place in a calm, toy-like 3D scene, and practises it with Pip, a small buddy robot.
Everything runs on the device: no accounts, no network, no data collection.

This repository holds the Swift Student Challenge App Playground and the tooling around it.

> **Status: weeks 1–7 of the plan.** The child's full path works: Home → a picture story read aloud word by
> word → practice (steps in order, sound previews, calm tools) → choose a reward for Pip's room → a feelings
> check-in → Home. Behind a 3-second hold, grown-ups can edit and draft stories (on-device model with a template
> fallback), check them against the writing rules, add face-blurred photos, plan the day, and export a PDF.
> Story texts are **placeholders** until an expert (a child psychologist or an experienced special-education
> teacher) has reviewed them. Only `Core/` is compiled and tested so far; the app target has not yet been built in
> Xcode (see [Known gaps](docs/ARCHITECTURE.md#known-gaps)).

## What's in the app

| For | Feature |
|---|---|
| The child | Picture stories with word-by-word narration at a calm 0.9× speed, in English or Indonesian |
| | Practice after a story: put the steps in order, hear the sounds quietly first, pick what helps |
| | Pip's room: choose one of three rewards after each story; nothing is random, nothing can be lost |
| | Feelings check-in with five faces, a Today strip (done, now, next) and an "I need…" card on every screen |
| Grown-ups | A 3-second hold gate; a story editor with live rule chips; drafts from templates or the on-device model |
| | Page photos with automatic face blur; plan the day; read the feelings notes; settings; PDF export |

## Requirements

| To | You need |
|---|---|
| Build and run the app | Xcode 26 or later (iPad simulator), or Swift Playgrounds 4.6 or later on iPad |
| Run the unit tests | A Swift 6.0+ toolchain (comes with Xcode; also works on Linux) |
| Lint and format | `swift-format` (ships with Swift 6 toolchains) |

## Getting started

```bash
git clone https://github.com/hilaldfzn/peek-ahead.git
cd peek-ahead
open PeekAhead.swiftpm        # the app; run it on an iPad simulator
make check                    # lint + unit tests + submission size check
```

Open **`PeekAhead.swiftpm`**, not the repository folder. The `Package.swift` at the root is a development-only package
that exists so the app's logic can be unit-tested (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)).

## Project structure

```
peek-ahead/
├── PeekAhead.swiftpm/              App Playground (this folder is what gets submitted)
│   ├── Package.swift               iOS app manifest (AppleProductTypes)
│   ├── App/                        Entry point, dependency wiring, child navigation
│   ├── Core/                       Platform-independent logic, unit-tested on any machine
│   │   ├── Models/  Content/       Stories, practice, validation, loading
│   │   ├── Narration/  StoryPlayer/
│   │   ├── Practice/  Progress/    Step game, sound limits, rewards, feelings, day plan, saved progress
│   │   └── Rules/  Drafting/  Editor/  Motion/
│   ├── Platform/                   Adapters around Apple frameworks (speech, audio, Foundation Models,
│   │                               photos, Vision face blur, files, fonts, logging)
│   ├── DesignSystem/               Tokens and components from DESIGN.md
│   ├── Features/                   SwiftUI screens: Home, StoryPlayer, Practice, Reward, Feelings,
│   │                               NeedCard, PipStage (RealityKit), GrownUp
│   └── Resources/                  Fonts, Pip USDZ, scenes, pictograms, room items, sounds, story JSON
├── Tests/AppCoreTests/             Unit tests for PeekAhead.swiftpm/Core (Swift Testing)
├── Package.swift                   Dev-only package: builds Core as a library for `swift test`
├── docs/                           Architecture, development workflow, content guide
├── scripts/                        Submission size check
└── .github/workflows/ci.yml        Lint, tests and size check on every push
```

## Commands

| Command | What it does |
|---|---|
| `make test` | Runs the unit tests (`swift test`) |
| `make lint` | Checks formatting and style (`swift-format lint --strict`) |
| `make format` | Formats the code in place |
| `make size` | Zips `PeekAhead.swiftpm` and checks it is under the 25 MB submission limit |
| `make check` | All of the above except `format`; the same checks CI runs |

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): layers, dependency rules, concurrency, and the decisions behind them
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md): workflow, commit conventions, definition of done, pre-submission checklist
- [docs/CONTENT.md](docs/CONTENT.md): how stories are written, stored and reviewed
- [CREDITS.md](CREDITS.md): fonts, 3D model, sounds and pictograms, with their licences

## Principles

- **Calm by default.** No timers, no failure states, nothing that plays by itself. Sounds stay off until a
  grown-up turns them on. Reduce Motion is respected.
- **Accessible from the first commit.** VoiceOver labels, Dynamic Type up to AX5, large targets.
- **Offline and private.** No network calls, no analytics, no accounts. Photos stay on the device, with faces
  blurred.
- **Honest claims.** The app helps families prepare for events together. It does not claim therapeutic outcomes.
