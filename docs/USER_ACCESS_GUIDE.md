# Healthcare Provider Registry - User Access Control Guide

## 🔐 Overview

This guide explains how to grant and manage access for different user types in the Healthcare Provider Registry system based on the protocol specifications.

## 👥 User Types and Access Levels

### 1. **SUPER_ADMIN**
- **Description**: System administrators with full access
- **Default User**: `admin` / `Admin123!@#`
- **Access**: All system functions, emergency access, data export
- **MFA**: Required
- **Session Timeout**: 8 hours

**Permissions:**
- ✅ Full provider management (CRUD)
- ✅ User management and role assignment
- ✅ System configuration and maintenance
- ✅ Blockchain network administration
- ✅ Emergency access and system reset
- ✅ Data export and backup

### 2. **REGISTRY_ADMIN**
- **Description**: Registry administrators with limited system access
- **Default User**: `registry.admin` / `RegistryAdmin123!`
- **Access**: Provider and verification management
- **MFA**: Required
- **Session Timeout**: 8 hours

**Permissions:**
- ✅ Provider verification and management
- ✅ Credential issuance and revocation
- ✅ Audit trail access
- ❌ System configuration
- ❌ User role assignment

### 3. **VERIFICATION_OFFICER**
- **Description**: Officers responsible for provider verification
- **Default User**: `verification.officer` / `VerifyOfficer123!`
- **Access**: Verification workflow management
- **MFA**: Required
- **Session Timeout**: 8 hours

**Permissions:**
- ✅ Provider verification workflow
- ✅ Document review and approval
- ✅ Credential management
- ❌ User management
- ❌ System configuration

### 4. **PROVIDER**
- **Description**: Healthcare providers managing their profiles
- **Default User**: `dr.smith` / `DrSmith123!`
- **Access**: Own profile and application management
- **MFA**: Optional
- **Session Timeout**: 4 hours

**Permissions:**
- ✅ Update own profile information
- ✅ Upload documents and credentials
- ✅ Track application status
- ✅ Manage education and license information
- ❌ Access other provider data
- ❌ System administration

### 5. **INSTITUTIONAL_VERIFIER**
- **Description**: Organizations with enhanced verification access
- **Default User**: `hospital.verifier` / `HospitalVerify123!`
- **Access**: Bulk verification and API access
- **MFA**: Required
- **Session Timeout**: 3 hours

**Permissions:**
- ✅ Search and verify provider credentials
- ✅ Bulk verification requests
- ✅ API access for integration
- ✅ Webhook notifications
- ✅ Download verification reports
- ❌ Provider profile modification

### 6. **INDIVIDUAL_VERIFIER**
- **Description**: Individual verifiers with basic access
- **Access**: Basic verification functions
- **MFA**: Required
- **Session Timeout**: 3 hours

**Permissions:**
- ✅ Search provider directory
- ✅ Request individual verifications
- ✅ View verification results
- ❌ Bulk operations
- ❌ API access

### 7. **GUEST**
- **Description**: Public users with read-only access
- **Access**: Public directory only
- **MFA**: Not required
- **Session Timeout**: 1 hour

**Permissions:**
- ✅ View public provider directory
- ✅ Basic search functionality
- ❌ Detailed provider information
- ❌ Verification requests

## 🚀 Quick Setup Guide

### 1. Import Keycloak Realm Configuration

```bash
# Start Keycloak
docker-compose up -d keycloak

# Wait for Keycloak to be ready
curl -f http://localhost:8080/health/ready

# Import realm configuration
docker exec healthcare-keycloak /opt/keycloak/bin/kc.sh import \
  --file /opt/keycloak/data/import/healthcare-registry-realm.json \
  --override true
```

### 2. Access the Applications

| User Type | Portal | URL | Default Credentials |
|-----------|--------|-----|-------------------|
| Admin | Admin Portal | http://localhost:3001 | admin / Admin123!@# |
| Registry Admin | Admin Portal | http://localhost:3001 | registry.admin / RegistryAdmin123! |
| Verification Officer | Admin Portal | http://localhost:3001 | verification.officer / VerifyOfficer123! |
| Provider | Provider Portal | http://localhost:3002 | dr.smith / DrSmith123! |
| Verifier | Verifier App | http://localhost:3003 | hospital.verifier / HospitalVerify123! |

### 3. Keycloak Admin Console

- **URL**: http://localhost:8080
- **Admin User**: admin / KeycloakAdmin123!
- **Realm**: healthcare-registry

## 👤 User Management

### Creating New Users

#### Via Keycloak Admin Console

1. Login to Keycloak Admin Console
2. Select `healthcare-registry` realm
3. Go to `Users` → `Add user`
4. Fill user details:
   - Username (email format recommended)
   - Email (required)
   - First Name / Last Name
   - Email Verified: ON
5. Set password in `Credentials` tab
6. Assign roles in `Role Mappings` tab

#### Via API

```bash
# Get admin token
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=KeycloakAdmin123!" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Create new provider user
curl -X POST http://localhost:8080/admin/realms/healthcare-registry/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "new.provider@hospital.com",
    "email": "new.provider@hospital.com",
    "firstName": "New",
    "lastName": "Provider",
    "enabled": true,
    "emailVerified": true,
    "credentials": [{
      "type": "password",
      "value": "NewProvider123!",
      "temporary": false
    }],
    "realmRoles": ["PROVIDER"]
  }'
```

### Role Assignment

#### Available Roles

