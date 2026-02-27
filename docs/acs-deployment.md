# Red Hat Advanced Cluster Security (RHACS/ACS) Deployment Workflow
## Layered Zero Trust Validated Pattern

**Homepage:** <https://github.com/validatedpatterns/layered-zero-trust>

## Maintainers

| Name | Email | URL |
| ---- | ------ | --- |
| Validated Patterns Team | <validatedpatterns@googlegroups.com> |  |


## Overview

The ACS deployment in the Layered Zero Trust pattern is implemented using:
- **GitOps**: ArgoCD manages the deployment lifecycle
- **Helm Charts**: Two separate charts for Central and Secured Cluster
- **Operator-based**: Uses Red Hat's RHACS Operator
- **Vault Integration**: Secrets stored in HashiCorp Vault

## Architecture Components

### 1. RHACS Operator
- **Installed via**: OLM (Operator Lifecycle Manager)
- **Namespace**: `openshift-operators`
- **Channel**: `stable`
- **Source**: `redhat-operators`

### 2. ACS Central Services (`acs-central`)
- **Purpose**: Central management console, Scanner V4, Policy engine
- **Namespace**: `stackrox`
- **Components**:
  - Central (management console)
  - Scanner V4 Indexer
  - Scanner V4 Matcher
  - PostgreSQL databases (Central DB, Scanner DB)

### 3. ACS Secured Cluster (`acs-secured-cluster`)
- **Purpose**: Per-cluster enforcement and monitoring
- **Namespace**: `stackrox` (same as Central on hub cluster)
- **Components**:
  - Sensor (communicates with Central)
  - Admission Controller (policy enforcement)
  - Collector (DaemonSet for runtime monitoring)

## Deployment Workflow

### Phase 1: Operator Installation (Managed by Pattern Framework)
**When**: During initial pattern deployment
**Configuration File**: `values-hub.yaml`
### Phase 2: ACS Central Application Creation
**When**: After operator is ready
**Helm Chart**: `charts/acs-central/`
### Phase 3: Resource Deployment (Ordered by Sync Waves)
#### **Sync Wave 1: RBAC Setup**
#### **Sync Wave 5: Secrets Configuration**
##### Option A: External Secret (Default - Used in Pattern)
**File**: `central-htpasswd-external-secret.yaml`
**Purpose**: Fetch admin password from Vault
**Creates**: Secret `central-htpasswd` with key `password`
**Why**: Central needs this secret before deployment
##### Option B: Static Secret (Alternative)
**File**: `admin-password-secret.yaml`
**Condition**: Only if `useExternalSecret: false`
#### **Sync Wave 6: Password Hash Generation**
**Purpose**: Generate bcrypt htpasswd entry for admin user
**Why Important**:
- Central CR expects `htpasswd` field for authentication
- Bcrypt generates different hash each time (random salt)
- Job is idempotent (checks for existing valid entry)
#### **Sync Wave 10: Central CR Deployment**
#### **Sync Wave 12: Cluster Init Bundle Creation**
**Purpose**: Generate cluster init bundle for Secured Cluster authentication
**Result**: Secured Cluster components can authenticate to Central
#### **Sync Wave 13: Authentication Provider Setup (Optional)**
**Condition**: Only if `integration.keycloak.enabled: true`
**Purpose**: Configure Keycloak authentication
**Result**: Users can log in via OpenShift OAuth instead of htpasswd
#### **Sync Wave 15: Secured Cluster Deployment**

## Recommended Cluster Specifications

### For layered-zero-trust pattern + ACS deployment:

**Minimum (Development/Testing):**
- Node Size: 3 worker nodes with 8 vCPU / 16Gi RAM each  
- Total Capacity: ~24 vCPU / 48Gi RAM  

**Production:**
- Node Size: 3-5 worker nodes with 16 vCPU / 32Gi RAM each
- Total Capacity: ~48-80 vCPU / 96-160Gi RAM

**Resource Breakdown:**
- OpenShift Platform:        ~8-12 CPU / ~15-20Gi
- Validated Pattern Base:    ~4-6 CPU / ~8-10Gi
- ACS Central Services:      ~2 CPU / ~8Gi
- ACS Secured Cluster:       ~1 CPU / ~2Gi
----------------------------------------
- Total Minimum:             ~15-21 CPU / ~33-40Gi