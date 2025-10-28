#!/bin/bash
set -e

# Fetch compiler containers
cd /app/compiler && ./fetch.sh

# Start the server
cd /app/ui && exec ./target/release/ui