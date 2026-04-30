#!/usr/bin/env bash

set -euo pipefail

export PLAYGROUND_UI_ADDRESS="${PLAYGROUND_UI_ADDRESS:-0.0.0.0}"
export PLAYGROUND_UI_PORT="${PLAYGROUND_UI_PORT:-${PORT:-3000}}"

setup_remote_docker_tls() {
	if [[ -z "${DOCKER_CA_PEM_B64:-}" && -z "${DOCKER_CERT_PEM_B64:-}" && -z "${DOCKER_KEY_PEM_B64:-}" ]]; then
		return 0
	fi

	local certs_dir="${PLAYGROUND_DOCKER_CERTS_DIR:-/tmp/playground-docker-certs}"
	mkdir -p "$certs_dir"
	chmod 700 "$certs_dir"

	if [[ -n "${DOCKER_CA_PEM_B64:-}" ]]; then
		printf '%s' "$DOCKER_CA_PEM_B64" | base64 --decode > "$certs_dir/ca.pem"
	fi

	if [[ -n "${DOCKER_CERT_PEM_B64:-}" ]]; then
		printf '%s' "$DOCKER_CERT_PEM_B64" | base64 --decode > "$certs_dir/cert.pem"
	fi

	if [[ -n "${DOCKER_KEY_PEM_B64:-}" ]]; then
		printf '%s' "$DOCKER_KEY_PEM_B64" | base64 --decode > "$certs_dir/key.pem"
		chmod 600 "$certs_dir/key.pem"
	fi

	export DOCKER_CERT_PATH="${DOCKER_CERT_PATH:-$certs_dir}"
	export DOCKER_TLS_VERIFY="${DOCKER_TLS_VERIFY:-1}"
}

docker_registry_login() {
	local username="${PLAYGROUND_DOCKERHUB_USERNAME:-${DOCKERHUB_USERNAME:-}}"
	local token="${PLAYGROUND_DOCKERHUB_TOKEN:-${DOCKERHUB_TOKEN:-}}"

	if [[ -z "$username" || -z "$token" ]]; then
		return 0
	fi

	printf '%s' "$token" | docker login --username "$username" --password-stdin
}

if [[ "${PLAYGROUND_SKIP_COMPILER_FETCH:-0}" != "1" ]]; then
	setup_remote_docker_tls

	if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
		if ! docker_registry_login; then
			echo "Docker registry login failed; continuing without prefetch." >&2
		fi
		cd /app/compiler
		if ! ./fetch.sh; then
			echo "Compiler image fetch failed; starting backend anyway." >&2
			echo "Compile/execute may fail until PLAYGROUND_COMPILER_IMAGE is reachable." >&2
		fi
	else
		echo "Docker is unavailable; skipping compiler image fetch and starting in degraded mode." >&2
		echo "Set DOCKER_HOST to a reachable Docker daemon (plus TLS vars if needed) to enable compile/execute." >&2
	fi
fi

cd /app/ui
exec ./target/release/ui