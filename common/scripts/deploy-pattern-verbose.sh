#!/bin/bash
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Status tracking
declare -a COMPONENT_STATUS
declare -a FAILED_COMPONENTS

# Function to print prominent messages
print_header() {
    echo
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo -e "${BOLD}${BLUE} $1${NC}"
    echo -e "${BOLD}${BLUE}========================================${NC}"
    echo
}

print_success() {
    echo -e "${BOLD}${GREEN}✓ SUCCESS: $1${NC}"
}

print_error() {
    echo -e "${BOLD}${RED}✗ FAILED: $1${NC}"
}

print_warning() {
    echo -e "${BOLD}${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BOLD}${BLUE}ℹ INFO: $1${NC}"
}

# Function to check if ArgoCD application is healthy
check_app_status() {
    local app_name=$1
    local namespace=$2
    local max_wait=${3:-300} # 5 minutes default
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if oc get application.argoproj.io/$app_name -n $namespace >/dev/null 2>&1; then
            local sync_status=$(oc get application.argoproj.io/$app_name -n $namespace -o jsonpath='{.status.sync.status}' 2>/dev/null)
            local health_status=$(oc get application.argoproj.io/$app_name -n $namespace -o jsonpath='{.status.health.status}' 2>/dev/null)
            
            if [[ "$sync_status" == "Synced" && "$health_status" == "Healthy" ]]; then
                return 0
            fi
        fi
        sleep 10
        wait_time=$((wait_time + 10))
        echo -n "."
    done
    return 1
}

# Function to list all components that will be installed
list_components() {
    print_header "LAYERED ZERO TRUST PATTERN - COMPONENT INSTALLATION PLAN"
    
    echo -e "${BOLD}The following components will be installed:${NC}"
    echo
    echo -e "${BOLD}${YELLOW}OPERATORS (OpenShift Subscriptions):${NC}"
    echo "  1. OpenShift Cert Manager Operator (cert-manager-operator namespace)"
    echo "  2. Red Hat Build of Keycloak Operator (keycloak-system namespace)"  
    echo "  3. OpenShift Zero Trust Workload Identity Manager (zero-trust-workload-identity-manager namespace)"
    echo "  4. Compliance Operator (openshift-compliance namespace)"
    echo
    echo -e "${BOLD}${YELLOW}APPLICATIONS (ArgoCD Applications):${NC}"
    echo "  5. HashiCorp Vault (vault namespace)"
    echo "  6. Golang External Secrets Operator (golang-external-secrets namespace)"
    echo "  7. Red Hat Keycloak (keycloak-system namespace)"
    echo "  8. Red Hat Cert Manager (cert-manager-operator namespace)" 
    echo "  9. Zero Trust Workload Identity Manager - SPIRE/SPIFFE (zero-trust-workload-identity-manager namespace)"
    echo
    echo -e "${BOLD}${YELLOW}POST-INSTALLATION:${NC}"
    echo " 10. Secrets Loading (configured backend)"
    echo
    echo -e "${BOLD}${BLUE}PREREQUISITES:${NC}"
    echo "  • OpenShift cluster with admin access"
    echo "  • Default StorageClass available"
    echo "  • Red Hat Marketplace access (for operators)"
    echo "  • Git repository access"
    echo
}

# Function to ask for confirmation
ask_confirmation() {
    echo -e "${BOLD}${YELLOW}Do you want to proceed with the installation? (y/N):${NC} "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            echo "Installation cancelled by user."
            exit 0
            ;;
    esac
}

# Function to deploy the pattern
deploy_pattern() {
    local name=$1
    local chart=$2
    shift 2
    local helm_opts="$*"
    
    print_header "STARTING PATTERN DEPLOYMENT"
    print_info "Installing core pattern infrastructure..."
    
    RUNS=10
    WAIT=15
    
    for i in $(seq 1 ${RUNS}); do
        exec 3>&1 4>&2
        OUT=$( { helm template --include-crds --name-template $name $chart $helm_opts 2>&4 | oc apply -f- 2>&4 1>&3; } 4>&1 3>&1)
        ret=$?
        exec 3>&- 4>&-
        if [ ${ret} -eq 0 ]; then
            break;
        else
            echo -n "."
            sleep "${WAIT}"
        fi
    done

    if [ ${i} -eq ${RUNS} ]; then
        print_error "Core pattern deployment failed after ${RUNS} attempts"
        echo "Error details: ${OUT}"
        COMPONENT_STATUS+=("Core Pattern:FAILED")
        FAILED_COMPONENTS+=("Core Pattern - $OUT")
        return 1
    else
        print_success "Core pattern infrastructure deployed successfully"
        COMPONENT_STATUS+=("Core Pattern:SUCCESS")
        return 0
    fi
}

