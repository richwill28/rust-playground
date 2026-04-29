#!/usr/bin/env bash

# Canonical compiler image used by this project.
# Local rust-stable/rust-beta/rust-nightly tags are all aliases of this image.
PLAYGROUND_COMPILER_IMAGE="${PLAYGROUND_COMPILER_IMAGE:-richwill28/rust}"

# Canonical Rust source repository and ref used to build rustc.
PLAYGROUND_RUST_REPO="${PLAYGROUND_RUST_REPO:-https://github.com/richwill28/rust.git}"
PLAYGROUND_RUST_REF="${PLAYGROUND_RUST_REF:-view-types}"