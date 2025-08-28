# Healthcare Provider Registry

A comprehensive, enterprise-ready healthcare provider registration and verification system built with blockchain technology, decentralized identity, and modern microservices architecture.

## 🏥 Overview

The Healthcare Provider Registry is a secure, scalable platform that enables:

- **Provider Registration**: Streamlined registration process for healthcare professionals
- **Blockchain Verification**: Immutable records using Hyperledger Fabric
- **Decentralized Identity**: Self-sovereign identity with Hyperledger Identus (DID/VC)
- **Single Sign-On**: Integrated authentication with Keycloak
- **Real-time Verification**: Instant credential verification for employers and institutions
- **Compliance**: HIPAA, GDPR, and healthcare regulation compliance

## 🏗️ Architecture

### Technology Stack

- **Blockchain**: Hyperledger Fabric 2.5+
- **Identity**: Hyperledger Identus (Prism)
- **Authentication**: Keycloak SSO
- **Backend**: Spring Boot (Java 17), Node.js
- **Frontend**: React 18, TypeScript
- **Database**: PostgreSQL, Redis
- **Container**: Docker, Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus, Grafana
- **Infrastructure**: Terraform, Helm

### System Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Admin Portal  │    │ Provider Portal │    │  Verifier App   │
│     (React)     │    │     (React)     │    │     (React)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Gateway   │
                    │  (Spring Boot)  │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Provider Service│    │Credential Service│    │ Identity Service│
│  (Spring Boot)  │    │   (Node.js)     │    │   (Node.js)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │    Keycloak     │
                    │      SSO        │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  PostgreSQL     │    │ Hyperledger     │    │  Hyperledger    │
│   Database      │    │    Fabric       │    │    Identus      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Node.js 18+
- Java 17+
- Git

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/HealthFlowEgy/healthcare-provider-registry.git
   cd healthcare-provider-registry
   ```

2. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start Infrastructure Services**
   ```bash
   docker-compose up -d postgres redis keycloak
   ```

4. **Initialize Blockchain Network**
   ```bash
   cd blockchain/fabric-network
   ./scripts/network.sh up
   ./scripts/deployCC.sh
   ```

5. **Start Identus Agent**
   ```bash
   cd identus-agent
   docker-compose up -d
   ```

6. **Start Backend Services**
   ```bash
   cd backend
   ./mvnw spring-boot:run -pl api-gateway
   ./mvnw spring-boot:run -pl provider-service
   npm start --prefix credential-service
   npm start --prefix identity-service
   ```

7. **Start Frontend Applications**
   ```bash
   cd frontend
   npm install
   npm run dev:admin     # Admin Portal (http://localhost:3001)
   npm run dev:provider  # Provider Portal (http://localhost:3002)
   npm run dev:verifier  # Verifier App (http://localhost:3003)
   ```

### Production Deployment

#### Kubernetes Deployment

1. **Deploy with Helm**
   ```bash
   helm install healthcare-registry ./infrastructure/helm/healthcare-registry
   ```

2. **Configure Ingress**
   ```bash
   kubectl apply -f infrastructure/kubernetes/ingress/
   ```

#### Docker Compose Deployment

```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 📚 Documentation

- [API Documentation](docs/api/README.md)
- [Architecture Guide](docs/architecture/README.md)
- [Deployment Guide](docs/deployment/README.md)
- [User Guides](docs/user-guides/README.md)
- [Development Setup](docs/development/README.md)

## 🔐 Security Features

- **End-to-End Encryption**: All data encrypted in transit and at rest
- **Zero-Knowledge Proofs**: Privacy-preserving credential verification
- **Multi-Factor Authentication**: Enhanced security with MFA
- **Role-Based Access Control**: Granular permission management
- **Audit Trail**: Immutable blockchain-based audit logs
- **Compliance**: HIPAA, GDPR, SOC 2 Type II ready

## 🧪 Testing

### Run All Tests
```bash
# Backend tests
cd backend && ./mvnw test

# Frontend tests
cd frontend && npm test

# Integration tests
cd tests/integration && npm test

# E2E tests
cd tests/e2e && npx playwright test

# Performance tests
cd tests/performance && k6 run load-test.js
```

### Test Coverage
- Unit Tests: 95%+
- Integration Tests: 90%+
- E2E Tests: 85%+

## 📊 Monitoring & Observability

- **Metrics**: Prometheus + Grafana dashboards
- **Logging**: Centralized logging with ELK stack
- **Tracing**: Distributed tracing with Jaeger
- **Health Checks**: Comprehensive health monitoring
- **Alerts**: Real-time alerting for critical issues

## 🔄 CI/CD Pipeline

The project includes comprehensive GitHub Actions workflows:

- **Build & Test**: Automated testing on every PR
- **Security Scan**: OWASP dependency check, container scanning
- **Code Quality**: SonarQube analysis
- **Deployment**: Automated deployment to staging/production
- **Performance**: Automated performance testing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow [Conventional Commits](https://conventionalcommits.org/)
- Maintain test coverage above 90%
- Update documentation for new features
- Ensure all security scans pass

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/HealthFlowEgy/healthcare-provider-registry/issues)
- **Discussions**: [GitHub Discussions](https://github.com/HealthFlowEgy/healthcare-provider-registry/discussions)
- **Email**: support@healthcare-registry.com

## 🗺️ Roadmap

### Phase 1 (Current)
- ✅ Core provider registration
- ✅ Blockchain integration
- ✅ Basic verification workflow

### Phase 2 (Q1 2024)
- 🔄 Advanced credential types
- 🔄 Mobile applications
- 🔄 API marketplace

### Phase 3 (Q2 2024)
- 📋 AI-powered verification
- 📋 Cross-border recognition
- 📋 Advanced analytics

## 🏆 Acknowledgments

- [Hyperledger Foundation](https://hyperledger.org/)
- [Keycloak Community](https://keycloak.org/)
- [Spring Boot Team](https://spring.io/projects/spring-boot)
- [React Community](https://reactjs.org/)

---

**Built with ❤️ for the healthcare community**

