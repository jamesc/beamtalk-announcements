# Copyright 2026 James Casey
# SPDX-License-Identifier: Apache-2.0

# Standard Beamtalk project targets.
# See: https://beamtalk.dev/docs/tooling

# Build the project
build:
    beamtalk build

# Run the test suite
test:
    beamtalk test

# Check formatting
fmt:
    beamtalk fmt-check

# Format in place
fmt-fix:
    beamtalk fmt

# Lint source files
lint:
    beamtalk lint

# Remove build artifacts
clean:
    rm -rf _build

# Type-check with warnings as errors. Builds first: `check` only sees the
# package's own native -spec types from built artifacts (BT-5342), so on a
# clean tree it would report every native FFI call as untyped Dynamic.
check: build
    beamtalk check --warnings-as-errors

# Full CI check (fmt + lint + build + check + test)
ci: fmt lint build check test

# Tag a release from beamtalk.toml version
release:
    #!/usr/bin/env bash
    set -euo pipefail
    version=$(grep '^version' beamtalk.toml | head -1 | sed 's/.*= *"\(.*\)"/\1/')
    git tag "v${version}"
    echo "Tagged v${version}"

# Push release tags to origin
publish:
    git push origin --tags
