# Validation Ladder

Multi-level validation framework for infrastructure-as-code. Each level builds on the previous, adding more confidence at the cost of more time and potentially cloud API calls. The validation ceiling in `## Arness` config determines the maximum level Arness runs without explicit approval.

---

## Level Definitions

### Level 0: Static Analysis (Always Run)

**What it does:** Validates syntax, configuration correctness, and module references without contacting any cloud API.

**Time cost:** Seconds
**Cloud cost:** None
**Network required:** No (except provider plugin downloads on first run)

**Tools by IaC engine:**

| IaC Tool | Command | What It Validates |
|----------|---------|-------------------|
| OpenTofu / Terraform | `tofu validate` | HCL syntax, variable references, provider schema |
| Pulumi | Type checking via compiler | TypeScript/Python type errors, import resolution |
| CDK | `cdk synth` | TypeScript compilation, construct validation, CloudFormation synthesis |
| Bicep | `az bicep build` | Bicep syntax, type checking, ARM template compilation |
| Kubernetes | `kubectl apply --dry-run=client` | YAML syntax, API schema validation (offline) |
| Helm | `helm lint` | Chart structure, template syntax, values validation |
| PaaS configs | Schema validation (JSON Schema, TOML parsing) | Config file structure and required fields |

**Failure at Level 0:** Always blocks. Syntax errors must be fixed before proceeding.

---

### Level 1: Local Validation (Ceiling >= 1)

**What it does:** Checks formatting, linting rules, module dependency resolution, and best practice compliance. May download provider plugins but does not authenticate or contact cloud APIs.

**Time cost:** Seconds to minutes
**Cloud cost:** None
**Network required:** Yes (for provider plugin downloads)

**Tools by IaC engine:**

| IaC Tool | Commands | What They Validate |
|----------|----------|-------------------|
| OpenTofu / Terraform | `tofu fmt -check -recursive`, `tflint` | Code formatting, naming conventions, deprecated features |
| Pulumi | Linter (ESLint/Ruff), `pulumi preview --diff` (local) | Code style, unused variables, preview dependency graph |
| CDK | `eslint`, `cdk diff` (against synthesized) | Code style, construct best practices |
| Bicep | `az bicep lint` | Best practice rules, parameter validation |
| Kubernetes | `kubectl apply --dry-run=server` | Full API validation against cluster schema |
| Helm | `helm template` + `kubectl apply --dry-run=client` | Rendered manifest validation |

**Additional checks at Level 1:**
- Variable completeness: all required variables have values for the target environment
- Module references: all module sources are reachable and version-pinned
- Provider version compatibility: provider versions are compatible with the IaC engine version

**Failure at Level 1:** Warns but does not block. Formatting and linting issues are advisory.

---

### Level 2: Security Scan and Cost Estimation (Ceiling >= 2)

**What it does:** Runs security scanning tools on the generated IaC and estimates cloud costs. This is the first level that provides cost awareness.

**Time cost:** Minutes
**Cloud cost:** None (scanning tools are free; cost estimation uses public pricing data)
**Network required:** Yes

**Security scanning tools:**

| Tool | What It Scans | Install |
|------|---------------|---------|
| Checkov | IaC misconfigurations (500+ policies) | `pip install checkov` |
| Trivy | IaC misconfigurations, container vulnerabilities | `brew install trivy` |
| tfsec (legacy, merged into Trivy) | Terraform/OpenTofu-specific security | Use Trivy instead |
| KICS | Multi-framework IaC scanning | `docker run checkmarx/kics` |

**Cost estimation tools:**

| Tool | What It Estimates | Install |
|------|-------------------|---------|
| Infracost | Per-resource monthly cost based on IaC plan | `brew install infracost` |
| Manual estimation | Agent-based estimation from public pricing pages | Built-in (no install) |

**Security scan process:**
1. Run the available scanning tool on the generated IaC files
2. Categorize findings: Critical, High, Medium, Low
3. Auto-fix High and Critical findings if possible
4. Present remaining findings with remediation guidance

**Cost estimation process:**
1. If Infracost is available: run `infracost breakdown --path .`
2. If Infracost is not available: invoke the `arn-infra-cost-analyst` agent for manual estimation
3. Compare the estimate against the configured cost threshold
4. If the estimate exceeds the threshold: present a cost gate warning

