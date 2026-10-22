#!/bin/bash
# save_plan.sh - Find plan file and create project structure
# Usage: save_plan.sh <PROJECT_NAME> <OUTPUT_DIR> [PLAN_FILE_PATH] [--force]
#
# PROJECT_NAME   - Name for the project subdirectory (required)
# OUTPUT_DIR     - Base directory where <PROJECT_NAME>/ will be created (required)
# PLAN_FILE_PATH - Path to a plan file. Can be:
#                  1. An absolute or relative path to a file (used directly)
#                  2. A filename to resolve in OUTPUT_DIR or OUTPUT_DIR/PLAN_PREVIEW_<name>.md
#                  3. Omitted to auto-detect: uses the single PLAN_PREVIEW_*.md in
#                     OUTPUT_DIR (errors if there are none or several)
# --force        - Replace an existing SOURCE_PLAN.md that differs from the plan
#
# Examples:
#   save_plan.sh my-feature .arness/plans
#   save_plan.sh my-feature .arness/plans .arness/plans/PLAN_PREVIEW_my-feature.md
#   save_plan.sh my-feature .arness/plans my-feature

set -e

PROJECT_NAME="$1"
OUTPUT_DIR="$2"
PLAN_FILE="$3"
FORCE="$4"

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

case "$PROJECT_NAME" in
    .|..|*[!A-Za-z0-9._-]*)
        echo "ERROR: PROJECT_NAME may only contain letters, digits, '.', '_' and '-': $PROJECT_NAME"
        exit 1
        ;;
esac

# --- Context ---

PROJECT_DIR="$OUTPUT_DIR/$PROJECT_NAME"

# --- Resolve plan file ---

if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
    # Explicit path provided and exists — use directly
    echo "Plan: $(basename "$PLAN_FILE")"
elif [ -z "$PLAN_FILE" ]; then
    # No plan file specified: use the only PLAN_PREVIEW in the output dir.
    # Never guess from other projects' plans (e.g. ~/.claude/plans).
    count=0
    for f in "$OUTPUT_DIR"/PLAN_PREVIEW_*.md; do
        [ -f "$f" ] || continue
        count=$((count + 1))
        PLAN_FILE="$f"
    done
    if [ "$count" -eq 0 ]; then
        echo "ERROR: No plan found. Run /arn-code-plan to create one first."
        exit 1
    fi
    if [ "$count" -gt 1 ]; then
        echo "ERROR: Several PLAN_PREVIEW files in $OUTPUT_DIR. Pass the plan file to use."
        exit 1
    fi
    echo "Plan: $(basename "$PLAN_FILE")"
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

if [ -f "$PROJECT_DIR/SOURCE_PLAN.md" ] && ! cmp -s "$PLAN_FILE" "$PROJECT_DIR/SOURCE_PLAN.md" && [ "$FORCE" != "--force" ]; then
    echo "ERROR: $PROJECT_DIR/SOURCE_PLAN.md already exists and differs from $(basename "$PLAN_FILE")."
    echo "Re-run with --force as the 4th argument to replace it."
    exit 1
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
echo "Plan: $(wc -l < "$PLAN_FILE" | tr -d ' ') lines"
