# Pulumi Patterns

Project structure, stack configuration, typed outputs, and idiomatic patterns for Pulumi infrastructure-as-code. Pulumi uses general-purpose programming languages (TypeScript, Python, Go, C#, Java) instead of a domain-specific language.

---

## Project Structure

### Single-Project (Simple)

```
infra/
├── Pulumi.yaml           # Project metadata (name, runtime, description)
├── Pulumi.dev.yaml       # Stack config for dev environment
├── Pulumi.staging.yaml   # Stack config for staging environment
├── Pulumi.prod.yaml      # Stack config for production environment
├── index.ts              # Main program (TypeScript)
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript configuration
└── node_modules/
```

### Multi-Project (Recommended for larger systems)

```
infra/
├── networking/
│   ├── Pulumi.yaml
│   ├── Pulumi.dev.yaml
│   ├── Pulumi.prod.yaml
│   └── index.ts
├── database/
│   ├── Pulumi.yaml
│   ├── Pulumi.dev.yaml
│   ├── Pulumi.prod.yaml
│   └── index.ts
├── app/
│   ├── Pulumi.yaml
│   ├── Pulumi.dev.yaml
│   ├── Pulumi.prod.yaml
│   └── index.ts
└── shared/
    ├── package.json
    └── src/
        ├── tags.ts       # Shared tagging logic
        └── config.ts     # Shared configuration helpers
```

---

## Pulumi.yaml (Project File)

```yaml
name: myproject-infra
runtime:
  name: nodejs
  options:
    typescript: true
description: Infrastructure for MyProject
```

---

## Stack Configuration

### Pulumi.dev.yaml

```yaml
config:
  aws:region: us-east-1
  myproject-infra:environment: dev
  myproject-infra:instanceType: t3.micro
  myproject-infra:dbInstanceClass: db.t3.micro
  myproject-infra:minInstances: "1"
  myproject-infra:maxInstances: "2"
```

### Pulumi.prod.yaml

```yaml
config:
  aws:region: us-east-1
  myproject-infra:environment: prod
  myproject-infra:instanceType: t3.medium
  myproject-infra:dbInstanceClass: db.r6g.large
  myproject-infra:minInstances: "2"
  myproject-infra:maxInstances: "10"
```

### Secrets in Config

```bash
# Set a secret (encrypted in the stack config file)
pulumi config set --secret dbPassword "my-secret-password"
```

```yaml
# In Pulumi.prod.yaml -- value is encrypted
config:
  myproject-infra:dbPassword:
    secure: AAABADQHNKz...
```

---

## TypeScript Patterns

### Main Program (index.ts)

```typescript
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const config = new pulumi.Config();
const environment = config.require("environment");
const projectName = pulumi.getProject();

// Common tags
const commonTags = {
  Project: projectName,
  Environment: environment,
  ManagedBy: "pulumi",
};

// VPC
const vpc = new aws.ec2.Vpc("main", {
  cidrBlock: "10.0.0.0/16",
  enableDnsHostnames: true,
  enableDnsSupport: true,
  tags: { ...commonTags, Name: `${projectName}-${environment}-vpc` },
});

// Database
const dbPassword = config.requireSecret("dbPassword");

const db = new aws.rds.Instance("main", {
  identifier: `${projectName}-${environment}-db`,
  engine: "postgres",
  engineVersion: "16",
  instanceClass: config.require("dbInstanceClass"),
  dbName: "appdb",
  username: "app",
  password: dbPassword,
  allocatedStorage: 20,
  vpcSecurityGroupIds: [dbSecurityGroup.id],
  dbSubnetGroupName: dbSubnetGroup.name,
  backupRetentionPeriod: environment === "prod" ? 30 : 7,
  skipFinalSnapshot: environment !== "prod",
  deletionProtection: environment === "prod",
  tags: commonTags,
});

// Exports
export const vpcId = vpc.id;
export const dbEndpoint = db.endpoint;
export const dbName = db.dbName;
```

### Component Resource Pattern

```typescript
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

interface AppServiceArgs {
  vpcId: pulumi.Input<string>;
  subnetIds: pulumi.Input<string>[];
  containerImage: string;
  containerPort: number;
  environment: string;
  tags: Record<string, string>;
}

class AppService extends pulumi.ComponentResource {
  public readonly url: pulumi.Output<string>;
  public readonly serviceName: pulumi.Output<string>;

  constructor(name: string, args: AppServiceArgs, opts?: pulumi.ComponentResourceOptions) {
    super("custom:app:AppService", name, {}, opts);

    const cluster = new aws.ecs.Cluster(`${name}-cluster`, {
      tags: args.tags,
    }, { parent: this });

    const taskDef = new aws.ecs.TaskDefinition(`${name}-task`, {
      family: name,
      networkMode: "awsvpc",
      requiresCompatibilities: ["FARGATE"],
      cpu: "256",
      memory: "512",
      containerDefinitions: JSON.stringify([{
        name: "app",
        image: args.containerImage,
        portMappings: [{
          containerPort: args.containerPort,
          protocol: "tcp",
        }],
        essential: true,
      }]),
      tags: args.tags,
    }, { parent: this });

    const service = new aws.ecs.Service(`${name}-service`, {
      cluster: cluster.arn,
      taskDefinition: taskDef.arn,
      desiredCount: 1,
      launchType: "FARGATE",
      networkConfiguration: {
        subnets: args.subnetIds,
        assignPublicIp: false,
      },
      tags: args.tags,
    }, { parent: this });

    this.serviceName = service.name;
    this.url = pulumi.interpolate`http://${name}.internal`;

    this.registerOutputs({
      url: this.url,
      serviceName: this.serviceName,
    });
  }
}
```

---

## Python Patterns

### Main Program (__main__.py)

```python
import pulumi
import pulumi_aws as aws