**Failure at Level 2:**
- Security Critical findings: block deployment, require remediation
- Security High findings: warn, recommend remediation before deployment
- Cost threshold exceeded: warn, require explicit acknowledgment
- Security Medium/Low: informational, do not block

---

### Level 3: Cloud Dry-Run (Ceiling >= 3)

**What it does:** Performs a cloud API dry-run that contacts the cloud provider to validate resource creation without actually creating resources.

**Time cost:** Minutes
**Cloud cost:** None (dry-run API calls are free for most providers)
**Network required:** Yes
**Authentication required:** Yes (cloud provider credentials)

**Commands by IaC engine:**

| IaC Tool | Command | What It Validates |
|----------|---------|-------------------|
| OpenTofu / Terraform | `tofu plan` | Full resource graph, API compatibility, quota checks |
| Pulumi | `pulumi preview` | Full resource graph, API compatibility |
| CDK | `cdk deploy --dry-run` (via CloudFormation changeset) | CloudFormation validation, resource compatibility |
| Bicep | `az deployment group what-if` | ARM deployment simulation |
| Kubernetes | `kubectl apply --dry-run=server` | Full API server validation, admission webhooks |
| Helm | `helm install --dry-run --debug` | Server-side template rendering and validation |

**Additional checks at Level 3:**
- Resource quotas: will the deployment exceed account quotas?
- IAM permissions: does the authenticated identity have permission to create the resources?
- Resource conflicts: do any resources already exist with conflicting names?
- Region availability: are the requested resource types available in the target region?

**Failure at Level 3:** Blocks deployment. Cloud dry-run failures indicate real deployment problems.

---

### Level 4: Full Apply (Ceiling >= 4)

**What it does:** Actually deploys the infrastructure. This is not a validation step -- it is the deployment itself. At this level, the validation ceiling has no practical effect (the user has approved full deployment).

**Time cost:** Minutes to hours (depending on resources)
**Cloud cost:** Real cloud charges begin
**Network required:** Yes
**Authentication required:** Yes

**Important:** Level 4 is typically handled by the `arn-infra-deploy` skill, not `arn-infra-define`. The define skill generates and validates code up to Level 3. The deploy skill handles the actual apply.

---

## Decision Framework

### Choosing the Default Validation Ceiling

| Experience Level | Recommended Ceiling | Rationale |
|-----------------|--------------------|-----------|
| Beginner | 1 | Security scans may be confusing; focus on getting syntax right |
| Intermediate | 2 | Security and cost awareness without cloud API interaction |
| Expert | 3 | Full dry-run for confidence before deployment |

### When to Exceed the Ceiling

The user should be prompted to exceed the ceiling when:
- Moving from staging to production (suggest Level 3 minimum)
- First-time deployment to a new provider
- Major infrastructure changes (new services, networking changes)
- Cost-sensitive deployments

### When NOT to Exceed the Ceiling

- Minor configuration changes (environment variable updates)
- Well-established patterns being applied to a new environment
- Development environment deployments with low risk

---

## Validation Report Format

After running the validation ladder, present results in this format:

```
## Validation Results

### Level 0: Static Analysis
- Status: PASSED / FAILED
- Details: [summary of checks performed]
- Issues: [list if any]

### Level 1: Local Validation
- Status: PASSED / WARNINGS / SKIPPED
- Formatting: [N files checked, N issues]
- Linting: [N rules checked, N violations]

### Level 2: Security Scan + Cost Estimation
- Status: PASSED / WARNINGS / BLOCKED
- Security: [Critical: N, High: N, Medium: N, Low: N]
- Cost estimate: $X.XX/month
- Cost threshold: $Y.YY/month
- Cost gate: PASSED / EXCEEDED

### Level 3: Cloud Dry-Run
- Status: PASSED / FAILED / SKIPPED
- Resources to create: N
- Resources to modify: N
- Resources to destroy: N
- Quota warnings: [list if any]
```

---

## Tool Availability Fallback

If the preferred validation tool is not installed, fall back to the next available option:

| Missing Tool | Fallback |
|-------------|----------|
| `checkov` / `trivy` | Agent-based security review (manual analysis of IaC patterns) |
| `infracost` | Agent-based cost estimation from public pricing data |
| `tflint` | Skip Level 1 linting, proceed to Level 2 |
| Provider CLI (for dry-run) | Skip Level 3, note that cloud validation was not possible |

When falling back, note the limitation in the validation report: "Level [N] used fallback: [tool] was not available. Install it for more accurate validation."
