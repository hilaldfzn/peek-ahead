# Development workflow

## Daily loop

1. Open `PeekAhead.swiftpm` in Xcode and run on an iPad simulator (landscape) and an iPhone simulator.
2. Put logic in `Core/` first, with a test in `Tests/AppCoreTests`. Keep views thin.
3. Before committing: `make check` (lint, tests, size).

## Branches and commits

- `main` always builds and passes `make check`.
- Work on short branches: `feature/practice-steps`, `fix/narration-race`, `docs/content-guide`.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):
  `feat(player): stop narration when the page changes`, `fix(core): …`, `test: …`, `docs: …`, `chore: …`, `ci: …`.
  One logical change per commit; explain *why* in the body when it isn't obvious.

## Definition of done (for any user-facing change)

- [ ] Logic is in `Core/` and covered by tests where possible.
- [ ] `make check` passes.
- [ ] Runs on the iPad simulator (landscape and portrait) and the iPhone simulator.
- [ ] VoiceOver: every control has a spoken label, and the reading order matches the visual order.
- [ ] Dynamic Type at AX5: nothing is cut off, and layouts stack vertically.
- [ ] Reduce Motion on: nothing bobs, waves or slides.
- [ ] No sound or narration starts by itself.

## Before submitting

- [ ] Every story is `"review": "reviewed"`, the review is recorded in `docs/CONTENT.md`, and the
      `placeholderStoriesAreMarked` test has been updated to expect reviewed stories.
- [ ] The "Draft" badge no longer appears on Home.
- [ ] Airplane mode: the whole app works offline.
- [ ] Builds and runs in **Swift Playgrounds on an iPad** and in the Xcode version the rules require.
- [ ] `make size` shows the zipped playground is under the limit.
- [ ] Credits screen lists everything in `CREDITS.md`.
- [ ] Your AI-use notes are up to date for the submission form.
