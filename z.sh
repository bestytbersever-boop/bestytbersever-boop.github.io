#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS="$ROOT/projects"
DOWNLOADS="$ROOT/public/downloads"

mkdir -p "$DOWNLOADS"

if [[ ! -d "$PROJECTS" ]]; then
  echo "ERROR: projects folder was not found at $PROJECTS" >&2
  exit 1
fi

shopt -s nullglob
project_dirs=("$PROJECTS"/*/)
shopt -u nullglob

if [[ ${#project_dirs[@]} -eq 0 ]]; then
  echo "No project folders found in $PROJECTS"
  exit 0
fi

for project_path in "${project_dirs[@]}"; do
  project_name="$(basename "$project_path")"
  zip_file="$DOWNLOADS/${project_name}.zip"

  echo "Zipping project: $project_name"
  rm -f "$zip_file"
  (cd "$project_path" && zip -r -q "$zip_file" .)

done

echo "Created $(find "$DOWNLOADS" -maxdepth 1 -type f -name '*.zip' | wc -l | tr -d ' ') ZIP files in $DOWNLOADS"
