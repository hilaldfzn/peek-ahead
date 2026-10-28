# Peek Ahead

**Peek Ahead** lets an autistic child see a new or noisy event before it happens: the dentist, a haircut,
Lebaran at Grandma's, a fire drill. The child reads a short picture story that is read aloud, peeks into the
place in a calm, toy-like 3D scene, and practises it with Pip, a small buddy robot.
Everything runs on the device: no accounts, no network, no data collection.

This repository holds the Swift Student Challenge App Playground and the tooling around it.

> **Status: skeleton.** One vertical slice works end to end: Home → read a 4-page story with word-by-word
> narration → Home. Pip appears in 3D on Home as a RealityKit spike. Story texts are **placeholders** until an
> expert (a child psychologist or an experienced special-education teacher) has reviewed them.

## Requirements

| To | You need |
|---|---|
| Build and run the app | Xcode 26 or later (iPad simulator), or Swift Playgrounds 4.6 or later on iPad |
| Run the unit tests | A Swift 6.0+ toolchain (comes with Xcode; also works on Linux) |
| Lint and format | `swift-format` (ships with Swift 6 toolchains) |

## Getting started

```bash
git clone <this repository> Peek Ahead
cd Peek Ahead
open PeekAhead.swiftpm        # the app; run it on an iPad simulator
make check               # lint + unit tests + submission size check
```

Open **`PeekAhead.swiftpm`**, not the repository folder. The `Package.swift` at the root is a development-only package
that exists so the app's logic can be unit-tested (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)).

## Project structure

```
Peek Ahead/
├── PeekAhead.swiftpm/               App Playground (this folder is what gets submitted)
│   ├── Package.swift           iOS app manifest (AppleProductTypes)
│   ├── App/                    Entry point, dependency wiring, navigation
│   ├── Core/                   Platform-independent logic: models, content, narration, player state
│   ├── Platform/               Adapters around Apple frameworks (speech, fonts, bundle, logging)
│   ├── DesignSystem/           Tokens and components from DESIGN.md
│   ├── Features/               SwiftUI screens: Home, StoryPlayer, PipStage (RealityKit)
│   └── Resources/              Fonts, Pip USDZ, scene renders, story JSON
├── Tests/AppCoreTests/        Unit tests for PeekAhead.swiftpm/Core (Swift Testing)
├── Package.swift               Dev-only package: builds Core as a library for `swift test`
├── docs/                       Architecture, development workflow, content guide
├── scripts/                    Submission size check
└── .github/workflows/ci.yml    Lint, tests and size check on every push
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
- [CREDITS.md](CREDITS.md): third-party assets and fonts with their licences

## Principles

- **Calm by default.** No timers, no failure states, nothing that plays by itself. Reduce Motion is respected.
- **Accessible from the first commit.** VoiceOver labels, Dynamic Type up to AX5, large targets.
- **Offline and private.** No network calls, no analytics, no accounts.
- **Honest claims.** The app helps families prepare for events together. It does not claim therapeutic outcomes.
