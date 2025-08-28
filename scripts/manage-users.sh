#!/bin/bash

# Healthcare Provider Registry - User Management Script
# Based on Protocol Specifications for User Access Control

set -e

# Configuration
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8080}"
REALM_NAME="${REALM_NAME:-healthcare-registry}"
ADMIN_USERNAME="${KEYCLOAK_ADMIN:-admin}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-KeycloakAdmin123!}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Get admin token
get_admin_token() {
    local token
    token=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$ADMIN_USERNAME" \
        -d "password=$ADMIN_PASSWORD" \
        -d "grant_type=password" \
        -d "client_id=admin-cli" | jq -r '.access_token')
    
    if [ "$token" = "null" ] || [ -z "$token" ]; then
        error "Failed to get admin token. Check Keycloak credentials."
        exit 1
    fi
    
    echo "$token"
}

# Check if user exists
user_exists() {
    local username="$1"
    local token="$2"
    
    local user_id
    user_id=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=$username" \
        -H "Authorization: Bearer $token" | jq -r '.[0].id // empty')
    
    [ -n "$user_id" ]
}

# Get user ID
get_user_id() {
    local username="$1"
    local token="$2"
    
    curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users?username=$username" \
        -H "Authorization: Bearer $token" | jq -r '.[0].id'
}

# Create user
create_user() {
    local username="$1"
    local email="$2"
    local first_name="$3"
    local last_name="$4"
    local password="$5"
    local role="$6"
    local token="$7"
    
    log "Creating user: $username with role: $role"
    
    # Create user payload
    local user_payload
    user_payload=$(cat <<EOF
{
    "username": "$username",
    "email": "$email",
    "firstName": "$first_name",
    "lastName": "$last_name",
    "enabled": true,
    "emailVerified": true,
    "credentials": [{
        "type": "password",
        "value": "$password",
        "temporary": false
    }]
}
EOF
)
    
    # Create user
    local response
    response=$(curl -s -w "%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$user_payload")
    
    local http_code="${response: -3}"
    
    if [ "$http_code" -eq 201 ]; then
        log "User $username created successfully"
        
        # Assign role
        assign_role "$username" "$role" "$token"
        
        # Set user attributes based on role
        set_user_attributes "$username" "$role" "$token"
        
    else
        error "Failed to create user $username. HTTP code: $http_code"
        return 1
    fi
}

# Assign role to user
assign_role() {
    local username="$1"
    local role="$2"
    local token="$3"
    
    log "Assigning role $role to user $username"
    
    local user_id
    user_id=$(get_user_id "$username" "$token")
    
    if [ "$user_id" = "null" ] || [ -z "$user_id" ]; then
        error "User $username not found"
        return 1
    fi
    
    # Get role details
    local role_payload
    role_payload=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/roles/$role" \
        -H "Authorization: Bearer $token")
    
    if [ "$(echo "$role_payload" | jq -r '.name')" = "null" ]; then
        error "Role $role not found"
        return 1
    fi
    
    # Assign role
    local response
    response=$(curl -s -w "%{http_code}" -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/role-mappings/realm" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "[$role_payload]")
    
    local http_code="${response: -3}"
    
    if [ "$http_code" -eq 204 ]; then
        log "Role $role assigned to user $username successfully"
    else
        error "Failed to assign role $role to user $username. HTTP code: $http_code"
        return 1
    fi
}

# Set user attributes based on role
set_user_attributes() {
    local username="$1"
    local role="$2"
    local token="$3"
    
    local user_id
    user_id=$(get_user_id "$username" "$token")
    
    local attributes="{}"
    
    case "$role" in
        "PROVIDER")
            attributes='{"providerType": ["PHYSICIAN"], "verificationStatus": ["PENDING"]}'
            ;;
        "INSTITUTIONAL_VERIFIER")
            attributes='{"verifierType": ["INSTITUTIONAL"], "apiAccess": ["true"]}'
            ;;
        "INDIVIDUAL_VERIFIER")
            attributes='{"verifierType": ["INDIVIDUAL"], "apiAccess": ["false"]}'
            ;;
        "ADMIN"|"SUPER_ADMIN"|"REGISTRY_ADMIN")
            attributes='{"department": ["Administration"], "mfaEnabled": ["true"]}'
            ;;
    esac
    
    if [ "$attributes" != "{}" ]; then
        log "Setting attributes for user $username"
        
        curl -s -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d "{\"attributes\": $attributes}"
    fi
}

# List users
list_users() {
    local token="$1"
    local role_filter="$2"
    
    log "Listing users${role_filter:+ with role: $role_filter}"
    
    local users
    users=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
        -H "Authorization: Bearer $token")
    
    if [ -n "$role_filter" ]; then
        # Filter by role (simplified - would need more complex logic for exact filtering)
        echo "$users" | jq -r '.[] | select(.realmRoles[]? == "'$role_filter'") | "\(.username) - \(.email) - \(.firstName) \(.lastName)"'
    else
        echo "$users" | jq -r '.[] | "\(.username) - \(.email) - \(.firstName) \(.lastName) - Enabled: \(.enabled)"'
    fi
}

# Delete user
delete_user() {
    local username="$1"
    local token="$2"
    
    warning "Deleting user: $username"
    
    local user_id
    user_id=$(get_user_id "$username" "$token")
    
    if [ "$user_id" = "null" ] || [ -z "$user_id" ]; then
        error "User $username not found"
        return 1
    fi
    
    read -p "Are you sure you want to delete user $username? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local response
        response=$(curl -s -w "%{http_code}" -X DELETE "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id" \
            -H "Authorization: Bearer $token")
        
        local http_code="${response: -3}"
        
        if [ "$http_code" -eq 204 ]; then
            log "User $username deleted successfully"
        else
            error "Failed to delete user $username. HTTP code: $http_code"
            return 1
        fi
    else
        info "User deletion cancelled"
    fi
}

