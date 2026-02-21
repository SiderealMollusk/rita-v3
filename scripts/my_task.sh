#!/usr/bin/env bash
set -euo pipefail

# Example consumer script that uses a secret loaded by run_with_secret.sh
# It expects the environment variable NEWT_REPO_KEY to be set.

if [[ -z "${NEWT_REPO_KEY:-}" ]]; then
  echo "Error: NEWT_REPO_KEY is not set. Did you run via run_with_secret.sh?" >&2
  exit 1
fi

echo "🔑 Using Newt repo GPG key: $NEWT_REPO_KEY"
# Here you could add the actual logic that needs the secret, e.g., adding the apt repo.
# For demonstration we just print the key.
