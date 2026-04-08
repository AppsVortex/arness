# CLI Registry

Curated registry of known infrastructure CLIs with detection commands, auth-check commands, and install instructions per OS.

---

## Provider CLIs

### AWS CLI
- **Binary:** `aws`
- **Provider:** AWS
- **Official:** Yes
- **Detection command:** `aws --version`
- **Auth-check command:** `aws sts get-caller-identity`
- **Structured output:** `--output json` (also `text`, `table`, `yaml`)
- **Install (macOS):** `brew install awscli`
- **Install (Linux):** `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && sudo ./aws/install`
- **Install (generic):** `pip install awscli`
- **What it enables vs MCP:** Required for `tofu plan/apply` operations -- MCP covers resource CRUD but not IaC state management. Also needed for ECR login, S3 sync, and CloudFormation operations.

### Google Cloud SDK (gcloud)
- **Binary:** `gcloud`
- **Provider:** GCP
- **Official:** Yes
- **Detection command:** `gcloud --version`
- **Auth-check command:** `gcloud auth list --filter=status:ACTIVE --format="value(account)"`
- **Structured output:** `--format=json`
- **Install (macOS):** `brew install google-cloud-sdk`
- **Install (Linux):** `curl https://sdk.cloud.google.com | bash`
- **Install (generic):** `snap install google-cloud-cli --classic`
- **What it enables vs MCP:** Required for GKE cluster management, Cloud Run deployments, and `gcloud builds submit`. Needed for service account key management.

### Azure CLI
- **Binary:** `az`
- **Provider:** Azure
- **Official:** Yes
- **Detection command:** `az --version`
- **Auth-check command:** `az account show`
- **Structured output:** `--output json` (default)
- **Install (macOS):** `brew install azure-cli`
- **Install (Linux):** `curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash`
- **Install (generic):** `pip install azure-cli`
- **What it enables vs MCP:** Required for AKS management, Azure Container Registry, and Bicep deployments. Needed for RBAC and subscription management.

### DigitalOcean CLI (doctl)
- **Binary:** `doctl`
- **Provider:** DigitalOcean
- **Official:** Yes
- **Detection command:** `doctl version`
- **Auth-check command:** `doctl account get`
- **Structured output:** `--output json`
- **Install (macOS):** `brew install doctl`
- **Install (Linux):** `snap install doctl`
- **Install (generic):** Download from https://github.com/digitalocean/doctl/releases
- **What it enables vs MCP:** Droplet management, DOKS cluster access, Spaces operations, and App Platform deployments.

### Fly.io CLI (flyctl)
- **Binary:** `fly`
- **Provider:** Fly.io
- **Official:** Yes
- **Detection command:** `fly version`
- **Auth-check command:** `fly auth whoami`
- **Structured output:** `--json` flag on most commands
- **Install (macOS):** `brew install flyctl`
- **Install (Linux):** `curl -L https://fly.io/install.sh | sh`
- **Install (generic):** Same as Linux
- **What it enables vs MCP:** Required for `fly deploy`, `fly postgres`, and machine management. Primary deployment tool for Fly.io.

### Vercel CLI
- **Binary:** `vercel`
- **Provider:** Vercel
- **Official:** Yes
- **Detection command:** `vercel --version`
- **Auth-check command:** `vercel whoami`
- **Structured output:** Limited JSON support
- **Install (macOS/Linux/generic):** `npm install -g vercel`
- **What it enables vs MCP:** Local deployment (`vercel deploy`), project linking, environment variable management. MCP provides similar coverage.

### Netlify CLI
- **Binary:** `netlify`
- **Provider:** Netlify
- **Official:** Yes
- **Detection command:** `netlify --version`
- **Auth-check command:** `netlify status`
- **Structured output:** `--json` flag
- **Install (macOS/Linux/generic):** `npm install -g netlify-cli`
- **What it enables vs MCP:** Site deployment, build configuration, serverless functions, and edge functions management.

