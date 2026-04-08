# IaC Tool Guide

Detailed reference for all supported Infrastructure-as-Code tools. Each entry includes what the tool generates, file extensions, state management, provider support, expertise level suitability, and key considerations.

---

## OpenTofu (Recommended)

- **License:** MPL 2.0 (open source, CNCF Sandbox project)
- **Generates:** HCL configuration files
- **File extensions:** `.tf`, `.tfvars`
- **State management:** Remote backends (S3, GCS, Azure Blob, PostgreSQL, HTTP), local state, OpenTofu Cloud (future)
- **Provider support:** All major providers via the OpenTofu Registry (fork of Terraform Registry, full compatibility)
- **CLI:** `tofu init`, `tofu plan`, `tofu apply`, `tofu destroy`
- **Expertise suitability:** Intermediate, Expert
- **Description:** OpenTofu is the community-maintained open-source fork of Terraform, created after HashiCorp changed Terraform's license to BSL. It is a drop-in replacement -- existing `.tf` files and state work without modification. OpenTofu is the recommended IaC tool for Arness Infra due to its open-source license, active CNCF governance, and full Terraform compatibility.

---

## Terraform

- **License:** BSL 1.1 (Business Source License -- NOT open source as of August 2023)
- **Generates:** HCL configuration files
- **File extensions:** `.tf`, `.tfvars`
- **State management:** Terraform Cloud (paid), remote backends (S3, GCS, Azure Blob), local state
- **Provider support:** All major providers via the Terraform Registry
- **CLI:** `terraform init`, `terraform plan`, `terraform apply`, `terraform destroy`
- **Expertise suitability:** Intermediate, Expert

**WARNING: Terraform License Change**

HashiCorp changed Terraform's license from MPL 2.0 to BSL 1.1 in August 2023. Key implications:
- **Not open source.** BSL restricts commercial use in competing products.
- **OSS (open-source Terraform) discontinued** in July 2025.
- **Per-resource pricing** introduced for Terraform Cloud/Enterprise.
- **Free tier eliminated** for Terraform Cloud managed workflows.

**Recommendation:** Use OpenTofu instead. It is a drop-in replacement with the same HCL syntax, same providers, and an open-source license. Migration is straightforward:
1. Replace `terraform` with `tofu` in all commands
2. Update CI/CD pipelines to use `opentofu/setup-opentofu` instead of `hashicorp/setup-terraform`
3. State files are compatible -- no state migration needed

If you have existing Terraform workflows and choose to continue using it, Arness Infra will generate compatible configs but will display this warning during init.

---

## Terragrunt

- **License:** MIT
- **Generates:** HCL wrapper configs (`terragrunt.hcl`) around OpenTofu/Terraform modules
- **File extensions:** `terragrunt.hcl`
- **State management:** Delegates to OpenTofu/Terraform backends
- **Provider support:** Same as OpenTofu/Terraform (Terragrunt is a wrapper)
- **CLI:** `terragrunt plan`, `terragrunt apply`, `terragrunt run-all plan`
- **Expertise suitability:** Expert
- **Description:** Terragrunt is a thin wrapper that provides DRY configuration, remote state management, and dependency orchestration for OpenTofu/Terraform. Set `TERRAGRUNT_TFPATH=tofu` to use with OpenTofu. Best for managing multiple environments or modules with shared configuration.

---

## Pulumi

