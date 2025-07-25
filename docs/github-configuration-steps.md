# 🚀 Guide d'Exécution - Configuration GitHub ISMAIL

Guide pas à pas pour configurer complètement GitHub avec tous les secrets et environments.

## 📋 Checklist de Configuration

### ✅ **Étape 1: Préparation**
- [ ] GitHub CLI installé (`gh --version`)
- [ ] Authentification GitHub (`gh auth login`)
- [ ] Accès admin au repository
- [ ] OpenSSL installé pour génération secrets

### ✅ **Étape 2: Génération des Secrets**
- [ ] Exécuter le script de génération
- [ ] Configurer les services externes
- [ ] Valider les secrets générés

### ✅ **Étape 3: Configuration GitHub**
- [ ] Upload des secrets repository
- [ ] Configuration des environments
- [ ] Setup des protection rules

### ✅ **Étape 4: Configuration SonarQube**
- [ ] Setup SonarCloud ou self-hosted
- [ ] Configuration des projets
- [ ] Quality gates

### ✅ **Étape 5: Validation**
- [ ] Test de la configuration
- [ ] Validation pipeline CI/CD
- [ ] Tests end-to-end

---

## 🔧 **Étape 1: Préparation**

### **Installation GitHub CLI**
```bash
# Windows (avec Chocolatey)
choco install gh

# macOS (avec Homebrew)
brew install gh

# Linux (Ubuntu/Debian)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### **Authentification GitHub**
```bash
# Se connecter à GitHub
gh auth login

# Sélectionner:
# - GitHub.com
# - HTTPS
# - Yes (authenticate Git)
# - Login with a web browser

# Vérifier l'authentification
gh auth status
```

### **Vérification des Permissions**
```bash
# Vérifier l'accès au repository
gh repo view miasysteme/Ismail-Plateform

# Vérifier les permissions admin
gh api repos/miasysteme/Ismail-Plateform --jq '.permissions'
```

---

## 🔐 **Étape 2: Génération des Secrets**

### **Exécution du Script**
```bash
# Rendre le script exécutable
chmod +x scripts/generate-secrets.sh

# Générer tous les secrets
./scripts/generate-secrets.sh

# Vérifier les fichiers générés
ls -la .secrets/
```

### **Configuration des Services Externes**

#### **SendGrid API Key**
1. Aller sur https://app.sendgrid.com/settings/api_keys
2. Créer une nouvelle API key
3. Copier la clé générée
4. Éditer `.secrets/generated-secrets.env`
5. Remplacer `REPLACE_WITH_YOUR_SENDGRID_KEY`

#### **Slack Webhook URL**
1. Aller sur https://api.slack.com/apps
2. Créer une nouvelle app ou utiliser existante
3. Activer "Incoming Webhooks"
4. Créer un webhook pour le canal #ci-cd
5. Copier l'URL du webhook
6. Remplacer `REPLACE_WITH_YOUR_WEBHOOK` dans le fichier secrets

#### **AWS Credentials**
1. Aller sur AWS IAM Console
2. Créer un utilisateur pour CI/CD
3. Attacher les policies nécessaires:
   - AmazonEKSClusterPolicy
   - AmazonS3FullAccess (pour backups)
   - AmazonRDSFullAccess (pour bases de données)
4. Générer les access keys
5. Remplacer dans le fichier secrets

### **Upload des Secrets vers GitHub**
```bash
# Rendre le script exécutable
chmod +x .secrets/upload-to-github.sh

# Uploader les secrets
./.secrets/upload-to-github.sh

# Vérifier sur GitHub
open https://github.com/miasysteme/Ismail-Plateform/settings/secrets
```

---

## 🌍 **Étape 3: Configuration GitHub**

### **Configuration des Environments**
```bash
# Rendre le script exécutable
chmod +x scripts/setup-github-environments.sh

# Configurer les environments
./scripts/setup-github-environments.sh

# Vérifier la configuration
open https://github.com/miasysteme/Ismail-Plateform/settings/environments
```

### **Configuration Manuelle des Reviewers**

#### **Environment production-approval**
1. Aller sur https://github.com/miasysteme/Ismail-Plateform/settings/environments
2. Cliquer sur "production-approval"
3. Dans "Required reviewers", ajouter:
   - Votre compte GitHub
   - Autres administrateurs du projet
4. Cocher "Prevent self-review"
5. Sauvegarder

### **Vérification des Branch Protection Rules**
```bash
# Vérifier les rules pour main
gh api repos/miasysteme/Ismail-Plateform/branches/main/protection

