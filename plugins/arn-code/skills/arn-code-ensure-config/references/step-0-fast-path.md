# Arness Code Ensure-Config — Step 0 Fast-Path

This is the **first read** for entry-point skills' Step 0. It runs a shell-only cache check; if the cache is valid, the entry-point can skip reading the full `references/ensure-config.md` (which is ~457 lines). On cache miss, falls through to the full validation flow.

## Procedure

1. **Run the cache check** via Bash:

   ```
   bash ${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/scripts/cache-check.sh
   ```

2. **If exit 0 (cache hit):**
   - Emit a one-line status to the user: `Ensure-config: cache valid (arn-code)`.
   - Return immediately. The entry-point skill's own workflow proceeds with no further config work.
   - **Do NOT read `references/ensure-config.md`** — that is the whole point of the fast path.

3. **If exit non-zero (cache miss):**
   - The script's stderr output includes the reason (e.g., `cache miss: pluginVersion changed`, `cache miss: fingerprint claudeMdArnessSection changed`). Surface it as an info-level note: `Ensure-config: cache miss (<reason>) — running full validation.`
   - **Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md`** and follow ALL its instructions (Layer 1: Profile, Layer 2: Config, Layer 3: Platform Labels).
   - At the end of successful validation, Layer 4 runs `scripts/cache-write.sh`, which writes the new `.arness/arn-code-ensure-config.local.json`.

## Cross-platform notes

The cache-check script works on Linux, Mac, and Windows-via-Git-Bash. It requires `bash`, `sha256sum` or `shasum`, `awk` and `grep`. The `gh` CLI is optional (used only to check the GitHub labels). If any required tool is missing, the script exits non-zero and full validation runs as the fallback.
