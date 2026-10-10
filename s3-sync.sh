#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/config.env.local}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <pull|push> [--delete] [--dry-run] [--config /path/to/config.env.local]

Synchronize a local folder with an S3 bucket folder using aws s3 sync.

Modes:
  pull      Download remote changes from S3 to the local folder
  push      Upload local changes from the local folder to S3

Options:
  --delete  Remove files in the destination that no longer exist in the source
  --dry-run Show the planned sync without changing files
  --config  Load a config file other than the default config.env.local
  -h, --help
            Show this help message
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

require_directory() {
  local path="$1"
  [[ -d "$path" ]] || fail "Directory does not exist: $path"
}

trim_slashes() {
  local value="$1"
  value="${value#/}"
  value="${value%/}"
  printf '%s' "$value"
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || fail "Config file not found: $CONFIG_FILE"

  # shellcheck disable=SC1090
  source "$CONFIG_FILE"

  [[ -n "${S3_BUCKET:-}" ]] || fail "S3_BUCKET must be set in $CONFIG_FILE"
  [[ -n "${LOCAL_SYNC_PATH:-}" ]] || fail "LOCAL_SYNC_PATH must be set in $CONFIG_FILE"
  [[ -n "${AWS_PROFILE:-}" ]] || fail "AWS_PROFILE must be set in $CONFIG_FILE"
  [[ -n "${S3_BUCKET_FOLDER:-}" ]] || fail "S3_BUCKET_FOLDER must be set in $CONFIG_FILE"
}

validate_paths() {
  local local_folder_name
  local remote_folder_name

  local_folder_name="$(basename "${LOCAL_SYNC_PATH%/}")"
  remote_folder_name="$(basename "$S3_BUCKET_FOLDER")"

  [[ -n "$local_folder_name" ]] || fail "LOCAL_SYNC_PATH must point to a folder"
  [[ -n "$remote_folder_name" ]] || fail "S3_BUCKET_FOLDER must point to a folder path"
  [[ "$local_folder_name" == "$remote_folder_name" ]] || fail "Local folder name ($local_folder_name) must match remote folder name ($remote_folder_name)"
}

main() {
  local mode=""
  local delete_flag=false
  local dry_run_flag=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      pull|push)
        [[ -z "$mode" ]] || fail "Only one sync mode can be provided"
        mode="$1"
        shift
        ;;
      --delete)
        delete_flag=true
        shift
        ;;
      --dry-run)
        dry_run_flag=true
        shift
        ;;
      --config)
        [[ $# -ge 2 ]] || fail "--config requires a file path"
        CONFIG_FILE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1"
        ;;
    esac
  done

  [[ -n "$mode" ]] || fail "You must provide a sync mode: pull or push"

  require_command aws
  load_config
  validate_paths

  local normalized_remote_path
  local remote_uri
  normalized_remote_path="$(trim_slashes "$S3_BUCKET_FOLDER")"
  remote_uri="s3://$S3_BUCKET/$normalized_remote_path"

  local source_path
  local destination_path

  case "$mode" in
    pull)
      mkdir -p "$LOCAL_SYNC_PATH"
      source_path="$remote_uri"
      destination_path="$LOCAL_SYNC_PATH"
      ;;
    push)
      require_directory "$LOCAL_SYNC_PATH"
      source_path="$LOCAL_SYNC_PATH"
      destination_path="$remote_uri"
      ;;
  esac

  local cmd=(
    aws s3 sync
    "$source_path"
    "$destination_path"
    --profile "$AWS_PROFILE"
    --exact-timestamps
  )

  if [[ "$delete_flag" == true ]]; then
    cmd+=(--delete)
  fi

  if [[ "$dry_run_flag" == true ]]; then
    cmd+=(--dryrun)
  fi

  printf 'Running command:'
  printf ' %q' "${cmd[@]}"
  printf '\n'

  "${cmd[@]}"
}

main "$@"
