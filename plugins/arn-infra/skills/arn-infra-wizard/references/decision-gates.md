# Quick Mode Decision Gates

### Gate Q1: Resume Detection

**When:** Entry, after artifact detection finds existing progress.

**Question:** "It looks like you have an in-progress infrastructure pipeline at [detected stage]. Resume from there, or start fresh?"

**Options:**
1. **Resume from [detected stage]** -- Skip to the detected resume point
2. **Start fresh** -- Begin at discover (do not delete existing artifacts)

**If no artifacts detected:** Skip Q1 and proceed directly to discover.

### Gate Q1.5: Tool Installation

**When:** After discover completes, if the tooling manifest shows recommended tools that are not installed.

**Question:** "The discovery audit found [N] recommended tools that are not installed: [list]. Would you like to install them now?"

**Options:**
1. **Install recommended tools** -- Attempt installation via the methods suggested by discover
2. **Skip** -- Continue without installing (some features may be limited)

**Note:** This gate only appears if discover identified missing recommended tools. The discover skill itself presents recommendations; this gate is a wizard-level confirmation to act on them.

### Gate Q2: Containerize Decision

**When:** Before containerize step.

**Question:** "Ready to set up containerization (Dockerfiles, docker-compose)?"

**Options:**
1. **Yes, containerize** (Recommended) -- Generate container configurations
2. **Skip** -- Proceed to infrastructure definition without containerization (suitable for serverless or PaaS deployments)

### Gate Q3: Deploy Level

**When:** After define completes, before deploy.

**Question:** "Infrastructure code is ready. What deployment scope?"

**Options:**
1. **Deploy to staging** (Recommended if staging environment exists) -- Deploy to the first non-production environment
2. **Deploy to production** -- Deploy directly to production (warning shown if staging exists but is unused)
3. **Dry run only** -- Run the deployment in dry-run mode to preview changes without applying
4. **Skip deployment** -- Continue to verification and CI/CD setup without deploying

### Gate Q4: Verify and CI/CD

**When:** After deploy completes (or after define if deploy was skipped).

**Question:** "Deployment complete. Set up verification and CI/CD?"

**Options:**
1. **Verify then set up CI/CD** (Recommended) -- Run verification checks, then generate CI/CD pipelines
2. **Verify only** -- Run verification without CI/CD setup
3. **CI/CD only** -- Set up pipelines without post-deployment verification
4. **Skip both** -- Continue to environment management

### Gate Q5: Environments

**When:** After verify/pipeline steps complete. **Expert/Intermediate only.**

**Question:** "Set up environment management (isolation, promotion pipeline)?"

**Options:**
1. **Yes** (Recommended) -- Configure environment isolation and promotion rules
2. **Skip** -- Continue to secrets management

### Gate Q6: Secrets and Monitoring

**When:** After env step completes. **Expert/Intermediate only.**

**Question:** "Set up secrets management and monitoring?"

**Options:**
1. **Both** (Recommended) -- Set up secrets management and observability
2. **Secrets only** -- Configure secrets management without monitoring
3. **Monitoring only** -- Set up observability without secrets management
4. **Skip both** -- Proceed to completion

### Gate Q7: Completion Summary

**When:** All selected steps are complete.

No question -- this is a summary gate. Present the completion summary and next steps.
