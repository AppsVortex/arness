# Bicep Patterns

Module decomposition, parameter files per environment, and idiomatic patterns for Azure Bicep infrastructure-as-code. Bicep is Azure's first-party IaC language that compiles to ARM templates.

---

## Project Structure

### Single-Environment (Simple)

```
infra/
├── main.bicep              # Orchestrator that calls modules
├── main.bicepparam         # Default parameter values
├── modules/
│   ├── networking.bicep    # VNet, subnets, NSGs
│   ├── database.bicep      # Azure SQL, Cosmos DB
│   ├── compute.bicep       # App Service, Container Apps, VMs
│   └── monitoring.bicep    # Application Insights, Log Analytics
└── bicepconfig.json        # Bicep configuration (linting rules)
```

### Multi-Environment (Recommended)

```
infra/
├── main.bicep
├── parameters/
│   ├── dev.bicepparam
│   ├── staging.bicepparam
│   └── prod.bicepparam
├── modules/
│   ├── networking.bicep
│   ├── database.bicep
│   ├── compute.bicep
│   └── monitoring.bicep
└── bicepconfig.json
```

---

## Main Orchestrator

### main.bicep

```bicep
targetScope = 'resourceGroup'

@description('Deployment environment')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Project name used for resource naming')
param projectName string

@description('Database administrator password')
@secure()
param dbPassword string

// Common tags
var commonTags = {
  Project: projectName
  Environment: environment
  ManagedBy: 'bicep'
}

// Networking
module networking 'modules/networking.bicep' = {
  name: 'networking-${environment}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    tags: commonTags
  }
}

// Database
module database 'modules/database.bicep' = {
  name: 'database-${environment}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    subnetId: networking.outputs.dbSubnetId
    dbPassword: dbPassword
    tags: commonTags
  }
}

// Compute
module compute 'modules/compute.bicep' = {
  name: 'compute-${environment}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    subnetId: networking.outputs.appSubnetId
    dbConnectionString: database.outputs.connectionString
    tags: commonTags
  }
}

// Outputs
output appUrl string = compute.outputs.appUrl
output dbServerName string = database.outputs.serverName
```

---

## Module Pattern

### modules/networking.bicep

```bicep
@description('Project name for resource naming')
param projectName string

@description('Deployment environment')
param environment string

@description('Azure region')
param location string

@description('Tags to apply to all resources')
param tags object

var vnetName = '${projectName}-${environment}-vnet'

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'app-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'db-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output appSubnetId string = vnet.properties.subnets[0].id
output dbSubnetId string = vnet.properties.subnets[1].id
```

---

## Parameter Files

### parameters/dev.bicepparam

```bicep
using '../main.bicep'

param environment = 'dev'
param projectName = 'myproject'
param dbPassword = readEnvironmentVariable('DB_PASSWORD')
```

### parameters/prod.bicepparam

```bicep
using '../main.bicep'

param environment = 'prod'
param projectName = 'myproject'
param dbPassword = readEnvironmentVariable('DB_PASSWORD')
```

---

## Common Resource Patterns

### App Service (Web App)

```bicep
param projectName string
param environment string
param location string
param tags object

var appServicePlanName = '${projectName}-${environment}-plan'
var appServiceName = '${projectName}-${environment}-app'
var isProduction = environment == 'prod'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: isProduction ? 'P1v3' : 'B1'
    tier: isProduction ? 'PremiumV3' : 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      alwaysOn: isProduction
      healthCheckPath: '/health'
    }
    httpsOnly: true
  }
}

output appUrl string = 'https://${appService.properties.defaultHostName}'
```

### Azure Container Apps

```bicep
param projectName string
param environment string
param location string
param containerImage string
param tags object

var containerAppEnvName = '${projectName}-${environment}-env'
var containerAppName = '${projectName}-${environment}-app'

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvName
  location: location
  tags: tags
  properties: {
    zoneRedundant: environment == 'prod'
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: containerImage
          resources: {
            cpu: json(environment == 'prod' ? '1.0' : '0.25')
            memory: environment == 'prod' ? '2Gi' : '0.5Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 3000
              }
              periodSeconds: 30
            }
          ]
        }
      ]
      scale: {
        minReplicas: environment == 'prod' ? 2 : 0
        maxReplicas: environment == 'prod' ? 10 : 2
      }
    }
  }
}
```

### Azure SQL Database

```bicep
param projectName string
param environment string
param location string
@secure()
param dbPassword string
param subnetId string
param tags object

var serverName = '${projectName}-${environment}-sqlserver'
var dbName = '${projectName}-${environment}-db'
var isProduction = environment == 'prod'

resource sqlServer 'Microsoft.Sql/servers@2024-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    administratorLogin: 'appadmin'
    administratorLoginPassword: dbPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2024-05-01-preview' = {
  parent: sqlServer
  name: dbName
  location: location
  tags: tags
  sku: {
    name: isProduction ? 'S2' : 'Basic'
    tier: isProduction ? 'Standard' : 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: isProduction ? 268435456000 : 2147483648
  }
}

output serverName string = sqlServer.name
output connectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${dbName};'
```

---

## Secure Parameters

```bicep
// Use @secure() decorator for sensitive parameters
@secure()
param dbPassword string

@secure()
param apiKey string

// Reference Key Vault secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'myproject-kv'
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' existing = {
  parent: keyVault
  name: 'db-password'
}
```

---

## Validation Commands

```bash
# Build (compile to ARM template) for syntax validation
az bicep build --file main.bicep

# What-if deployment (dry run)
az deployment group what-if \
  --resource-group myproject-dev-rg \
  --template-file main.bicep \
  --parameters parameters/dev.bicepparam

# Deploy
az deployment group create \
  --resource-group myproject-dev-rg \
  --template-file main.bicep \
  --parameters parameters/dev.bicepparam

# Lint
az bicep lint --file main.bicep
```

---

## Best Practices Summary

1. **Module decomposition:** One module per resource group or concern (networking, database, compute).
2. **Parameter files per environment:** Use `.bicepparam` files with the `using` keyword.
3. **Secure parameters:** Always use `@secure()` for passwords, keys, and connection strings.
4. **Conditional sizing:** Use ternary expressions for environment-aware resource sizing.
5. **Output chaining:** Pass module outputs as inputs to dependent modules.
6. **Resource naming:** Use consistent `${projectName}-${environment}-<role>` pattern.
7. **API version pinning:** Pin API versions in resource type declarations.
8. **Tagging:** Pass a `tags` object through all modules for consistent tagging.
