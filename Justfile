# ChartsEx development and release tasks

version := `sed -n 's/^  @version "\(.*\)"/\1/p' mix.exs | head -1`

# Run tests with NIF compilation
test:
    CHARTS_EX_BUILD=true mix test

# Run tests, format check, and clippy
check:
    CHARTS_EX_BUILD=true mix test
    mix format --check-formatted
    cd native/charts_ex && cargo clippy -- -D warnings

# Format Elixir and Rust code
format:
    mix format
    cd native/charts_ex && cargo fmt

# Generate hex docs locally
docs:
    CHARTS_EX_BUILD=true mix docs

# Full release: tag, push, wait for builds, download checksums, commit, publish
release: _release-preflight _release-tag _release-wait _release-checksums _release-publish

# Step 1: Verify everything is clean and passing before release
_release-preflight:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Preflight checks for v{{version}}..."

    # Clean working tree?
    if [ -n "$(git status --porcelain)" ]; then
        echo "ERROR: Working tree is dirty. Commit or stash changes first."
        exit 1
    fi

    # On master?
    branch=$(git branch --show-current)
    if [ "$branch" != "master" ]; then
        echo "ERROR: Not on master (on $branch). Switch to master first."
        exit 1
    fi

    # Up to date with remote?
    git fetch origin master --quiet
    if [ "$(git rev-parse master)" != "$(git rev-parse origin/master)" ]; then
        echo "ERROR: Local master differs from origin. Pull or push first."
        exit 1
    fi

    # Tag doesn't already exist?
    if git rev-parse "v{{version}}" >/dev/null 2>&1; then
        echo "ERROR: Tag v{{version}} already exists."
        exit 1
    fi

    # Tests pass?
    echo "==> Running tests..."
    CHARTS_EX_BUILD=true mix test --trace
    echo "==> Format check..."
    mix format --check-formatted
    echo "==> Preflight passed."

# Step 2: Tag and push to trigger the release workflow
_release-tag:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Tagging v{{version}} and pushing..."
    git tag "v{{version}}"
    git push origin "v{{version}}"
    echo "==> Tag pushed. Release workflow triggered."

# Step 3: Wait for the release workflow to finish
_release-wait:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Waiting for release workflow to complete..."
    # Find the run triggered by our tag
    sleep 5
    run_id=$(gh run list --repo jtippett/charts_ex --workflow release.yml --branch "v{{version}}" --limit 1 --json databaseId --jq '.[0].databaseId')
    if [ -z "$run_id" ]; then
        echo "ERROR: Could not find release workflow run for v{{version}}"
        exit 1
    fi
    echo "==> Watching run $run_id..."
    gh run watch "$run_id" --repo jtippett/charts_ex --exit-status
    echo "==> Release workflow completed successfully."

# Step 4: Download precompiled binaries and commit checksums
_release-checksums:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Downloading precompiled binaries and generating checksums..."
    CHARTS_EX_BUILD=true mix compile --force
    mix rustler_precompiled.download ChartsEx.Native --all --print
    echo "==> Committing checksums..."
    git add checksum-Elixir.ChartsEx.Native.exs
    git commit -m "chore: add precompiled binary checksums for v{{version}}"
    git push origin master
    echo "==> Checksums committed and pushed."

# Step 5: Publish to Hex
_release-publish:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Publishing v{{version}} to Hex..."
    mix hex.publish
    echo "==> Published! https://hex.pm/packages/charts_ex/{{version}}"
