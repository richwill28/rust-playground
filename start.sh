#!/usr/bin/env bash

set -euo pipefail

export PLAYGROUND_UI_ADDRESS="${PLAYGROUND_UI_ADDRESS:-0.0.0.0}"
export PLAYGROUND_UI_PORT="${PLAYGROUND_UI_PORT:-${PORT:-3000}}"

if [[ "${PLAYGROUND_SKIP_COMPILER_FETCH:-0}" != "1" ]]; then
	if ! command -v docker >/dev/null 2>&1; then
		echo "Docker CLI is not available. This backend requires Docker to run compiler containers." >&2
		echo "Set PLAYGROUND_SKIP_COMPILER_FETCH=1 only if rust-stable/rust-beta/rust-nightly are already present." >&2
		exit 1
	fi

	if ! docker info >/dev/null 2>&1; then
		echo "Docker daemon is unavailable. The playground needs Docker access to run compiler containers." >&2
		echo "Provide Docker access (local socket or DOCKER_HOST) or set PLAYGROUND_SKIP_COMPILER_FETCH=1 if images are preloaded." >&2
		exit 1
	fi

	cd /app/compiler
	./fetch.sh
fi

cd /app/ui
exec ./target/release/ui