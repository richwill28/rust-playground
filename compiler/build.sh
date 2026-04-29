#!/usr/bin/env bash

set -euv -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/image_repository.sh"

compiler_image="${PLAYGROUND_COMPILER_IMAGE}"
rust_repo="${PLAYGROUND_RUST_REPO}"
rust_ref="${PLAYGROUND_RUST_REF}"

docker build \
    -t "rust-stable" \
    -t "${compiler_image}" \
    --build-arg "rust_repo=${rust_repo}" \
    --build-arg "rust_ref=${rust_ref}" \
    base

docker tag "rust-stable" "rust-beta"
docker tag "rust-stable" "rust-nightly"
