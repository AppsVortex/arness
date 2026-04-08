# Pattern Refresh Procedure

Automatic post-implementation refresh of stored pattern documentation. After implementation tasks complete, the codebase may contain new conventions, architectural decisions, or testing approaches that are not yet reflected in the stored pattern docs. This procedure detects and writes those updates so pattern docs stay current without manual intervention.

## When to Invoke

- **execute-plan** -- after all tasks complete (Step 5b)
- **execute-plan-teams** -- after all IMPL and REVIEW tasks complete (Step 6)
- **swift** -- after moderate-ceremony implementation completes
- **standard** -- after implementation completes
- **catch-up** -- after catch-up record generation (user-confirmed)

## Procedure

1. **Read the Code patterns directory path** from the `## Arness` config in CLAUDE.md (the `Code patterns` field). This is the directory containing `code-patterns.md`, `testing-patterns.md`, `architecture.md`, and optionally `ui-patterns.md` and `security-patterns.md`.

2. **Check if pattern docs exist.** Look for `code-patterns.md`, `testing-patterns.md`, and `architecture.md` in the Code patterns directory.
   - If **none exist** AND this is **not** a catch-up context: skip the refresh with message: "Pattern documentation has not been generated yet. Run any pipeline skill to trigger initial generation."
   - If **none exist** AND this **is** a catch-up context: invoke the `arn-code-codebase-analyzer` agent with full analysis mode to generate pattern docs from scratch. Write the output to the Code patterns directory. Print: "Pattern documentation generated from scratch." Return.
   - If **at least one exists**: proceed to step 3.

3. **Invoke the `arn-code-codebase-analyzer` agent** with full analysis mode. Pass the current Code patterns directory path and instruct the agent to analyze the full codebase for patterns, architecture, and testing conventions.

4. **Compare fresh analysis against stored pattern files.** Identify:
   - **New patterns** -- patterns found in the analysis that do not appear in stored docs
   - **Changed patterns** -- patterns whose details (reference files, examples, descriptions) differ from stored versions
   - **Removed patterns** -- patterns in stored docs that no longer have supporting evidence in the codebase

5. **If differences found:** Write updated pattern files automatically to the Code patterns directory. Print summary:
   ```
   Pattern documentation updated: N new patterns, M changed, K removed.
   ```

6. **If no differences:** Print:
   ```
   Pattern documentation is up to date.
   ```

## Error Handling

If the `arn-code-codebase-analyzer` agent fails or returns empty output, print a warning:

```
Pattern refresh failed -- patterns unchanged. This does not affect your implementation.
```

Continue without blocking. The pattern refresh is supplementary -- a failure here does not invalidate the implementation or test results.

## Gating

- **Pipeline skills** (execute-plan, execute-plan-teams, swift, standard): Automatic. No user confirmation required. The refresh runs silently and reports results.
- **Catch-up skill**: User-confirmed. The catch-up skill handles its own gating before invoking this procedure -- it asks the user whether to refresh patterns after generating catch-up records.
