# Catch-Up Record Format

Reference for the `arn-code-catch-up` skill. Defines the CATCHUP_ record format, including the CHANGE_RECORD.json envelope with the `catchup` extension object, boundary marker records, and the markdown summary format.

---

## Envelope

CATCHUP_ records use the existing `CHANGE_RECORD_TEMPLATE.json` schema (see `CHANGE_RECORD_TEMPLATE.json` in the template directory) with these specific field values:

| Field | Value |
|-------|-------|
| `recordType` | `"change-record"` |
| `version` | `1` |
| `ceremonyTier` | `"catchup"` |
| `projectName` | Auto-generated from the primary theme or commit range (e.g., `"fix-auth-headers"` or `"catchup-2026-03-15-to-2026-03-29"`) |
| `changePath` | `<plans-dir>/CATCHUP_<name>/` |
| `timestamp` | Current ISO 8601 timestamp |
| `tierSelection` | `{ "recommended": "catchup", "selected": "catchup", "overrideReason": null }` |
| `specRef` | Empty string (catch-up records have no spec) |
| `planRef` | Empty string (catch-up records have no plan) |
| `reportRef` | Empty string |
| `commitHash` | The covered commit hash (single-commit records) or the latest commit hash in the group |
| `commitMessage` | The covered commit message (single-commit records) or a generated group summary |
| `review` | `{ "verdict": "not-applicable", "findingCount": { "warnings": 0, "errors": 0 } }` |
| `sketchRef` | Empty string |
| `nextSteps` | Array of suggested follow-up actions |

---

## Catchup Extension Object

The `catchup` extension object is appended to the standard CHANGE_RECORD envelope. It captures the retroactive nature of the record and is honest about confidence levels.

```json
"catchup": {
  "scanRange": {
    "start": "<ISO date>",
    "end": "<ISO date>",
    "method": "tier-tag | progress-tracker | 30-day-default"
  },
  "coveredCommits": ["<hash1>", "<hash2>"],
  "confidence": "low",
  "gaps": [
    "commit message too terse to determine intent",
    "no test changes detected"
  ],
  "whatWeKnow": "Changed files X, Y, Z. Commit message: '...'",
  "whatWeDontKnow": "Intent behind the change. Whether tests were run. Architectural reasoning.",
  "groupingTheme": "theme name (for grouped records)",
  "boundaryMarker": false
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `scanRange.start` | ISO 8601 string | Start of the scan window |
| `scanRange.end` | ISO 8601 string | End of the scan window (usually HEAD date) |
| `scanRange.method` | string | Which scan range detection tier was used: `"tier-tag"`, `"progress-tracker"`, or `"30-day-default"` |
| `coveredCommits` | string[] | Array of full commit hashes covered by this record |
| `confidence` | string | Always `"low"` -- catch-up records are retroactive and lack real-time context |
| `gaps` | string[] | Honest list of what information is missing or uncertain |
| `whatWeKnow` | string | Facts derived from git: files changed, commit message, diff stats |
| `whatWeDontKnow` | string | Information that cannot be recovered retroactively: intent, test coverage, architectural reasoning |
| `groupingTheme` | string or null | Theme name for grouped records; `null` for individual records |
| `boundaryMarker` | boolean | `false` for normal records; `true` for boundary markers |

---

## Boundary Marker Record

Boundary markers document the edge between pre-Arness and Arness-tracked history. They use the same envelope but with additional boundary-specific fields.

```json
"catchup": {
  "scanRange": {
    "start": "earliest-arness-artifact-date",
    "end": "earliest-arness-artifact-date"
  },
  "coveredCommits": [],
  "confidence": "low",
  "gaps": ["All commits before this point predate Arness tracking"],
  "whatWeKnow": "N commits exist before Arness tracking began at <hash>",
  "whatWeDontKnow": "Intent, testing status, and architectural reasoning for all pre-Arness commits",
  "groupingTheme": null,
  "boundaryMarker": true,
  "preArnessCommitCount": 42,
  "boundaryCommitHash": "<hash>"
}
```

### Additional Boundary Fields

| Field | Type | Description |
|-------|------|-------------|
| `preArnessCommitCount` | number | Total number of commits that predate Arness tracking |
| `boundaryCommitHash` | string | The commit hash of the earliest Arness-tracked commit (the boundary point) |

---

## Markdown Summary

Each CATCHUP_ directory also contains a `CATCHUP_<name>.md` markdown file providing a human-readable summary using the "What We Know / What We Don't Know" framing.

### Format

```markdown
# Catch-Up: <name>

**Generated:** <ISO 8601 timestamp>
**Commits covered:** <count>
**Confidence:** low

## What We Know

- Files modified: <list>
- Commit message(s): <quoted message(s)>
- Diff stats: <insertions/deletions summary>
- Author: <git author>
- Date range: <earliest commit date> to <latest commit date>

## What We Don't Know

- Intent behind the change
- Whether tests were run or passed
- Architectural reasoning or trade-offs considered
- Whether this change was reviewed by anyone
- Impact on existing patterns or conventions

## Gaps

<bulleted list from the `gaps` array>

## Covered Commits

| Hash | Date | Message |
|------|------|---------|
| <short hash> | <date> | <subject> |
```

### Boundary Marker Markdown

For boundary markers, the markdown uses a simplified format:

```markdown
# Arness Tracking Boundary

**Generated:** <ISO 8601 timestamp>
**Pre-Arness commits:** <count>
**Boundary commit:** <hash>

## Summary

<count> commits exist in this repository before Arness tracking began.
Arness tracking started at commit <hash> on <date>.

All commits before this point are undocumented by the Arness pipeline.
This boundary marker exists to acknowledge their presence without
fabricating documentation about their intent or quality.
```

---

## Directory Structure

Each catch-up record produces a directory under the plans directory:

```
<plans-dir>/CATCHUP_<name>/
  CATCHUP_<name>.md    (what we know / what we don't know summary)
  CHANGE_RECORD.json   (unified change envelope with catchup extension)
```

The `<name>` is derived from:
- **Individual records:** The commit's primary theme (e.g., `fix-auth-headers`, `add-logging`)
- **Grouped records:** The group theme name (e.g., `api-cleanup`, `deps-updates`)
- **Summary records:** A date range (e.g., `catchup-2026-03-01-to-2026-03-29`)
- **Boundary markers:** `pre-arness-boundary`
