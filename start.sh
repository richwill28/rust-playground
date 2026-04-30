#!/usr/bin/env bash

set -euo pipefail

export PLAYGROUND_UI_ADDRESS="${PLAYGROUND_UI_ADDRESS:-0.0.0.0}"
export PLAYGROUND_UI_PORT="${PLAYGROUND_UI_PORT:-${PORT:-3000}}"

if [[ "${PLAYGROUND_SKIP_COMPILER_FETCH:-0}" != "1" ]]; then
	if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
		cd /app/compiler
		./fetch.sh
	else
		echo "Docker is unavailable; skipping compiler image fetch and starting in degraded mode." >&2
		echo "Compilation and execution endpoints require Docker access to function." >&2
	fi
fi

cd /app/ui
exec ./target/release/ui