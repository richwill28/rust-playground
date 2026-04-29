#syntax=docker/dockerfile:1.5

FROM ubuntu:24.04 as toolchain

ARG rust_repo="https://github.com/richwill28/rust.git"
ARG rust_ref="view-types"

ENV DEBIAN_FRONTEND="noninteractive"

# `build-essential` and `file` are needed for backtrace-sys
# `cmake`, `git`, `python` are needed for wasm tools
RUN apt-get update && apt-get install -y \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    file \
    gcc \
    git \
    libssl-dev \
    ninja-build \
    pkg-config \
    python3 \
    rustup \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m playground -d /playground
RUN usermod -p '!!' root # Disable all passwords for root

# Attach the security note
COPY --chown=playground attach_notice.sh security_notice.txt /playground/
RUN /playground/attach_notice.sh /playground/security_notice.txt /etc/passwd && \
    /playground/attach_notice.sh /playground/security_notice.txt /etc/shadow && \
    rm -f /playground/attach_notice.sh

USER playground
ENV USER=playground
ENV PATH=/playground/.cargo/bin:/playground/rust/build/x86_64-unknown-linux-gnu/stage2/bin:$PATH
WORKDIR /playground

RUN git clone --branch "${rust_ref}" "${rust_repo}" /playground/rust && \
    cd /playground/rust && \
    python3 x.py build --stage 2 && \
    python3 x.py dist rust-src rustc-dev llvm-tools --stage 2 && \
    python3 x.py dist cargo --stage 2 && \
    stage2_prefix="/playground/rust/build/x86_64-unknown-linux-gnu/stage2" && \
    cd /playground/rust/build/dist && \
    for package in rust-src rustc-dev llvm-tools cargo; do \
        archive="$(ls "${package}-"*.tar.gz | head -n1)" && \
        tar -xzf "${archive}" && \
        dir="${archive%.tar.gz}" && \
        cd "${dir}" && \
        ./install.sh --prefix="${stage2_prefix}" --disable-ldconfig && \
        cd .. && \
        rm -rf "${dir}"; \
    done && \
    /playground/rust/build/x86_64-unknown-linux-gnu/stage2/bin/rustc --version && \
    /playground/rust/build/x86_64-unknown-linux-gnu/stage2/bin/cargo --version

COPY --chown=playground entrypoint.sh /playground/tools/

# Build Charon from source with custom rustc stage2

FROM toolchain as charon-build

USER root
RUN apt-get update && apt-get install -y \
    bubblewrap \
    libgmp-dev \
    m4 \
    opam \
 && rm -rf /var/lib/apt/lists/*

USER playground
# Docker builders often disallow unprivileged user namespaces required by bubblewrap.
RUN opam init --auto-setup --disable-sandboxing --bare
RUN opam switch create 5.2.0 -y
RUN git clone --branch "view-types" https://github.com/richwill28/charon.git /playground/charon && \
    cd /playground/charon && \
    opam exec --switch=5.2.0 -- opam install . --deps-only --with-doc --with-test -y && \
    opam exec --switch=5.2.0 -- opam install -y ocamlformat.0.27.0 && \
    opam exec --switch=5.2.0 -- env CUSTOM_RUSTC_STAGE2=/playground/rust/build/x86_64-unknown-linux-gnu/stage2 make build-custom

# Build Aeneas from source with custom rustc lib path

FROM charon-build as aeneas-build

RUN git clone --branch "view-types" https://github.com/richwill28/aeneas.git /playground/aeneas && \
    cd /playground/aeneas && \
    ln -s /playground/charon charon && \
    opam exec --switch=5.2.0 -- opam install -y \
        ppx_deriving \
        visitors \
        easy_logging \
        zarith \
        yojson \
        core_unix \
        odoc \
        ocamlgraph \
        menhir \
        ocamlformat \
        unionFind \
        progress \
        domainslib && \
    opam exec --switch=5.2.0 -- env CUSTOM_RUSTC_LIB=/playground/rust/build/x86_64-unknown-linux-gnu/stage2/lib make build

# Build wasm-tools

FROM toolchain as wasm-tools

RUN cargo install --locked wasm-tools

# Fetch all the crate source files

FROM toolchain as sources

RUN mkdir /playground/src && echo 'fn main() {}' > /playground/src/main.rs
COPY --chown=playground Cargo.toml /playground/Cargo.toml
COPY --chown=playground crate-information.json /playground/crate-information.json
RUN cargo fetch

# Set up cargo-chef for faster builds

FROM toolchain as chef-available

RUN cargo install --locked cargo-chef

WORKDIR /orchestrator

# Prepare the orchestrator's dependencies

FROM chef-available as prepare-orchestrator

COPY --chown=playground asm-cleanup /asm-cleanup
COPY --chown=playground modify-cargo-toml /modify-cargo-toml
COPY --chown=playground orchestrator /orchestrator
RUN cargo chef prepare

# Build the orchestrator

FROM chef-available as build-orchestrator

COPY --chown=playground asm-cleanup /asm-cleanup
COPY --chown=playground modify-cargo-toml /modify-cargo-toml
COPY --chown=playground --from=prepare-orchestrator /orchestrator/recipe.json /orchestrator/recipe.json
RUN cargo chef cook --locked --release

COPY --chown=playground orchestrator /orchestrator
RUN cargo install --locked --path .

# Compiler and pre-compiled crates

FROM sources

# Charon uses a pinned rustup toolchain. Install it during image build so
# Aeneas requests in network-isolated runtime containers don't attempt
# toolchain downloads.
COPY --from=charon-build /playground/charon/rust-toolchain /playground/charon-rust-toolchain
RUN python3 - <<'PY'
import pathlib
import subprocess
import tomllib

content = pathlib.Path('/playground/charon-rust-toolchain').read_text().strip()
if content.startswith('['):
    data = tomllib.loads(content)
    toolchain = data['toolchain']['channel']
    components = list(data['toolchain'].get('components', []))
else:
    toolchain = content
    components = []

cmd = ['rustup', 'toolchain', 'install', toolchain, '--profile', 'minimal', '--no-self-update']
for component in components:
    cmd.extend(['--component', component])
subprocess.check_call(cmd)
PY

RUN cargo build
RUN cargo build --release
# Fresh playground requests run in brand-new containers. Prebuilding a Polonius
# artifact set avoids recompiling the top-crate dependency graph on every
# Polonius run in runtime containers.
RUN RUSTFLAGS="-Zpolonius=next" cargo build
RUN RUSTFLAGS="-Zpolonius=next" cargo build --release
RUN rm src/*.rs

COPY --from=build-orchestrator /playground/.cargo/bin/worker /playground/.cargo/bin/worker
COPY --from=wasm-tools /playground/.cargo/bin/wasm-tools /playground/.cargo/bin
COPY --from=charon-build /playground/charon/bin/charon /playground/.cargo/bin/charon
COPY --from=charon-build /playground/charon/bin/charon-driver /playground/.cargo/bin/charon-driver
COPY --from=aeneas-build /playground/aeneas/bin /playground/aeneas-bin
COPY --chown=playground cargo-wasm /playground/.cargo/bin
# `cargo-miri-playground` is vestigial and can be removed after a while
COPY --chown=playground cargo-miri-playground /playground/.cargo/bin
USER root
RUN ln -sf /playground/aeneas-bin/aeneas /playground/.cargo/bin/aeneas && \
    ln -sf /playground/aeneas-bin/test_runner /playground/.cargo/bin/test_runner
USER playground

ENTRYPOINT ["/playground/tools/entrypoint.sh"]