config = pulumi.Config()
environment = config.require("environment")
project_name = pulumi.get_project()

common_tags = {
    "Project": project_name,
    "Environment": environment,
    "ManagedBy": "pulumi",
}

vpc = aws.ec2.Vpc("main",
    cidr_block="10.0.0.0/16",
    enable_dns_hostnames=True,
    enable_dns_support=True,
    tags={**common_tags, "Name": f"{project_name}-{environment}-vpc"},
)

db_password = config.require_secret("dbPassword")

db = aws.rds.Instance("main",
    identifier=f"{project_name}-{environment}-db",
    engine="postgres",
    engine_version="16",
    instance_class=config.require("dbInstanceClass"),
    db_name="appdb",
    username="app",
    password=db_password,
    allocated_storage=20,
    tags=common_tags,
)

pulumi.export("vpc_id", vpc.id)
pulumi.export("db_endpoint", db.endpoint)
```

---

## State Backend Configuration

### Pulumi Cloud (Default)

```bash
# Login to Pulumi Cloud (free tier available)
pulumi login
```

### Self-Managed (S3)

```bash
pulumi login s3://my-pulumi-state-bucket
```

### Self-Managed (Local)

```bash
pulumi login --local
```

---

## Stack References (Cross-Project)

```typescript
// In the app project, reference outputs from the networking project
const networkingStack = new pulumi.StackReference("org/networking/dev");
const vpcId = networkingStack.getOutput("vpcId");
const subnetIds = networkingStack.getOutput("subnetIds");
```

---

## Validation Commands

```bash
# Preview changes (dry run)
pulumi preview

# Preview with diff output
pulumi preview --diff

# Deploy
pulumi up

# Deploy with auto-approval (CI/CD only)
pulumi up --yes

# Destroy
pulumi destroy

# View stack outputs
pulumi stack output
```

---

## Best Practices Summary

1. **One stack per environment:** Use separate stacks (dev, staging, prod) with per-stack config files.
2. **Component resources:** Encapsulate related resources into component classes for reusability.
3. **Stack references:** Use `StackReference` for cross-project dependencies, not hardcoded values.
4. **Secrets management:** Use `config.requireSecret()` / `pulumi config set --secret` for sensitive values.
5. **Typed outputs:** Export typed outputs with `pulumi.export()` for downstream consumption.
6. **Common tags:** Define tags once and spread across all resources.
7. **Parent tracking:** Pass `{ parent: this }` to child resources in components for proper resource tree.
8. **Pin provider versions:** Pin SDK versions in `package.json` / `requirements.txt`.
