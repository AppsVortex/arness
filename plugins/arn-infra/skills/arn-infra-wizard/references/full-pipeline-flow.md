# Full Pipeline Mode Flow

When the user selects Full Pipeline mode, the wizard sequences 6 pipeline skills with gates P1-P6. Each gate invokes one pipeline skill and presents the result before proceeding.

### Gate P1: Change Specification

Show progress:
```
Infra Pipeline (Full): CHANGE-SPEC --> change-plan --> save-plan --> execute --> review --> document
                        ^^^^^^^^^^^
```

Inform the user: "Creating a structured change specification..."

> `Skill: arn-infra:arn-infra-change-spec`

When change-spec completes, the spec file exists in `.arness/infra-specs/`. Proceed to P2.

### Gate P2: Change Planning

Show progress:
```
Infra Pipeline (Full): change-spec --> CHANGE-PLAN --> save-plan --> execute --> review --> document
                                       ^^^^^^^^^^^
```

Inform the user: "Generating an infrastructure change plan from the specification..."

> `Skill: arn-infra:arn-infra-change-plan`

When change-plan completes, the plan preview exists in `.arness/infra-plans/`. Proceed to P3.

### Gate P3: Save Plan

Show progress:
```
Infra Pipeline (Full): change-spec --> change-plan --> SAVE-PLAN --> execute --> review --> document
                                                       ^^^^^^^^^
```

Inform the user: "Structuring and saving the change plan..."

> `Skill: arn-infra:arn-infra-save-plan`

When save-plan completes, the structured plan directory exists in `.arness/infra-plans/`. Proceed to P4.

### Gate P4: Execute Change

Show progress:
```
Infra Pipeline (Full): change-spec --> change-plan --> save-plan --> EXECUTE --> review --> document
                                                                     ^^^^^^^
```

Inform the user: "Executing the infrastructure change plan..."

> `Skill: arn-infra:arn-infra-execute-change`

When execute-change completes, infrastructure changes have been applied. Proceed to P5.

### Gate P5: Review Change

Show progress:
```
Infra Pipeline (Full): change-spec --> change-plan --> save-plan --> execute --> REVIEW --> document
                                                                                 ^^^^^^
```

Inform the user: "Reviewing the executed infrastructure changes..."

> `Skill: arn-infra:arn-infra-review-change`

When review-change completes, the review report is available. Proceed to P6.

### Gate P6: Document Change

Show progress:
```
Infra Pipeline (Full): change-spec --> change-plan --> save-plan --> execute --> review --> DOCUMENT
                                                                                           ^^^^^^^^
```

Inform the user: "Documenting the infrastructure change..."

> `Skill: arn-infra:arn-infra-document-change`

When document-change completes, runbooks and changelogs have been generated. Show the Full Pipeline completion summary.

### Full Pipeline Completion Summary

Show final progress:
```
Infra Pipeline (Full): change-spec --> change-plan --> save-plan --> execute --> review --> document
                            ✓               ✓             ✓           ✓          ✓           ✓
```

Present a completion summary:

- **Mode:** Full Pipeline
- **Change specification:** `[spec file path]`
- **Change plan:** `[plan directory path]`
- **Execution:** [completed / partial]
- **Review:** [PASS / WARN / FAIL]
- **Documentation:** [runbooks, changelogs generated]

**Next steps:**
- "Run `/arn-infra-wizard` again to start a new change pipeline"
- "Run `/arn-infra-help` to check your pipeline position"
- "Run `/arn-infra-deploy` to deploy to additional environments"
