# Healthcare Provider Registry - Deployment Guide

## 🚀 Quick Deployment Options

### Option 1: Docker Compose (Recommended for Development/Testing)

1. **Clone the repository**
   ```bash
   git clone https://github.com/HealthFlowEgy/healthcare-provider-registry.git
   cd healthcare-provider-registry
   ```

2. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Access the applications**
   - Admin Portal: http://localhost:3001
   - Provider Portal: http://localhost:3002
   - Verifier App: http://localhost:3003
   - API Gateway: http://localhost:8081
   - Keycloak: http://localhost:8080
   - Grafana: http://localhost:3000

### Option 2: Kubernetes (Production)

1. **Prerequisites**
   - Kubernetes cluster (1.24+)
   - Helm 3.0+
   - kubectl configured

2. **Deploy with Helm**
   ```bash
   helm install healthcare-registry ./infrastructure/helm/healthcare-registry
   ```

3. **Configure ingress**
   ```bash
   kubectl apply -f infrastructure/kubernetes/ingress/
   ```

### Option 3: Manual Setup

#### Backend Services

1. **Database Setup**
   ```bash
   # PostgreSQL
   docker run -d --name postgres \
     -e POSTGRES_DB=healthcare_registry \
     -e POSTGRES_USER=healthcare_admin \
     -e POSTGRES_PASSWORD=SecurePassword123! \
     -p 5432:5432 postgres:15-alpine

   # Redis
   docker run -d --name redis \
     -p 6379:6379 redis:7-alpine \
     redis-server --requirepass RedisPassword123!
   ```

2. **Keycloak Setup**
   ```bash
   docker run -d --name keycloak \
     -e KEYCLOAK_ADMIN=admin \
     -e KEYCLOAK_ADMIN_PASSWORD=KeycloakAdmin123! \
     -p 8080:8080 \
     quay.io/keycloak/keycloak:23.0 start-dev
   ```

3. **Identus Agent**
   ```bash
   docker run -d --name identus-agent \
     -e AGENT_HTTP_PORT=8085 \
     -e POLLUX_DB_HOST=localhost \
     -e POLLUX_DB_PORT=5432 \
     -p 8085:8085 \
     ghcr.io/hyperledger/identus-cloud-agent:1.33.0
   ```

4. **Backend Services**
   ```bash
   # API Gateway
   cd backend/api-gateway
   ./mvnw spring-boot:run

   # Provider Service
   cd backend/provider-service
   ./mvnw spring-boot:run

   # Credential Service
   cd backend/credential-service
   npm install && npm start

   # Identity Service
   cd backend/identity-service
   npm install && npm start
   ```

#### Frontend Applications

```bash
# Install dependencies
cd frontend
npm install

# Start development servers
npm run dev:admin     # Port 3001
npm run dev:provider  # Port 3002
npm run dev:verifier  # Port 3003
```

## 🔧 Configuration

### Environment Variables

Key environment variables to configure:

```bash
# Database
POSTGRES_USER=healthcare_admin
POSTGRES_PASSWORD=SecurePassword123!
POSTGRES_DB=healthcare_registry

# Authentication
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=KeycloakAdmin123!
JWT_SECRET=jwt_secret_key_minimum_32_characters_required_for_security

# Identus
IDENTUS_ADMIN_TOKEN=identus_admin_token_12345
IDENTUS_WALLET_SEED=wallet_seed_minimum_32_characters_required_here

# External Services
SMTP_HOST=smtp.gmail.com
SMTP_USERNAME=noreply@healthcare-registry.com
SMTP_PASSWORD=smtp_password_here
```

### SSL/TLS Configuration

For production deployment, configure SSL certificates:

```bash
# Place certificates in configs/ssl/
configs/ssl/
├── healthcare-registry.crt
├── healthcare-registry.key
└── ca-bundle.crt
```