# Function to wait for and check operators
check_operators() {
    print_header "MONITORING OPERATOR INSTALLATION"
    
    local operators=(
        "openshift-cert-manager-operator:cert-manager-operator"
        "rhbk-operator:keycloak-system"
        "openshift-zero-trust-workload-identity-manager:zero-trust-workload-identity-manager"
        "compliance-operator:openshift-compliance"
    )
    
    for op in "${operators[@]}"; do
        IFS=':' read -r op_name op_namespace <<< "$op"
        print_info "Checking operator: $op_name in namespace $op_namespace"
        
        # Wait for subscription to be created
        local timeout=120
        local elapsed=0
        while [ $elapsed -lt $timeout ]; do
            if oc get subscription $op_name -n $op_namespace >/dev/null 2>&1; then
                break
            fi
            sleep 5
            elapsed=$((elapsed + 5))
            echo -n "."
        done
        
        if [ $elapsed -ge $timeout ]; then
            print_error "Operator subscription $op_name not found after $timeout seconds"
            COMPONENT_STATUS+=("$op_name Operator:FAILED")
            FAILED_COMPONENTS+=("$op_name Operator - Subscription not created")
            continue
        fi
        
        # Check if operator is installed successfully
        timeout=300
        elapsed=0
        while [ $elapsed -lt $timeout ]; do
            local install_plan=$(oc get subscription $op_name -n $op_namespace -o jsonpath='{.status.state}' 2>/dev/null)
            if [[ "$install_plan" == "AtLatestKnown" ]]; then
                print_success "Operator $op_name installed successfully"
                COMPONENT_STATUS+=("$op_name Operator:SUCCESS")
                break
            fi
            sleep 10
            elapsed=$((elapsed + 10))
            echo -n "."
        done
        
        if [ $elapsed -ge $timeout ]; then
            print_error "Operator $op_name installation timed out"
            COMPONENT_STATUS+=("$op_name Operator:FAILED")
            FAILED_COMPONENTS+=("$op_name Operator - Installation timeout")
        fi
    done
}

# Function to check applications
check_applications() {
    print_header "MONITORING APPLICATION DEPLOYMENT"
    
    local apps=(
        "vault:openshift-gitops"
        "golang-external-secrets:openshift-gitops"
        "rh-keycloak:openshift-gitops"
        "rh-cert-manager:openshift-gitops"
        "zero-trust-workload-identity-manager:openshift-gitops"
    )
    
    # Wait a bit for ArgoCD to pick up the applications
    print_info "Waiting for ArgoCD to detect applications..."
    sleep 30
    
    for app in "${apps[@]}"; do
        IFS=':' read -r app_name app_namespace <<< "$app"
        print_info "Checking application: $app_name"
        
        if check_app_status "$app_name" "$app_namespace" 600; then  # 10 minute timeout
            print_success "Application $app_name deployed successfully"
            COMPONENT_STATUS+=("$app_name Application:SUCCESS")
        else
            print_error "Application $app_name deployment failed or timed out"
            COMPONENT_STATUS+=("$app_name Application:FAILED")
            
            # Get more details about the failure
            local sync_status=$(oc get application.argoproj.io/$app_name -n $app_namespace -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
            local health_status=$(oc get application.argoproj.io/$app_name -n $app_namespace -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
            FAILED_COMPONENTS+=("$app_name Application - Sync: $sync_status, Health: $health_status")
        fi
    done
}

# Function to load secrets
load_secrets() {
    print_header "LOADING SECRETS"
    print_info "Starting secrets loading process..."
    
    if common/scripts/process-secrets.sh "$1"; then
        print_success "Secrets loaded successfully"
        COMPONENT_STATUS+=("Secrets Loading:SUCCESS")
    else
        print_error "Secrets loading failed"
        COMPONENT_STATUS+=("Secrets Loading:FAILED")
        FAILED_COMPONENTS+=("Secrets Loading - Check secrets configuration")
    fi
}

# Function to print final summary
print_summary() {
    print_header "INSTALLATION SUMMARY"
    
    local success_count=0
    local total_count=${#COMPONENT_STATUS[@]}
    
    echo -e "${BOLD}Component Installation Results:${NC}"
    echo
    
    for status in "${COMPONENT_STATUS[@]}"; do
        IFS=':' read -r component result <<< "$status"
        if [[ "$result" == "SUCCESS" ]]; then
            echo -e "  ${GREEN}✓${NC} $component"
            success_count=$((success_count + 1))
        else
            echo -e "  ${RED}✗${NC} $component"
        fi
    done
    
    echo
    echo -e "${BOLD}Statistics:${NC}"
    echo "  Total components: $total_count"
    echo -e "  Successful: ${GREEN}$success_count${NC}"
    echo -e "  Failed: ${RED}$((total_count - success_count))${NC}"
    
    if [ ${#FAILED_COMPONENTS[@]} -gt 0 ]; then
        echo
        echo -e "${BOLD}${RED}Failed Components Details:${NC}"
        for failure in "${FAILED_COMPONENTS[@]}"; do
            echo -e "  ${RED}•${NC} $failure"
        done
        echo
        print_warning "Some components failed to install. Check the details above and ArgoCD console for more information."
        print_info "You can check ArgoCD applications status with: make argo-healthcheck"
        return 1
    else
        echo
        print_success "All components installed successfully!"
        print_info "You can verify the installation with: make argo-healthcheck"
        return 0
    fi
}

# Main execution
main() {
    local name=$1
    local chart=$2
    shift 2
    local helm_opts="$*"
    
    # Initialize arrays
    COMPONENT_STATUS=()
    FAILED_COMPONENTS=()
    
    # List components and ask for confirmation
    list_components
    ask_confirmation
    
    # Deploy pattern
    if deploy_pattern "$name" "$chart" $helm_opts; then
        # Check operators
        check_operators
        
        # Check applications  
        check_applications
        
        # Load secrets
        load_secrets "$name"
    else
        print_error "Core pattern deployment failed. Aborting installation."
        exit 1
    fi
    
    # Print summary
    print_summary
}

# Execute main function with all arguments
main "$@" 