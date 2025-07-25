# 🔍 Configuration SonarQube - ISMAIL Platform

Guide complet pour configurer SonarQube avec la plateforme ISMAIL pour les quality gates automatiques.

## 📋 Table des Matières

1. [Options de Déploiement](#options-de-déploiement)
2. [Configuration SonarCloud](#configuration-sonarcloud)
3. [Configuration Self-Hosted](#configuration-self-hosted)
4. [Configuration des Projets](#configuration-des-projets)
5. [Quality Gates](#quality-gates)
6. [Intégration GitHub](#intégration-github)

---

## 🌐 Options de Déploiement

### **Option 1: SonarCloud (Recommandé)**
- ✅ **Gratuit** pour projets open source
- ✅ **Maintenance zéro** - géré par SonarSource
- ✅ **Intégration GitHub** native
- ✅ **Scalabilité** automatique
- ❌ **Données externes** (peut poser des problèmes de compliance)

### **Option 2: Self-Hosted**
- ✅ **Contrôle total** des données
- ✅ **Customisation** avancée
- ✅ **Compliance** enterprise
- ❌ **Maintenance** requise
- ❌ **Coûts** infrastructure

---

## ☁️ Configuration SonarCloud

### **1. Setup Initial**

#### **Étape 1: Créer un compte SonarCloud**
1. Aller sur https://sonarcloud.io
2. Se connecter avec GitHub
3. Autoriser l'accès au repository `miasysteme/Ismail-Plateform`

#### **Étape 2: Importer le projet**
```bash
# URL du projet
https://sonarcloud.io/projects/create

# Sélectionner GitHub
# Choisir miasysteme/Ismail-Plateform
# Configuration automatique
```

#### **Étape 3: Configuration des projets**
```yaml
# Auth Service
Project Key: miasysteme_Ismail-Plateform_auth-service
Project Name: ISMAIL Auth Service
Main Branch: main

# Wallet Service  
Project Key: miasysteme_Ismail-Plateform_wallet-service
Project Name: ISMAIL Wallet Service
Main Branch: main
```

### **2. Génération des Tokens**

#### **Token d'Organisation**
```bash
# Aller sur: https://sonarcloud.io/account/security
# Générer un token avec scope: Execute Analysis
# Nom: ISMAIL-Platform-CI
# Expiration: 90 jours (renouvelable)
```

#### **Configuration GitHub Secret**
```bash
# Ajouter le token dans GitHub Secrets
gh secret set SONAR_TOKEN --body "YOUR_SONAR_TOKEN_HERE"
```

### **3. Configuration des Quality Gates**

#### **Quality Gate ISMAIL**
```yaml
Name: ISMAIL Platform
Conditions:
  Coverage:
    - New Code Coverage: > 80%
    - Overall Code Coverage: > 75%
  
  Maintainability:
    - New Code Maintainability Rating: A
    - New Technical Debt: < 5%
  
  Reliability:
    - New Code Reliability Rating: A
    - New Bugs: 0
  
  Security:
    - New Code Security Rating: A
    - New Vulnerabilities: 0
    - New Security Hotspots Reviewed: 100%
  
  Duplications:
    - New Code Duplicated Lines: < 3%
```

---

## 🏠 Configuration Self-Hosted

### **1. Déploiement Docker**

#### **Docker Compose**
```yaml
# infrastructure/sonarqube/docker-compose.yml
version: '3.8'

services:
  sonarqube:
    image: sonarqube:10.3-community
    container_name: sonarqube
    restart: unless-stopped
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: ${SONAR_DB_PASSWORD}
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: true
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    ports:
      - "9000:9000"
    depends_on:
      - db
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
      nproc:
        soft: 4096
        hard: 4096

  db:
    image: postgres:15-alpine
    container_name: sonarqube-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: ${SONAR_DB_PASSWORD}
      POSTGRES_DB: sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    ports:
      - "5433:5432"

volumes:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:
  postgresql_data:

networks:
  default:
    name: sonarqube-network
```

#### **Variables d'Environnement**
```bash
# .env
SONAR_DB_PASSWORD=your_secure_password_here
```

#### **Déploiement**
```bash
# Démarrer SonarQube
cd infrastructure/sonarqube
docker-compose up -d

# Vérifier les logs
docker-compose logs -f sonarqube

# Accéder à l'interface
open http://localhost:9000
# Login: admin / admin (changer au premier login)
```

### **2. Configuration Kubernetes**

#### **Namespace et Secrets**
```yaml
# infrastructure/k8s/sonarqube/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sonarqube
  labels:
    name: sonarqube

---
apiVersion: v1
kind: Secret
metadata:
  name: sonarqube-secrets
  namespace: sonarqube
type: Opaque
stringData:
  postgres-password: "your_secure_password"
  sonar-admin-password: "your_admin_password"
```

#### **PostgreSQL Deployment**
```yaml
# infrastructure/k8s/sonarqube/postgres.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        env:
        - name: POSTGRES_DB
          value: sonar
        - name: POSTGRES_USER
          value: sonar
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: sonarqube-secrets
              key: postgres-password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: sonarqube
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: sonarqube
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

#### **SonarQube Deployment**
```yaml
# infrastructure/k8s/sonarqube/sonarqube.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarqube
  namespace: sonarqube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sonarqube
  template:
    metadata:
      labels:
        app: sonarqube
    spec:
      initContainers:
      - name: init-sysctl
        image: busybox:1.35
        command:
        - sh
        - -c
        - |
          sysctl -w vm.max_map_count=524288
          sysctl -w fs.file-max=131072
        securityContext:
          privileged: true
      containers:
      - name: sonarqube
        image: sonarqube:10.3-community
        env:
        - name: SONAR_JDBC_URL
          value: jdbc:postgresql://postgres:5432/sonar
        - name: SONAR_JDBC_USERNAME
          value: sonar
        - name: SONAR_JDBC_PASSWORD
          valueFrom:
            secretKeyRef:
              name: sonarqube-secrets
              key: postgres-password
        ports:
        - containerPort: 9000
        volumeMounts:
        - name: sonarqube-data
          mountPath: /opt/sonarqube/data
        - name: sonarqube-logs
          mountPath: /opt/sonarqube/logs
        - name: sonarqube-extensions
          mountPath: /opt/sonarqube/extensions
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
      volumes:
      - name: sonarqube-data
        persistentVolumeClaim:
          claimName: sonarqube-data-pvc
      - name: sonarqube-logs
        persistentVolumeClaim:
          claimName: sonarqube-logs-pvc
      - name: sonarqube-extensions
        persistentVolumeClaim:
          claimName: sonarqube-extensions-pvc

---
apiVersion: v1
kind: Service
metadata:
  name: sonarqube
  namespace: sonarqube
spec:
  selector:
    app: sonarqube
  ports:
  - port: 9000
    targetPort: 9000
  type: LoadBalancer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarqube-data-pvc
  namespace: sonarqube
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarqube-logs-pvc
  namespace: sonarqube
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sonarqube-extensions-pvc
  namespace: sonarqube
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

---

## ⚙️ Configuration des Projets

### **1. Configuration Maven**

#### **Parent POM**
```xml
<!-- services/pom.xml -->
<properties>
    <sonar.organization>miasysteme</sonar.organization>
    <sonar.host.url>https://sonarcloud.io</sonar.host.url>
    <sonar.coverage.jacoco.xmlReportPaths>
        ${project.basedir}/target/site/jacoco/jacoco.xml
    </sonar.coverage.jacoco.xmlReportPaths>
    <sonar.exclusions>
        **/target/**,
        **/generated/**,
        **/*Application.java,
        **/*Config.java,
        **/*Configuration.java
    </sonar.exclusions>
    <sonar.test.exclusions>
        **/src/test/**
    </sonar.test.exclusions>
</properties>

<profiles>
    <profile>
        <id>sonar</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <properties>
            <sonar.sources>src/main/java</sonar.sources>
            <sonar.tests>src/test/java</sonar.tests>
        </properties>
    </profile>
</profiles>
```

#### **Auth Service Configuration**
```xml
<!-- services/auth-service/pom.xml -->
<properties>
    <sonar.projectKey>miasysteme_Ismail-Plateform_auth-service</sonar.projectKey>
    <sonar.projectName>ISMAIL Auth Service</sonar.projectName>
</properties>
```

#### **Wallet Service Configuration**
```xml
<!-- services/wallet-service/pom.xml -->
<properties>
    <sonar.projectKey>miasysteme_Ismail-Plateform_wallet-service</sonar.projectKey>
    <sonar.projectName>ISMAIL Wallet Service</sonar.projectName>
</properties>
```

### **2. Configuration JaCoCo**

#### **Plugin Configuration**
```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.10</version>
    <executions>
        <execution>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
        </execution>
        <execution>
            <id>check</id>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <rules>
                    <rule>
                        <element>BUNDLE</element>
                        <limits>
                            <limit>
                                <counter>INSTRUCTION</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.80</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

---

## 🎯 Quality Gates

### **Configuration Quality Gate ISMAIL**

#### **Création via API**
```bash
# Créer le quality gate
curl -X POST \
  -H "Authorization: Bearer $SONAR_TOKEN" \
  -d "name=ISMAIL Platform" \
  "https://sonarcloud.io/api/qualitygates/create"

# Ajouter les conditions
curl -X POST \
  -H "Authorization: Bearer $SONAR_TOKEN" \
  -d "gateId=1&metric=new_coverage&op=LT&error=80" \
  "https://sonarcloud.io/api/qualitygates/create_condition"
```

#### **Conditions Recommandées**
```yaml
New Code Coverage: > 80%
Overall Code Coverage: > 75%
New Code Maintainability Rating: A
New Code Reliability Rating: A
New Code Security Rating: A
New Bugs: 0
New Vulnerabilities: 0
New Security Hotspots Reviewed: 100%
New Code Duplicated Lines: < 3%
New Technical Debt: < 5%
```

---

## 🔗 Intégration GitHub

### **1. Configuration Webhook**
```bash
# SonarCloud configure automatiquement les webhooks
# Vérifier sur: https://sonarcloud.io/project/webhooks
```

### **2. Status Checks**
```yaml
# Les status checks sont automatiquement ajoutés:
- SonarCloud Code Analysis
- Quality Gate Status
```

### **3. Pull Request Decoration**
```yaml
# Configuration automatique pour:
- Commentaires sur les PR
- Annotations sur les lignes modifiées
- Résumé des métriques
- Lien vers le rapport détaillé
```

---

## ✅ Validation

### **Test de Configuration**
```bash
# Lancer l'analyse locale
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=miasysteme_Ismail-Plateform_auth-service \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.login=$SONAR_TOKEN

# Vérifier les résultats
open https://sonarcloud.io/dashboard?id=miasysteme_Ismail-Plateform_auth-service
```

---

**🎯 SonarQube configuré pour des quality gates automatiques !**
