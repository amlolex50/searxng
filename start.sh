#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SearXNG startup script for Cloud Run

set -e

# Generate a secure secret key if not provided
if [ -z "$SEARXNG_SECRET_KEY" ]; then
    echo "Generating secure secret key..."
    export SEARXNG_SECRET_KEY=$(openssl rand -hex 32)
    echo "Secret key generated successfully"
else
    echo "Using provided secret key"
fi

# Start SearXNG
echo "Starting SearXNG on $HOST:$PORT"
exec python -m searx.webapp