# Reset user password
reset_password() {
    local username="$1"
    local new_password="$2"
    local temporary="$3"
    local token="$4"
    
    log "Resetting password for user: $username"
    
    local user_id
    user_id=$(get_user_id "$username" "$token")
    
    if [ "$user_id" = "null" ] || [ -z "$user_id" ]; then
        error "User $username not found"
        return 1
    fi
    
    local password_payload
    password_payload=$(cat <<EOF
{
    "type": "password",
    "value": "$new_password",
    "temporary": $temporary
}
EOF
)
    
    local response
    response=$(curl -s -w "%{http_code}" -X PUT "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users/$user_id/reset-password" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$password_payload")
    
    local http_code="${response: -3}"
    
    if [ "$http_code" -eq 204 ]; then
        log "Password reset for user $username successfully"
    else
        error "Failed to reset password for user $username. HTTP code: $http_code"
        return 1
    fi
}

# Create predefined users based on protocol specifications
create_default_users() {
    local token="$1"
    
    log "Creating default users based on protocol specifications"
    
    # Super Admin
    if ! user_exists "admin" "$token"; then
        create_user "admin" "admin@healthcare-registry.com" "System" "Administrator" "Admin123!@#" "SUPER_ADMIN" "$token"
    fi
    
    # Registry Admin
    if ! user_exists "registry.admin" "$token"; then
        create_user "registry.admin" "registry.admin@healthcare-registry.com" "Registry" "Admin" "RegistryAdmin123!" "REGISTRY_ADMIN" "$token"
    fi
    
    # Verification Officer
    if ! user_exists "verification.officer" "$token"; then
        create_user "verification.officer" "verification@healthcare-registry.com" "Verification" "Officer" "VerifyOfficer123!" "VERIFICATION_OFFICER" "$token"
    fi
    
    # Sample Provider
    if ! user_exists "dr.smith" "$token"; then
        create_user "dr.smith" "dr.smith@hospital.com" "John" "Smith" "DrSmith123!" "PROVIDER" "$token"
    fi
    
    # Sample Institutional Verifier
    if ! user_exists "hospital.verifier" "$token"; then
        create_user "hospital.verifier" "verifier@hospital.com" "Hospital" "Verifier" "HospitalVerify123!" "INSTITUTIONAL_VERIFIER" "$token"
    fi
    
    # Sample Individual Verifier
    if ! user_exists "individual.verifier" "$token"; then
        create_user "individual.verifier" "individual@example.com" "Individual" "Verifier" "IndividualVerify123!" "INDIVIDUAL_VERIFIER" "$token"
    fi
    
    log "Default users created successfully"
}

# Show usage
usage() {
    cat <<EOF
Healthcare Provider Registry - User Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    create-user <username> <email> <first_name> <last_name> <password> <role>
        Create a new user with specified role
        
    create-defaults
        Create default users based on protocol specifications
        
    list-users [role]
        List all users or filter by role
        
    delete-user <username>
        Delete a user (with confirmation)
        
    reset-password <username> <new_password> [temporary]
        Reset user password (temporary=true/false, default: false)
        
    assign-role <username> <role>
        Assign role to existing user

Available Roles:
    SUPER_ADMIN          - Full system access
    ADMIN                - System administrator
    REGISTRY_ADMIN       - Registry management
    VERIFICATION_OFFICER - Verification workflow
    PROVIDER             - Healthcare provider
    INSTITUTIONAL_VERIFIER - Enhanced verifier
    INDIVIDUAL_VERIFIER  - Basic verifier
    VERIFIER             - Base verifier role
    GUEST                - Public access

Environment Variables:
    KEYCLOAK_URL         - Keycloak server URL (default: http://localhost:8080)
    REALM_NAME           - Keycloak realm name (default: healthcare-registry)
    KEYCLOAK_ADMIN       - Admin username (default: admin)
    KEYCLOAK_ADMIN_PASSWORD - Admin password (default: KeycloakAdmin123!)

Examples:
    $0 create-defaults
    $0 create-user "new.provider@hospital.com" "new.provider@hospital.com" "New" "Provider" "NewProvider123!" "PROVIDER"
    $0 list-users PROVIDER
    $0 reset-password "dr.smith" "NewPassword123!" true
    $0 assign-role "existing.user" "VERIFIER"

EOF
}

# Main script logic
main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    # Get admin token
    log "Authenticating with Keycloak..."
    local token
    token=$(get_admin_token)
    
    local command="$1"
    shift
    
    case "$command" in
        "create-user")
            if [ $# -ne 6 ]; then
                error "create-user requires 6 arguments: username email first_name last_name password role"
                usage
                exit 1
            fi
            create_user "$1" "$2" "$3" "$4" "$5" "$6" "$token"
            ;;
        "create-defaults")
            create_default_users "$token"
            ;;
        "list-users")
            list_users "$token" "$1"
            ;;
        "delete-user")
            if [ $# -ne 1 ]; then
                error "delete-user requires 1 argument: username"
                usage
                exit 1
            fi
            delete_user "$1" "$token"
            ;;
        "reset-password")
            if [ $# -lt 2 ] || [ $# -gt 3 ]; then
                error "reset-password requires 2-3 arguments: username new_password [temporary]"
                usage
                exit 1
            fi
            local temporary="${3:-false}"
            reset_password "$1" "$2" "$temporary" "$token"
            ;;
        "assign-role")
            if [ $# -ne 2 ]; then
                error "assign-role requires 2 arguments: username role"
                usage
                exit 1
            fi
            assign_role "$1" "$2" "$token"
            ;;
        *)
            error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