| Role | Description | Inheritance |
|------|-------------|-------------|
| SUPER_ADMIN | Full system access | Inherits ADMIN |
| ADMIN | System administrator | Base admin role |
| REGISTRY_ADMIN | Registry management | Inherits ADMIN (limited) |
| VERIFICATION_OFFICER | Verification workflow | Standalone |
| PROVIDER | Healthcare provider | Standalone |
| INSTITUTIONAL_VERIFIER | Enhanced verifier | Inherits VERIFIER |
| INDIVIDUAL_VERIFIER | Basic verifier | Inherits VERIFIER |
| VERIFIER | Base verifier role | Standalone |
| GUEST | Public access | Standalone |

#### Assign Role via API

```bash
# Get user ID
USER_ID=$(curl -s -X GET "http://localhost:8080/admin/realms/healthcare-registry/users?username=new.provider@hospital.com" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id')

# Assign PROVIDER role
curl -X POST "http://localhost:8080/admin/realms/healthcare-registry/users/$USER_ID/role-mappings/realm" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '[{
    "name": "PROVIDER",
    "description": "Healthcare provider"
  }]'
```

## 🔒 Security Configuration

### Multi-Factor Authentication (MFA)

MFA is required for:
- SUPER_ADMIN
- REGISTRY_ADMIN
- VERIFICATION_OFFICER
- INSTITUTIONAL_VERIFIER
- INDIVIDUAL_VERIFIER

#### Enable MFA for User

1. Login to user account
2. Go to Account Console: http://localhost:8080/realms/healthcare-registry/account
3. Navigate to `Authenticator` section
4. Set up TOTP using Google Authenticator or similar app

### Password Policy

Current policy enforces:
- Minimum 12 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character
- Cannot be username or email
- Password history: 12 previous passwords
- Maximum age: 90 days

### Session Management

| User Type | Max Sessions | Idle Timeout | Max Lifetime |
|-----------|--------------|--------------|--------------|
| ADMIN | 3 | 30 minutes | 8 hours |
| PROVIDER | 2 | 60 minutes | 4 hours |
| VERIFIER | 5 | 45 minutes | 3 hours |
| GUEST | 1 | 15 minutes | 1 hour |

## 🔍 Access Control Examples

### API Access Control

#### Provider accessing own data
```bash
# Login as provider
TOKEN=$(curl -s -X POST http://localhost:8080/realms/healthcare-registry/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=dr.smith" \
  -d "password=DrSmith123!" \
  -d "grant_type=password" \
  -d "client_id=provider-portal" \
  -d "client_secret=provider-portal-secret-key-12345" | jq -r '.access_token')

# Access own profile
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8081/api/providers/profile
```

#### Verifier searching providers
```bash
# Login as verifier
VERIFIER_TOKEN=$(curl -s -X POST http://localhost:8080/realms/healthcare-registry/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=hospital.verifier" \
  -d "password=HospitalVerify123!" \
  -d "grant_type=password" \
  -d "client_id=verifier-app" \
  -d "client_secret=verifier-app-secret-key-12345" | jq -r '.access_token')

# Search providers
curl -H "Authorization: Bearer $VERIFIER_TOKEN" \
  "http://localhost:8081/api/providers/search?specialty=CARDIOLOGY"
```

#### Admin managing users
```bash
# Login as admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/healthcare-registry/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=Admin123!@#" \
  -d "grant_type=password" \
  -d "client_id=admin-portal" \
  -d "client_secret=admin-portal-secret-key-12345" | jq -r '.access_token')

# Get all providers
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://localhost:8081/api/admin/providers
```

## 📊 Rate Limiting

| User Type | Requests/Minute | Requests/Hour |
|-----------|-----------------|---------------|
| ADMIN | 1,000 | 50,000 |
| PROVIDER | 100 | 5,000 |
| VERIFIER | 500 | 25,000 |
| GUEST | 10 | 500 |

## 🔄 User Lifecycle Management

### New Provider Registration

1. **Self-Registration**
   - Provider visits registration portal
   - Fills registration form
   - Email verification required
   - Account created with PROVIDER role

2. **Admin-Created Account**
   - Admin creates account via console
   - Temporary password assigned
   - User must change password on first login

### Provider Verification Process

1. **Document Upload** (Provider)
   - Upload medical licenses
   - Upload education certificates
   - Submit for verification

2. **Verification Review** (Verification Officer)
   - Review submitted documents
   - Verify with issuing authorities
   - Approve or reject application

3. **Credential Issuance** (System)
   - Generate verifiable credentials
   - Record on blockchain
   - Notify provider of completion

### Account Deactivation

1. **Temporary Suspension**
   - Disable user account
   - Preserve data
   - Can be reactivated

2. **Permanent Deletion**
   - Remove user account
   - Anonymize audit logs
   - Cannot be recovered

## 🚨 Troubleshooting

### Common Issues

#### User Cannot Login
1. Check if account is enabled
2. Verify email is confirmed
3. Check password policy compliance
4. Verify role assignments

#### Access Denied Errors
1. Check user roles
2. Verify client configuration
3. Check token expiration
4. Validate permissions

#### MFA Issues
1. Verify TOTP configuration
2. Check time synchronization
3. Use backup codes if available

### Support Commands

```bash
# Check user status
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8080/admin/realms/healthcare-registry/users?username=user@example.com"

# Reset user password
curl -X PUT "http://localhost:8080/admin/realms/healthcare-registry/users/$USER_ID/reset-password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"password","value":"NewPassword123!","temporary":true}'

# Check user sessions
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:8080/admin/realms/healthcare-registry/users/$USER_ID/sessions"
```

## 📞 Support

For user access issues:
- **Documentation**: [GitHub Wiki](https://github.com/HealthFlowEgy/healthcare-provider-registry/wiki)
- **Issues**: [GitHub Issues](https://github.com/HealthFlowEgy/healthcare-provider-registry/issues)
- **Email**: support@healthcare-registry.com

---

**🔐 Security is our priority. Always follow the principle of least privilege when granting access.**

