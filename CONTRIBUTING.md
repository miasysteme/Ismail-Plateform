# 🤝 Guide de Contribution - ISMAIL Platform

Merci de votre intérêt pour contribuer à la plateforme ISMAIL ! Ce guide vous aidera à comprendre comment participer efficacement au développement.

## 📋 Table des Matières

1. [Code de Conduite](#code-de-conduite)
2. [Comment Contribuer](#comment-contribuer)
3. [Standards de Développement](#standards-de-développement)
4. [Workflow Git](#workflow-git)
5. [Tests et Qualité](#tests-et-qualité)
6. [Documentation](#documentation)
7. [Review Process](#review-process)

## 🤝 Code de Conduite

En participant à ce projet, vous acceptez de respecter notre [Code de Conduite](CODE_OF_CONDUCT.md). Nous nous engageons à maintenir un environnement accueillant et inclusif pour tous.

## 🚀 Comment Contribuer

### Types de Contributions

- 🐛 **Bug Reports** - Signaler des problèmes
- ✨ **Feature Requests** - Proposer de nouvelles fonctionnalités
- 📝 **Documentation** - Améliorer la documentation
- 🧪 **Tests** - Ajouter ou améliorer les tests
- 🔧 **Code** - Corriger des bugs ou implémenter des fonctionnalités

### Avant de Commencer

1. **Vérifiez les Issues existantes** pour éviter les doublons
2. **Discutez des changements majeurs** en créant une issue d'abord
3. **Lisez la documentation** pour comprendre l'architecture
4. **Configurez votre environnement** de développement

## 📏 Standards de Développement

### Java / Spring Boot

```java
// Utilisez les annotations Spring appropriées
@RestController
@RequestMapping("/api/auth")
@Validated
@Slf4j
public class AuthController {
    
    // Javadoc obligatoire pour les méthodes publiques
    /**
     * Authentifie un utilisateur avec email et mot de passe
     * 
     * @param request Données de connexion
     * @return Réponse d'authentification avec tokens
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        // Implementation
    }
}
```

### Conventions de Nommage

- **Classes** : PascalCase (`AuthService`, `WalletController`)
- **Méthodes** : camelCase (`authenticateUser`, `processPayment`)
- **Variables** : camelCase (`userId`, `transactionAmount`)
- **Constantes** : UPPER_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`)
- **Packages** : lowercase (`com.ismail.platform.auth`)

### Structure des Packages

```
com.ismail.platform.{service}
├── controller/          # REST Controllers
├── service/            # Business Logic
├── repository/         # Data Access
├── domain/
│   ├── entity/        # JPA Entities
│   └── dto/           # Data Transfer Objects
├── config/            # Configuration Classes
├── exception/         # Custom Exceptions
└── util/              # Utility Classes
```

## 🔄 Workflow Git

### Branches

- **`main`** - Code de production stable
- **`develop`** - Branche de développement principale
- **`feature/ISSUE-123-description`** - Nouvelles fonctionnalités
- **`bugfix/ISSUE-456-description`** - Corrections de bugs
- **`hotfix/ISSUE-789-description`** - Corrections urgentes production

### Commits

Utilisez le format [Conventional Commits](https://www.conventionalcommits.org/) :

```bash
# Format
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]

# Exemples
feat(auth): add biometric authentication support
fix(wallet): resolve transaction timeout issue
docs(api): update authentication endpoints documentation
test(integration): add wallet service integration tests
```

### Types de Commits

- **feat** : Nouvelle fonctionnalité
- **fix** : Correction de bug
- **docs** : Documentation uniquement
- **style** : Formatage, points-virgules manquants, etc.
- **refactor** : Refactoring sans changement fonctionnel
- **test** : Ajout ou modification de tests
- **chore** : Maintenance, dépendances, etc.

### Processus de Pull Request

1. **Créer une branche** depuis `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/ISSUE-123-new-feature
   ```

2. **Développer et tester** localement
   ```bash
   # Faire vos modifications
   mvn clean test
   mvn verify
   ```

3. **Commit et push**
   ```bash
   git add .
   git commit -m "feat(module): add new feature"
   git push origin feature/ISSUE-123-new-feature
   ```

4. **Créer la Pull Request**
   - Titre descriptif
   - Description détaillée des changements
   - Référence à l'issue (`Closes #123`)
   - Screenshots si applicable

## 🧪 Tests et Qualité

### Couverture de Tests

- **Minimum requis** : 80% de couverture
- **Tests unitaires** : Toutes les méthodes publiques
- **Tests d'intégration** : Scénarios end-to-end
- **Tests de performance** : Endpoints critiques

### Types de Tests

```java
// Test unitaire
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {
    
    @Mock
    private UserRepository userRepository;
    
    @InjectMocks
    private AuthService authService;
    
    @Test
    @DisplayName("Should authenticate user with valid credentials")
    void shouldAuthenticateUserWithValidCredentials() {
        // Given
        // When
        // Then
    }
}

// Test d'intégration
@SpringBootTest
@Testcontainers
class AuthControllerIntegrationTest {
    
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15");
    
    @Test
    void shouldRegisterNewUser() {
        // Test avec base de données réelle
    }
}
```

### Quality Gates

Avant chaque merge, vérifiez :

- ✅ Tous les tests passent
- ✅ Couverture de code >80%
- ✅ SonarQube quality gate
- ✅ Pas de vulnérabilités critiques
- ✅ Documentation à jour

## 📚 Documentation

### Javadoc

```java
/**
 * Service de gestion de l'authentification des utilisateurs.
 * 
 * <p>Ce service gère l'inscription, la connexion, et la validation
 * des utilisateurs avec support de l'authentification biométrique.</p>
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 * @since 1.0.0
 */
@Service
public class AuthService {
    
    /**
     * Authentifie un utilisateur avec ses identifiants.
     * 
     * @param email Email de l'utilisateur
     * @param password Mot de passe en clair
     * @return Token d'authentification si succès
     * @throws AuthenticationException Si les identifiants sont invalides
     * @throws UserLockedException Si le compte est verrouillé
     */
    public AuthToken authenticate(String email, String password) {
        // Implementation
    }
}
```

### README des Modules

Chaque module doit avoir son propre README avec :

- Description du module
- APIs exposées
- Configuration requise
- Exemples d'utilisation
- Dépendances

### API Documentation

- Utilisez **OpenAPI 3.0** avec annotations Spring
- Documentez tous les endpoints
- Incluez des exemples de requêtes/réponses
- Spécifiez les codes d'erreur

## 👀 Review Process

### Checklist du Reviewer

#### Code Quality
- [ ] Code lisible et bien structuré
- [ ] Respect des conventions de nommage
- [ ] Pas de code dupliqué
- [ ] Gestion appropriée des erreurs
- [ ] Logging approprié

#### Tests
- [ ] Tests unitaires présents
- [ ] Tests d'intégration si nécessaire
- [ ] Couverture de code suffisante
- [ ] Tests passent en local

#### Sécurité
- [ ] Pas de secrets en dur
- [ ] Validation des entrées
- [ ] Autorisation appropriée
- [ ] Pas de vulnérabilités évidentes

#### Performance
- [ ] Pas de requêtes N+1
- [ ] Pagination pour les listes
- [ ] Cache approprié
- [ ] Optimisation des requêtes DB

#### Documentation
- [ ] Javadoc à jour
- [ ] README mis à jour si nécessaire
- [ ] API documentation complète

### Feedback Constructif

- **Soyez spécifique** : Pointez les lignes exactes
- **Expliquez le pourquoi** : Justifiez vos suggestions
- **Proposez des solutions** : Ne faites pas que critiquer
- **Soyez respectueux** : Critique le code, pas la personne

## 🚀 Environnement de Développement

### Setup Initial

```bash
# 1. Fork et clone
git clone https://github.com/YOUR_USERNAME/Ismail-Plateform.git
cd Ismail-Plateform

# 2. Configuration Git
git config user.name "Your Name"
git config user.email "your.email@example.com"

# 3. Ajouter le remote upstream
git remote add upstream https://github.com/miasysteme/Ismail-Plateform.git

# 4. Installer les dépendances
mvn clean install

# 5. Démarrer l'infrastructure locale
docker-compose -f infrastructure/docker/docker-compose.dev.yml up -d
```

### Outils Recommandés

- **IDE** : IntelliJ IDEA ou VS Code
- **Java** : OpenJDK 21
- **Maven** : 3.9+
- **Docker** : Latest stable
- **Git** : 2.40+

### Plugins Utiles

#### IntelliJ IDEA
- SonarLint
- CheckStyle-IDEA
- Lombok
- Spring Boot Assistant

#### VS Code
- Extension Pack for Java
- Spring Boot Extension Pack
- SonarLint
- GitLens

## 📞 Aide et Support

### Où Demander de l'Aide

- **💬 Discussions GitHub** : Questions générales
- **🐛 Issues GitHub** : Bugs et problèmes
- **📧 Email** : dev-team@ismail-platform.com
- **💬 Slack** : #dev-help (pour les contributeurs réguliers)

### Ressources Utiles

- [Architecture Documentation](docs/architecture.md)
- [API Documentation](docs/api.md)
- [Deployment Guide](infrastructure/README.md)
- [Testing Strategy](tests/README.md)

---

**🙏 Merci de contribuer à ISMAIL Platform !**

*Ensemble, nous construisons l'avenir des services digitaux en Afrique de l'Ouest.*
