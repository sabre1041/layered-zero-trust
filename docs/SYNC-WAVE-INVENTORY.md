# Argo CD Sync-Wave Inventory

All `argocd.argoproj.io/sync-wave` assignments in `layered-zero-trust`.

A +31 offset was applied to every value so that all waves are positive (>= 1), preserving the original relative ordering. This accommodates the Validated Patterns operator applying the Argo CD super-role later than before, which caused resources with negative sync waves to fail.

## Application-level waves (`values-hub.yaml`)

These control when each Argo CD Application syncs relative to other Applications.

| Application | Old | Current | Comment | Active? |
| --- | ---: | ---: | --- | --- |
| compliance-scanning | -30 | 1 | Earliest app | yes |
| ztvp-certificates | -10 | 21 | Custom CA distribution | yes |
| openshift-storage (OperatorGroup) | -5 | 26 | Propagated to OperatorGroup | commented |
| rhtpa-operator (namespace) | -5 | 26 | Before operator subscription | commented |
| odf (subscription) | -4 | 27 | After OperatorGroup (26) | commented |
| rhtpa-operator (subscription) | -4 | 27 | After OperatorGroup (26) | commented |
| quay-operator (subscription) | -3 | 28 | After ODF operator | commented |
| rhtas-operator (subscription) | -2 | 29 | After Quay operator | commented |
| quay-enterprise (namespace) | 1 | 32 | Before NooBaa and Quay components | commented |
| trusted-artifact-signer (namespace) | 1 | 32 | Auto-created by RHTAS operator | commented |
| trusted-profile-analyzer (namespace) | 1 | 32 | Before RHTPA components | commented |
| noobaa-mcg | 5 | 36 | Deploy after core services | commented |
| acs-central | 10 | 41 | — | yes |
| quay-registry | 10 | 41 | Deploy after NooBaa | commented |
| trusted-profile-analyzer | 10 | 41 | Chart resources (OBC, DB, etc.) | commented |
| acs-secured-cluster | 15 | 46 | — | yes |
| trusted-artifact-signer | 15 | 46 | Deploy after dependencies | commented |

## Chart-level waves (templates)

These control resource ordering within a single Application's sync.

### compliance-scanning (`charts/compliance-scanning/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| apiserver-encryption.yaml | -10 | 21 |
| pvc.yaml | -10 | 21 |
| scan-setting.yaml | -10 | 21 |
| scan-setting-binding.yaml | -10 | 21 |

### ztvp-certificates (`charts/ztvp-certificates/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| rbac.yaml (7 resources) | -9 | 22 |
| configmap-script.yaml | -9 | 22 |
| ca-extraction-job-initial.yaml | -8 | 23 |
| ca-extraction-cronjob.yaml | -8 | 23 |
| managedclusterset-binding.yaml | -6 | 25 |
| distribution-policy.yaml (3 resources) | -5 | 26 |

### rhtpa-operator (`charts/rhtpa-operator/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| ingress-ca-job.yaml (SA, Role, RoleBinding, ConfigMap, Job) | 0 | 31 |
| operator-rolebinding.yaml (2 bindings) | 1 | 32 |
| ingress-ca-job.yaml (completion Job) | 2 | 33 |
| oidc-cli-secret.yaml | 3 | 34 |
| postgresql-serviceaccount.yaml | 5 | 36 |
| postgresql-external-secret.yaml | 5 | 36 |
| object-bucket-claim.yaml | 5 | 36 |
| s3-credentials-secret.yaml | 8 | 39 |
| postgresql-statefulset.yaml | 10 | 41 |
| postgresql-service.yaml | 10 | 41 |
| spiffe-helper-config.yaml | 18 | 49 |
| trusted-profile-analyzer.yaml (supporting objects) | 20 | 51 |
| operator-readiness-check.yaml (SA, Role, Job) | 40 | 71 |
| trusted-profile-analyzer.yaml (Policy/CR) | 50 | 81 |

### noobaa-mcg (`charts/noobaa-mcg/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| default-backingstore.yaml | 1 | 32 |
| noobaa-system.yaml | 2 | 33 |
| bucket-class.yaml | 3 | 34 |

### keycloak (`charts/keycloak/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| keycloak.yaml | 5 | 36 |
| keycloak-realm-import.yaml | 10 | 41 |

### quay-registry (`charts/quay-registry/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| object-bucket-claim.yaml | 5 | 36 |
| quay-s3-setup-serviceaccount.yaml (5 resources) | 6 | 37 |
| quay-config-bundle-secret.yaml | 7 | 38 |
| quay-s3-credentials-job.yaml | 8 | 39 |
| quay-registry.yaml | 10 | 41 |

### acs-central (`charts/acs-central/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| rbac/* (SA, Role, ClusterRole, bindings) | 1 | 32 |
| admin-password-secret.yaml | 5 | 36 |
| central-htpasswd-external-secret.yaml | 5 | 36 |
| keycloak-client-secret-external-secret.yaml | 5 | 36 |
| create-htpasswd-field.yaml (Job) | 6 | 37 |
| central-cr.yaml | 10 | 41 |
| create-cluster-init-bundle.yaml (Job) | 12 | 43 |
| create-auth-provider.yaml (Job) | 13 | 44 |
| console-link.yaml | 15 | 46 |

### acs-secured-cluster (`charts/acs-secured-cluster/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| secured-cluster-cr.yaml | 15 | 46 |

### rhtas-operator (`charts/rhtas-operator/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| securesign.yaml | 15 | 46 |

### qtodo (`charts/qtodo/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| truststore-secret-external-secret.yaml | 5 | 36 |
| postgresql-statefulset.yaml | 10 | 41 |
| postgresql-service.yaml | 10 | 41 |
| qtodo-truststore-config.yaml | 10 | 41 |
| app-deployment.yaml | 20 | 51 |
| app-service.yaml | 20 | 51 |

### supply-chain (`charts/supply-chain/templates/`)

| Resource | Old | Current |
| --- | ---: | ---: |
| workspaces.yaml | 20 | 51 |

### docs/DEVELOPMENT.md (example snippet, not deployed)

| Resource | Old | Current |
| --- | ---: | ---: |
| noobaa-mcg example | 5 | 36 |