### Railway CLI
- **Binary:** `railway`
- **Provider:** Railway
- **Official:** Yes
- **Detection command:** `railway version`
- **Auth-check command:** `railway whoami`
- **Structured output:** Limited
- **Install (macOS):** `brew install railway`
- **Install (Linux/generic):** `npm install -g @railway/cli`
- **What it enables:** Required for `railway up` deployments, service management, and environment variable configuration.

### Scaleway CLI
- **Binary:** `scw`
- **Provider:** Scaleway
- **Official:** Yes
- **Detection command:** `scw version`
- **Auth-check command:** `scw account project list`
- **Structured output:** `--output=json`
- **Install (macOS):** `brew install scw`
- **Install (Linux):** Download from https://github.com/scaleway/scaleway-cli/releases
- **What it enables:** Instance management, Kubernetes (Kapsule), object storage, and managed database operations.

### Cloudflare Wrangler
- **Binary:** `wrangler`
- **Provider:** Cloudflare
- **Official:** Yes
- **Detection command:** `wrangler --version`
- **Auth-check command:** `wrangler whoami`
- **Structured output:** Limited
- **Install (macOS/Linux/generic):** `npm install -g wrangler`
- **What it enables vs MCP:** Workers development and deployment, R2 operations, KV management. MCP provides similar coverage for production operations.

### Render CLI
- **Binary:** `render`
- **Provider:** Render
- **Official:** Yes (limited)
- **Detection command:** `render --version`
- **Auth-check command:** `render auth status` (if available)
- **Structured output:** Limited
- **Install:** `npm install -g @render/cli` (or download from https://render.com/docs/cli)
- **What it enables:** Service management and deployment triggers. Blueprint-based deployment via `render.yaml` is the primary method.

---

## IaC Tool CLIs

### OpenTofu
- **Binary:** `tofu`
- **Detection command:** `tofu --version`
- **Install (macOS):** `brew install opentofu`
- **Install (Linux):** See https://opentofu.org/docs/intro/install/
- **Install (generic):** `curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh`
- **Required for:** All OpenTofu IaC workflows. Blocks `arn-infra-define` if missing and IaC tool is `opentofu`.

### Terraform
- **Binary:** `terraform`
- **Detection command:** `terraform --version`
- **Install (macOS):** `brew install terraform`
- **Install (Linux):** See https://developer.hashicorp.com/terraform/install
- **Note:** BSL licensed. Recommend OpenTofu instead.

### Pulumi
- **Binary:** `pulumi`
- **Detection command:** `pulumi version`
- **Install (macOS):** `brew install pulumi`
- **Install (Linux):** `curl -fsSL https://get.pulumi.com | sh`

### AWS CDK
- **Binary:** `cdk`
- **Detection command:** `cdk --version`
- **Install (macOS/Linux/generic):** `npm install -g aws-cdk`

---

## Validation and Security Tool CLIs

### Checkov
- **Binary:** `checkov`
- **Detection command:** `checkov --version`
- **Install:** `pip install checkov` or `brew install checkov`
- **Purpose:** IaC policy scanning (OpenTofu, Terraform, CloudFormation, Kubernetes, Docker)

### Trivy
- **Binary:** `trivy`
- **Detection command:** `trivy --version`
- **Install (macOS):** `brew install trivy`
- **Install (Linux):** `sudo apt-get install trivy` or download from https://github.com/aquasecurity/trivy/releases
- **Purpose:** Vulnerability and misconfiguration scanning for containers and IaC

### Infracost
- **Binary:** `infracost`
- **Detection command:** `infracost --version`
- **Install (macOS):** `brew install infracost`
- **Install (Linux):** `curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh`
- **Purpose:** Cloud cost estimation for IaC changes

### TruffleHog
- **Binary:** `trufflehog`
- **Detection command:** `trufflehog --version`
- **Install (macOS):** `brew install trufflehog`
- **Install (Linux):** Download from https://github.com/trufflesecurity/trufflehog/releases
- **Purpose:** Secret detection in code and git history

### Gitleaks
- **Binary:** `gitleaks`
- **Detection command:** `gitleaks version`
- **Install (macOS):** `brew install gitleaks`
- **Install (Linux):** Download from https://github.com/gitleaks/gitleaks/releases
- **Purpose:** Secret detection focused on git repositories