- **License:** Apache 2.0
- **Generates:** Infrastructure code in general-purpose languages (TypeScript, Python, Go, Java, C#, YAML)
- **File extensions:** Varies by language (`.ts`, `.py`, `.go`, etc.) + `Pulumi.yaml`, `Pulumi.<stack>.yaml`
- **State management:** Pulumi Cloud (free tier available), self-managed backends (S3, Azure Blob, GCS, local)
- **Provider support:** All major providers via Pulumi Registry
- **CLI:** `pulumi up`, `pulumi preview`, `pulumi destroy`
- **Expertise suitability:** Intermediate (if familiar with the language), Expert
- **Description:** Pulumi uses real programming languages instead of domain-specific HCL. This enables loops, conditionals, type checking, and IDE support natively. Good for teams that prefer their application language for infrastructure.

---

## AWS CDK (Cloud Development Kit)

- **License:** Apache 2.0
- **Generates:** CloudFormation templates from TypeScript/Python/Go/Java/C# code
- **File extensions:** Varies by language + `cdk.json`
- **State management:** CloudFormation stacks (managed by AWS)
- **Provider support:** AWS only
- **CLI:** `cdk deploy`, `cdk synth`, `cdk diff`, `cdk destroy`
- **Expertise suitability:** Intermediate (AWS), Expert
- **Description:** AWS-specific IaC using general-purpose languages. Synthesizes to CloudFormation. Best for AWS-only deployments where teams prefer code over HCL. Constructs provide high-level abstractions that reduce boilerplate.

---

## Azure Bicep

- **License:** MIT
- **Generates:** ARM template JSON from Bicep DSL
- **File extensions:** `.bicep`, `.bicepparam`
- **State management:** Azure Resource Manager (managed by Azure)
- **Provider support:** Azure only
- **CLI:** `az bicep build`, `az deployment group create`
- **Expertise suitability:** Intermediate (Azure), Expert
- **Description:** Azure-specific DSL that compiles to ARM templates. Significantly more readable than raw ARM JSON. Native Azure CLI integration. Best for Azure-only deployments.

---

## kubectl / Helm

- **License:** Apache 2.0
- **Generates:** Kubernetes YAML manifests (kubectl) or Helm charts (YAML templates + values)
- **File extensions:** `.yaml`, `.yml`, `Chart.yaml`, `values.yaml`
- **State management:** Kubernetes API server (cluster state)
- **Provider support:** Any Kubernetes cluster (EKS, GKE, AKS, self-managed)
- **CLI:** `kubectl apply`, `helm install`, `helm upgrade`
- **Expertise suitability:** Expert
- **Description:** Direct Kubernetes resource management. kubectl uses plain YAML manifests. Helm adds templating, packaging, and release management. Assumes a Kubernetes cluster already exists (created via IaC or managed service).

---

## No IaC (Platform-Native Configs)

- **License:** N/A
- **Generates:** Platform-specific configuration files
- **File extensions:** `fly.toml`, `railway.json`, `render.yaml`, `vercel.json`, `netlify.toml`
- **State management:** Managed by the PaaS provider
- **Provider support:** Individual PaaS providers only
- **CLI:** `fly deploy`, `railway up`, `vercel deploy`, `netlify deploy`
- **Expertise suitability:** Beginner, Intermediate
- **Description:** For PaaS providers (Fly.io, Railway, Render, Vercel, Netlify), traditional IaC is unnecessary. These platforms use simple config files that define the deployment without managing low-level cloud resources. This is the recommended approach for beginners -- it abstracts away infrastructure complexity while remaining version-controlled and reproducible.

---

## Tool Selection Summary

| Tool | Best For | Experience Level | Multi-Provider |
|------|----------|-----------------|----------------|
| OpenTofu | General-purpose IaC | Intermediate, Expert | Yes (all providers) |
| Terraform | Legacy/existing setups | Intermediate, Expert | Yes (all providers) |
| Terragrunt | Multi-env OpenTofu/TF | Expert | Yes (via OpenTofu/TF) |
| Pulumi | Code-first teams | Intermediate, Expert | Yes (all providers) |
| AWS CDK | AWS-only, code-first | Intermediate, Expert | AWS only |
| Azure Bicep | Azure-only | Intermediate, Expert | Azure only |
| kubectl/Helm | Kubernetes workloads | Expert | Any K8s cluster |
| Platform-native | Simple PaaS deploys | Beginner, Intermediate | Single PaaS |
