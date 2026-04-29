#!/usr/bin/env bash

set -euv -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/image_repository.sh"

compiler_image="${PLAYGROUND_COMPILER_IMAGE}"

docker pull "${compiler_image}"
docker tag "${compiler_image}" "rust-stable"
docker tag "${compiler_image}" "rust-beta"
docker tag "${compiler_image}" "rust-nightly"
