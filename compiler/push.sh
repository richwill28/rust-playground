#!/usr/bin/env bash

set -euv -o pipefail

source "$(dirname "${BASH_SOURCE[0]}")/image_repository.sh"

compiler_image="${PLAYGROUND_COMPILER_IMAGE}"

docker push "${compiler_image}"