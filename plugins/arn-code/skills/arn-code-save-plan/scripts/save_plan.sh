#!/bin/bash
# save_plan.sh - Find plan file and create project structure
# Usage: save_plan.sh <PROJECT_NAME> <OUTPUT_DIR> [PLAN_FILE_PATH]
#
# PROJECT_NAME   - Name for the project subdirectory (required)
# OUTPUT_DIR     - Base directory where <PROJECT_NAME>/ will be created (required)
# PLAN_FILE_PATH - Path to a plan file. Can be:
#                  1. An absolute or relative path to a file (used directly)
#                  2. A filename to resolve in OUTPUT_DIR or OUTPUT_DIR/PLAN_PREVIEW_<name>.md
#                  3. Omitted to auto-detect: checks PLAN_PREVIEW_*.md in OUTPUT_DIR,
#                     then falls back to ~/.claude/plans/ for legacy compatibility
#
# Examples:
#   save_plan.sh my-feature .arness/plans
#   save_plan.sh my-feature .arness/plans .arness/plans/PLAN_PREVIEW_my-feature.md
#   save_plan.sh my-feature .arness/plans my-feature

set -e

PROJECT_NAME="$1"
OUTPUT_DIR="$2"
PLAN_FILE="$3"

# --- Validate required arguments ---

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: PROJECT_NAME is required"
    echo "Usage: save_plan.sh <PROJECT_NAME> <OUTPUT_DIR> [PLAN_FILE_PATH]"
    exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
    echo "ERROR: OUTPUT_DIR is required"
    echo "Usage: save_plan.sh <PROJECT_NAME> <OUTPUT_DIR> [PLAN_FILE_PATH]"
    exit 1
fi

# --- Context ---

PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"

# --- Resolve plan file ---

if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
    # Explicit path provided and exists — use directly
    echo "Plan: $(basename "$PLAN_FILE")"
elif [ -z "$PLAN_FILE" ]; then
    # No plan file specified: check for PLAN_PREVIEW in output dir, then legacy
    PLAN_FILE=$(ls -t "$OUTPUT_DIR"/PLAN_PREVIEW_*.md 2>/dev/null | head -1)
    if [ -z "$PLAN_FILE" ]; then
        LEGACY_DIR="$HOME/.claude/plans"
        if [ -d "$LEGACY_DIR" ]; then
            PLAN_FILE=$(ls -t "$LEGACY_DIR"/*.md 2>/dev/null | head -1)
            if [ -n "$PLAN_FILE" ]; then
                echo "Plan (legacy): $(basename "$PLAN_FILE")"
            fi
        fi
    else
        echo "Plan: $(basename "$PLAN_FILE")"
    fi
    if [ -z "$PLAN_FILE" ]; then
        echo "ERROR: No plan found. Run /arn-code-plan to create one first."
        exit 1
    fi
else
    # Provided value is not a direct file path — try resolving
    if [ -f "$OUTPUT_DIR/$PLAN_FILE" ]; then
        PLAN_FILE="$OUTPUT_DIR/$PLAN_FILE"
    elif [ -f "$OUTPUT_DIR/PLAN_PREVIEW_$PLAN_FILE.md" ]; then
        PLAN_FILE="$OUTPUT_DIR/PLAN_PREVIEW_$PLAN_FILE.md"
    else
        # Legacy fallback
        LEGACY_DIR="$HOME/.claude/plans"
        if [ -f "$LEGACY_DIR/$PLAN_FILE" ]; then
            PLAN_FILE="$LEGACY_DIR/$PLAN_FILE"
        elif [ -f "$LEGACY_DIR/$PLAN_FILE.md" ]; then
            PLAN_FILE="$LEGACY_DIR/$PLAN_FILE.md"
        else
            echo "ERROR: Plan file not found: $PLAN_FILE"
            exit 1
        fi
    fi
    echo "Plan: $(basename "$PLAN_FILE")"
fi

# --- Create project structure ---

if [ -d "$PROJECT_DIR" ]; then
    echo "WARNING: Project directory already exists: $PROJECT_DIR"
fi

mkdir -p "$PROJECT_DIR/plans"
mkdir -p "$PROJECT_DIR/reports"

cp "$PLAN_FILE" "$PROJECT_DIR/SOURCE_PLAN.md"

# --- Summary ---

echo ""
echo "Project structure ready:"
echo "  $PROJECT_DIR/"
echo "  ├── SOURCE_PLAN.md  (from: $(basename "$PLAN_FILE"))"
echo "  ├── plans/"
echo "  └── reports/"
echo ""
echo "Plan: $(wc -l < "$PLAN_FILE") lines"
