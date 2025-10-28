# Railway deployment Dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND="noninteractive"

# Install system dependencies including Docker
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    file \
    gcc \
    git \
    libssl-dev \
    pkg-config \
    docker.io \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Node.js and pnpm for frontend
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g pnpm

# Copy all source code
WORKDIR /app
COPY . .

# Build frontend
WORKDIR /app/ui/frontend
RUN pnpm install && pnpm build

# Build orchestrator components
WORKDIR /app/compiler/base/orchestrator
RUN cargo build --release

# Build the main UI server
WORKDIR /app/ui
RUN cargo build --release

# Set up the runtime environment
ENV PLAYGROUND_UI_ROOT="/app/ui/frontend/build"
ENV PLAYGROUND_UI_ADDRESS="0.0.0.0"
ENV PLAYGROUND_UI_PORT="3000"
ENV PLAYGROUND_CORS_ENABLED="1"

# Copy the worker binary to expected location
RUN mkdir -p /root/.cargo/bin
RUN cp /app/compiler/base/orchestrator/target/release/worker /root/.cargo/bin/

# Make scripts executable
RUN chmod +x /app/compiler/fetch.sh /app/start.sh

EXPOSE 3000

# Use minimal startup script that runs fetch.sh then starts server
CMD ["/app/start.sh"]