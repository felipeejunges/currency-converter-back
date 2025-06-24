#!/bin/bash
set -e

# Ensure Ruby gems are in the PATH
export PATH="$PATH:/usr/local/bundle/bin"

# Remove a potentially pre-existing server.pid for Rails.
rm -f /currency-converter-back/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
