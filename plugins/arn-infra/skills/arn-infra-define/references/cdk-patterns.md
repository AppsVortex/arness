# AWS CDK Patterns

App/stack hierarchy, construct levels, environment-aware stacks, and idiomatic patterns for AWS Cloud Development Kit infrastructure-as-code.

---

## Project Structure

### Standard CDK Project

```
infra/
├── bin/
│   └── app.ts              # CDK app entry point (defines stacks per environment)
├── lib/
│   ├── stacks/
│   │   ├── networking-stack.ts    # VPC, subnets, NAT gateways
│   │   ├── database-stack.ts      # RDS, ElastiCache
│   │   ├── compute-stack.ts       # ECS, Lambda, EC2
│   │   └── monitoring-stack.ts    # CloudWatch, alarms
│   └── constructs/
│       ├── app-service.ts         # Custom L3 construct for app services
│       ├── secure-bucket.ts       # Custom L3 construct for S3 with security defaults
│       └── tagged-resource.ts     # Mixin for common tagging
├── test/
│   └── stacks.test.ts      # CDK assertion tests
├── cdk.json                 # CDK configuration
├── package.json
└── tsconfig.json
```

---

## CDK App Entry Point

### bin/app.ts

```typescript
import * as cdk from "aws-cdk-lib";
import { NetworkingStack } from "../lib/stacks/networking-stack";
import { DatabaseStack } from "../lib/stacks/database-stack";
import { ComputeStack } from "../lib/stacks/compute-stack";

const app = new cdk.App();

// Environment configuration
const envConfig: Record<string, cdk.Environment> = {
  dev: { account: "111111111111", region: "us-east-1" },
  staging: { account: "222222222222", region: "us-east-1" },
  prod: { account: "333333333333", region: "us-east-1" },
};

const targetEnv = app.node.tryGetContext("env") || "dev";
const environment = envConfig[targetEnv];

// Common tags
cdk.Tags.of(app).add("Project", "myproject");
cdk.Tags.of(app).add("Environment", targetEnv);
cdk.Tags.of(app).add("ManagedBy", "cdk");

// Stack deployment
const networking = new NetworkingStack(app, `MyProject-${targetEnv}-Networking`, {
  env: environment,
  environment: targetEnv,
});

const database = new DatabaseStack(app, `MyProject-${targetEnv}-Database`, {
  env: environment,
  environment: targetEnv,
  vpc: networking.vpc,
});

const compute = new ComputeStack(app, `MyProject-${targetEnv}-Compute`, {
  env: environment,
  environment: targetEnv,
  vpc: networking.vpc,
  dbEndpoint: database.dbEndpoint,
});
```

---

## Construct Levels

### L1 (CloudFormation Resources)

Direct CloudFormation resource mappings. Prefix: `Cfn`. Use when CDK does not have a higher-level construct.

```typescript
new cdk.aws_ec2.CfnVPC(this, "Vpc", {
  cidrBlock: "10.0.0.0/16",
});
```

### L2 (Intent-Based Constructs)

AWS-provided constructs with sensible defaults and convenience methods. These are the most commonly used.

```typescript
const vpc = new ec2.Vpc(this, "Vpc", {
  maxAzs: 3,
  natGateways: 1,
});

const bucket = new s3.Bucket(this, "Bucket", {
  encryption: s3.BucketEncryption.S3_MANAGED,
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
```

### L3 (Patterns / Custom Constructs)

Higher-level abstractions that compose multiple L2 constructs. Create custom L3 constructs for repeated patterns.

```typescript
import * as cdk from "aws-cdk-lib";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as ecs from "aws-cdk-lib/aws-ecs";
import * as ecs_patterns from "aws-cdk-lib/aws-ecs-patterns";
import { Construct } from "constructs";

interface AppServiceProps {
  vpc: ec2.IVpc;
  containerImage: string;
  containerPort: number;
  environment: string;
  desiredCount?: number;
  cpu?: number;
  memoryLimitMiB?: number;
}

class AppService extends Construct {
  public readonly service: ecs_patterns.ApplicationLoadBalancedFargateService;
  public readonly url: string;

  constructor(scope: Construct, id: string, props: AppServiceProps) {
    super(scope, id);

    this.service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, "Service", {
      vpc: props.vpc,
      taskImageOptions: {
        image: ecs.ContainerImage.fromRegistry(props.containerImage),
        containerPort: props.containerPort,
        environment: {
          NODE_ENV: props.environment,
        },
      },
      desiredCount: props.desiredCount ?? 1,
      cpu: props.cpu ?? 256,
      memoryLimitMiB: props.memoryLimitMiB ?? 512,
      publicLoadBalancer: true,
    });

    this.url = this.service.loadBalancer.loadBalancerDnsName;
  }
}
```

