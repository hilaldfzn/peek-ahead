SWIFT_SOURCES := PeekAhead.swiftpm Tests Package.swift

.PHONY: check test lint format size

## Everything CI runs: lint, unit tests and the submission size check.
check: lint test size

## Unit tests for the platform-independent code (PeekAhead.swiftpm/Core).
test:
	swift test --parallel

## Fails on any formatting or style issue.
lint:
	swift-format lint --strict --recursive $(SWIFT_SOURCES)

## Rewrites files in place to match .swift-format.
format:
	swift-format format --in-place --recursive $(SWIFT_SOURCES)

## Zips PeekAhead.swiftpm the way it will be submitted and checks it stays under the size limit.
size:
	scripts/check-submission-size.sh