# Vérifier les rules pour develop
gh api repos/miasysteme/Ismail-Plateform/branches/develop/protection
```

---

## 🔍 **Étape 4: Configuration SonarQube**

### **Option A: SonarCloud (Recommandé)**

#### **Setup SonarCloud**
1. Aller sur https://sonarcloud.io
2. Se connecter avec GitHub
3. Importer le repository `miasysteme/Ismail-Plateform`
4. Configurer l'organisation

#### **Configuration des Projets**
```bash
# Les projets seront créés automatiquement:
# - miasysteme_Ismail-Plateform_auth-service
# - miasysteme_Ismail-Plateform_wallet-service
```

#### **Génération du Token**
1. Aller sur https://sonarcloud.io/account/security
2. Générer un token "ISMAIL-Platform-CI"
3. Copier le token
4. L'ajouter aux secrets GitHub:
```bash
gh secret set SONAR_TOKEN --body "YOUR_SONAR_TOKEN_HERE"
```

### **Option B: Self-Hosted**
```bash
# Déployer SonarQube avec Docker
cd infrastructure/sonarqube
docker-compose up -d

# Accéder à l'interface
open http://localhost:9000
# Login: admin / admin (changer au premier login)
```

### **Configuration Quality Gates**
1. Aller sur SonarCloud > Quality Gates
2. Créer "ISMAIL Platform" quality gate
3. Configurer les conditions selon docs/sonarqube-setup.md
4. Assigner aux projets ISMAIL

---

## ✅ **Étape 5: Validation**

### **Validation Automatique**
```bash
# Rendre le script exécutable
chmod +x scripts/validate-github-config.sh

# Exécuter la validation
./scripts/validate-github-config.sh

# Consulter le rapport généré
ls github-config-validation-*.md
```

### **Test de la Pipeline CI/CD**

#### **Test 1: Push sur develop**
```bash
# Créer un commit de test
echo "# Test CI/CD" > TEST.md
git add TEST.md
git commit -m "test: validate CI/CD pipeline"
git push origin develop

# Vérifier l'exécution
open https://github.com/miasysteme/Ismail-Plateform/actions
```

#### **Test 2: Pull Request**
```bash
# Créer une branche feature
git checkout -b feature/test-pr
echo "Test PR" >> TEST.md
git add TEST.md
git commit -m "feat: test pull request workflow"
git push origin feature/test-pr

# Créer la PR
gh pr create --title "Test PR Workflow" --body "Test de la pipeline CI/CD"

# Vérifier les status checks
gh pr status
```

#### **Test 3: Déploiement Production (Simulation)**
```bash
# Créer un tag de test
git checkout main
git tag v0.1.1-test
git push origin v0.1.1-test

# Vérifier que l'approval est demandé
open https://github.com/miasysteme/Ismail-Plateform/actions
```

### **Validation des Secrets**
```bash
# Tester la connectivité (si configuré)
# AWS
aws sts get-caller-identity

# SonarQube
curl -H "Authorization: Bearer $SONAR_TOKEN" \
  https://sonarcloud.io/api/authentication/validate
```

---

## 🚨 **Dépannage**

### **Problèmes Courants**

#### **GitHub CLI non authentifié**
```bash
gh auth logout
gh auth login
```

#### **Permissions insuffisantes**
```bash
# Vérifier les permissions
gh api repos/miasysteme/Ismail-Plateform --jq '.permissions'

# Demander les permissions admin au propriétaire
```

#### **Secrets non visibles**
```bash
# Les secrets ne sont pas visibles après upload
# Vérifier avec:
gh secret list

# Si absent, re-uploader:
gh secret set SECRET_NAME --body "SECRET_VALUE"
```

#### **Workflows qui ne se déclenchent pas**
```bash
# Vérifier les permissions Actions
gh api repos/miasysteme/Ismail-Plateform/actions/permissions

# Activer les Actions si nécessaire
gh api repos/miasysteme/Ismail-Plateform/actions/permissions \
  --method PUT \
  --field enabled=true \
  --field allowed_actions=all
```

### **Logs de Debug**
```bash
# Logs détaillés GitHub CLI
gh --debug api repos/miasysteme/Ismail-Plateform

# Logs des workflows
gh run list
gh run view RUN_ID --log
```

---

## 📞 **Support**

### **En cas de problème**
1. Consulter les logs détaillés
2. Vérifier la documentation dans `docs/`
3. Créer une issue sur GitHub
4. Contacter l'équipe technique

### **Ressources Utiles**
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [SonarCloud Documentation](https://docs.sonarcloud.io/)

---

**🎯 Configuration GitHub complète pour ISMAIL Platform !**

*Suivez ce guide étape par étape pour une configuration sans erreur.*
