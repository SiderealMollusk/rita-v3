#!/usr/bin/env bash
set -euo pipefail

# Wrapper that loads required secrets and runs a target script.
# Usage: run_with_secret.sh <script> [args...]

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET_SCRIPT=$1
shift || true

# Source shared auth helpers.
source "${SCRIPT_DIR}/secret_loader.sh"
ensure_op_auth

# Example: load the Newt repo GPG key and export it for the target script.
export NEWT_REPO_KEY=$(op item get "newt_secrets" --vault "${OP_VAULT:-rita-v3}" --fields "label=newt_repo_key" --reveal)

# Execute the target script with any additional arguments.
exec "${TARGET_SCRIPT}" "$@"
