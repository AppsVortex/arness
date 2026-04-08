#!/usr/bin/env bash
set -euo pipefail

# save_infra_plan.sh -- Create the infrastructure plan project directory structure.
#
# Usage: save_infra_plan.sh <PROJECT_NAME> <OUTPUT_DIR> [PLAN_FILE_PATH]
#
# Arguments:
#   PROJECT_NAME    -- kebab-case name for the project directory
#   OUTPUT_DIR      -- parent directory where the project will be created (Infra plans directory)
#   PLAN_FILE_PATH  -- (optional) explicit path to PLAN_PREVIEW_INFRA_*.md file
#
# Creates:
#   <OUTPUT_DIR>/<PROJECT_NAME>/
#   ├── SOURCE_PLAN.md
#   ├── plans/
#   └── reports/

PROJECT_NAME="${1:-}"
OUTPUT_DIR="${2:-}"
PLAN_FILE_PATH="${3:-}"

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: PROJECT_NAME is required as the first argument." >&2
  exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
  echo "Error: OUTPUT_DIR is required as the second argument." >&2
  exit 1
fi

# Resolve the plan file
if [ -z "$PLAN_FILE_PATH" ]; then
  # Search for PLAN_PREVIEW_INFRA_*.md in OUTPUT_DIR
  MATCHES=()
  while IFS= read -r -d '' file; do
    MATCHES+=("$file")
  done < <(find "$OUTPUT_DIR" -maxdepth 1 -name "PLAN_PREVIEW_INFRA_*.md" -print0 2>/dev/null)

  # Also check current directory if nothing found
  if [ ${#MATCHES[@]} -eq 0 ]; then
    while IFS= read -r -d '' file; do
      MATCHES+=("$file")
    done < <(find "." -maxdepth 1 -name "PLAN_PREVIEW_INFRA_*.md" -print0 2>/dev/null)
  fi

  if [ ${#MATCHES[@]} -eq 0 ]; then
    echo "Error: No PLAN_PREVIEW_INFRA_*.md file found in $OUTPUT_DIR or current directory." >&2
    echo "Provide the plan file path as the third argument, or run arn-infra-change-plan first." >&2
    exit 1
  elif [ ${#MATCHES[@]} -eq 1 ]; then
    PLAN_FILE_PATH="${MATCHES[0]}"
  else
    echo "Error: Multiple PLAN_PREVIEW_INFRA_*.md files found:" >&2
    for f in "${MATCHES[@]}"; do
      echo "  $f" >&2
    done
    echo "Provide the plan file path as the third argument to select one." >&2
    exit 1
  fi
fi

if [ ! -f "$PLAN_FILE_PATH" ]; then
  echo "Error: Plan file not found: $PLAN_FILE_PATH" >&2
  exit 1
fi

PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"

# Create directory structure
echo "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR/plans"
mkdir -p "$PROJECT_DIR/reports"

# Copy the plan file as SOURCE_PLAN.md
echo "Copying plan preview as SOURCE_PLAN.md"
cp "$PLAN_FILE_PATH" "$PROJECT_DIR/SOURCE_PLAN.md"

echo "Project directory created successfully:"
echo "  $PROJECT_DIR/"
echo "  ├── SOURCE_PLAN.md"
echo "  ├── plans/"
echo "  └── reports/"