Update nginx configuration:
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/healthcare-registry.crt;
    ssl_certificate_key /etc/nginx/ssl/healthcare-registry.key;
    
    # Additional SSL configuration...
}
```

## 🏗️ Infrastructure Setup

### AWS Deployment

1. **EKS Cluster**
   ```bash
   cd infrastructure/terraform/environments/aws
   terraform init
   terraform plan
   terraform apply
   ```

2. **RDS Database**
   ```bash
   # Configure RDS PostgreSQL instance
   # Update connection strings in environment variables
   ```

3. **Application Load Balancer**
   ```bash
   # Configure ALB for ingress
   kubectl apply -f infrastructure/kubernetes/aws/
   ```

### Azure Deployment

1. **AKS Cluster**
   ```bash
   cd infrastructure/terraform/environments/azure
   terraform init
   terraform apply
   ```

2. **Azure Database for PostgreSQL**
   ```bash
   # Configure managed PostgreSQL
   # Update connection strings
   ```

### Google Cloud Deployment

1. **GKE Cluster**
   ```bash
   cd infrastructure/terraform/environments/gcp
   terraform init
   terraform apply
   ```

2. **Cloud SQL**
   ```bash
   # Configure Cloud SQL PostgreSQL
   # Update connection strings
   ```

## 🔐 Security Configuration

### Keycloak Realm Setup

1. **Import realm configuration**
   ```bash
   docker exec keycloak /opt/keycloak/bin/kc.sh import \
     --file /opt/keycloak/data/import/realm-export.json
   ```

2. **Configure clients**
   - Admin Portal: `admin-portal`
   - Provider Portal: `provider-portal`
   - Verifier App: `verifier-app`
   - API Gateway: `api-gateway`

### Blockchain Network

1. **Hyperledger Fabric Setup**
   ```bash
   cd blockchain/fabric-network
   ./scripts/network.sh up
   ./scripts/createChannel.sh
   ./scripts/deployCC.sh
   ```

2. **Chaincode Deployment**
   ```bash
   # Provider Registry Chaincode
   ./scripts/deployCC.sh provider-registry

   # Credential Management Chaincode
   ./scripts/deployCC.sh credential-management
   ```

## 📊 Monitoring Setup

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'healthcare-api'
    static_configs:
      - targets: ['api-gateway:8081', 'provider-service:8082']
  
  - job_name: 'identus-agent'
    static_configs:
      - targets: ['identus-agent:9085']
```

### Grafana Dashboards

Import pre-configured dashboards:
- System Metrics
- Application Performance
- Blockchain Metrics
- Security Events

## 🧪 Testing Deployment

### Health Checks

```bash
# API Gateway
curl http://localhost:8081/actuator/health

# Provider Service
curl http://localhost:8082/actuator/health

# Credential Service
curl http://localhost:8083/health

# Identity Service
curl http://localhost:8084/health

# Identus Agent
curl http://localhost:8085/_system/health
```

### Integration Tests

```bash
# Run integration tests
cd tests/integration
npm test

# Run E2E tests
cd tests/e2e
npx playwright test

# Run performance tests
cd tests/performance
k6 run load-test.js
```

## 🔄 CI/CD Pipeline

### GitHub Actions

The repository includes comprehensive CI/CD workflows:

- **Build & Test**: `.github/workflows/ci.yml`
- **Security Scan**: `.github/workflows/security.yml`
- **Deploy**: `.github/workflows/deploy.yml`

### Deployment Environments

1. **Development**: Auto-deploy on push to `develop` branch
2. **Staging**: Auto-deploy on push to `staging` branch
3. **Production**: Manual approval required

## 📋 Post-Deployment Checklist

- [ ] All services are running and healthy
- [ ] Database migrations completed successfully
- [ ] Keycloak realm and clients configured
- [ ] Identus agent is connected and operational
- [ ] Blockchain network is up and chaincode deployed
- [ ] SSL certificates are valid and configured
- [ ] Monitoring dashboards are accessible
- [ ] Backup procedures are in place
- [ ] Security scans completed with no critical issues
- [ ] Performance tests passed
- [ ] Documentation is up to date

## 🆘 Troubleshooting

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Check database connectivity
   docker exec postgres pg_isready -U healthcare_admin
   ```

2. **Keycloak Authentication Issues**
   ```bash
   # Check Keycloak logs
   docker logs keycloak
   ```

3. **Identus Agent Issues**
   ```bash
   # Check agent status
   curl http://localhost:8085/_system/health
   ```

4. **Blockchain Network Issues**
   ```bash
   # Check Fabric network status
   cd blockchain/fabric-network
   ./scripts/network.sh status
   ```

### Log Locations

- API Gateway: `/var/log/healthcare/api-gateway.log`
- Provider Service: `/var/log/healthcare/provider-service.log`
- Credential Service: `/var/log/healthcare/credential-service.log`
- Identity Service: `/var/log/healthcare/identity-service.log`

### Support

For deployment support:
- GitHub Issues: https://github.com/HealthFlowEgy/healthcare-provider-registry/issues
- Documentation: https://github.com/HealthFlowEgy/healthcare-provider-registry/wiki
- Email: support@healthcare-registry.com

---

**🎉 Congratulations! Your Healthcare Provider Registry is now deployed and ready for use.**