---

## Stack Pattern

### lib/stacks/networking-stack.ts

```typescript
import * as cdk from "aws-cdk-lib";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import { Construct } from "constructs";

interface NetworkingStackProps extends cdk.StackProps {
  environment: string;
}

export class NetworkingStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: NetworkingStackProps) {
    super(scope, id, props);

    this.vpc = new ec2.Vpc(this, "Vpc", {
      maxAzs: props.environment === "prod" ? 3 : 2,
      natGateways: props.environment === "prod" ? 2 : 1,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: "Public",
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: "Private",
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
        {
          cidrMask: 28,
          name: "Isolated",
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
        },
      ],
    });

    // Outputs
    new cdk.CfnOutput(this, "VpcId", { value: this.vpc.vpcId });
  }
}
```

---

## Environment-Aware Configuration

### Using CDK Context

```bash
# Deploy dev
cdk deploy --context env=dev

# Deploy prod
cdk deploy --context env=prod
```

### cdk.json

```json
{
  "app": "npx ts-node --prefer-ts-exts bin/app.ts",
  "context": {
    "env": "dev"
  }
}
```

### Environment-Specific Sizing

```typescript
const isProduction = props.environment === "prod";

const db = new rds.DatabaseInstance(this, "Database", {
  engine: rds.DatabaseInstanceEngine.postgres({ version: rds.PostgresEngineVersion.VER_16 }),
  instanceType: isProduction
    ? ec2.InstanceType.of(ec2.InstanceClass.R6G, ec2.InstanceSize.LARGE)
    : ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
  vpc: props.vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
  multiAz: isProduction,
  backupRetention: cdk.Duration.days(isProduction ? 30 : 7),
  deletionProtection: isProduction,
  removalPolicy: isProduction ? cdk.RemovalPolicy.RETAIN : cdk.RemovalPolicy.DESTROY,
});
```

---

## Cross-Stack References

```typescript
// In the database stack: export the endpoint
new cdk.CfnOutput(this, "DbEndpoint", {
  value: this.db.dbInstanceEndpointAddress,
  exportName: `${props.environment}-DbEndpoint`,
});

// In the compute stack: import the endpoint
const dbEndpoint = cdk.Fn.importValue(`${props.environment}-DbEndpoint`);
```

Or pass directly via props (preferred for same-app stacks):

```typescript
const compute = new ComputeStack(app, "Compute", {
  dbEndpoint: database.dbEndpoint,  // Direct reference
});
```

---

## Validation Commands

```bash
# Synthesize CloudFormation templates
cdk synth

# Show diff against deployed stack
cdk diff

# Deploy
cdk deploy

# Deploy specific stack
cdk deploy MyProject-dev-Compute

# Deploy all stacks
cdk deploy --all

# Destroy
cdk destroy
```

---

## Best Practices Summary

1. **One stack per concern:** Separate networking, database, compute, and monitoring into distinct stacks.
2. **L2 constructs by default:** Use L2 constructs for sensible defaults. Drop to L1 only when needed.
3. **Custom L3 constructs:** Encapsulate repeated patterns into reusable L3 constructs.
4. **Environment via context:** Use `--context env=dev` to select environment at deploy time.
5. **Cross-stack props:** Pass references via constructor props within the same app (not `importValue`).
6. **Removal policies:** Set `RETAIN` for production databases and stateful resources. `DESTROY` for dev.
7. **Assertion tests:** Use `aws-cdk-lib/assertions` to validate synthesized templates.
8. **Tag at the app level:** Use `cdk.Tags.of(app).add()` for project-wide tags.
