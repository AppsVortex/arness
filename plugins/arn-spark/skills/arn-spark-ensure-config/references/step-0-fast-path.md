# Arness Spark Ensure-Config — Step 0 Fast-Path

This is the **first read** for entry-point skills' Step 0. It runs a shell-only cache check; if the cache is valid, the entry-point can skip reading the full `references/ensure-config.md`. On cache miss, falls through to the full validation flow.

## Procedure

1. **Run the cache check** via Bash:

   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/scripts/cache-check.sh
   ```

2. **If exit 0 (cache hit):**
   - Emit a one-line status to the user: `Ensure-config: cache valid (arn-spark, last validated <duration> ago)`. Read the `validatedAt` timestamp from `.arness/arn-spark-ensure-config.local.json` to format the duration; if reading fails, just say "cache valid".
   - Return immediately. The entry-point skill's own workflow proceeds with no further config work.
   - **Do NOT read `references/ensure-config.md`** — that is the whole point of the fast path.

3. **If exit non-zero (cache miss):**
   - The script's stderr output includes the reason (e.g., `cache miss: pluginVersion changed`, `cache miss: fingerprint claudeMdArnessSection changed`). Surface it as an info-level note: `Ensure-config: cache miss (<reason>) — running full validation.`
   - **Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/ensure-config.md`** and follow ALL its instructions.
   - At the end of successful validation, the ensure-config.md flow's "Cache Write" step writes the new `.arness/arn-spark-ensure-config.local.json` per the cache schema documented inline there.

## Cross-platform notes

The cache-check script works on Linux, Mac, and Windows-via-Git-Bash. It requires `bash`, `sha256sum` or `shasum`, `awk`, `grep`, `cat`, and `jq`. The `gh` CLI is optional (used only for GitHub label count verification). If any required tool is missing, the script exits non-zero and full validation runs as the fallback.
