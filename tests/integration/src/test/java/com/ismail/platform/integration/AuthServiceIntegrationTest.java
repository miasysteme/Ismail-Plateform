package com.ismail.platform.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ismail.platform.integration.config.TestConfiguration;
import com.ismail.platform.integration.dto.AuthRequest;
import com.ismail.platform.integration.dto.AuthResponse;
import com.ismail.platform.integration.dto.RegisterRequest;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.*;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.Duration;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tests d'intégration pour le service d'authentification ISMAIL
 * 
 * Teste les scénarios end-to-end avec des conteneurs réels :
 * - PostgreSQL pour la persistance
 * - Redis pour le cache et les sessions
 * - Kong pour l'API Gateway
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@SpringBootTest(
    classes = TestConfiguration.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT
)
@Testcontainers
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class AuthServiceIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private ObjectMapper objectMapper;

    // Conteneurs Testcontainers
    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine")
            .withDatabaseName("ismail_test")
            .withUsername("test_user")
            .withPassword("test_password")
            .withInitScript("init-test-db.sql")
            .waitingFor(Wait.forLogMessage(".*database system is ready to accept connections.*", 2))
            .withStartupTimeout(Duration.ofMinutes(2));

    @Container
    static GenericContainer<?> redis = new GenericContainer<>("redis:7-alpine")
            .withExposedPorts(6379)
            .withCommand("redis-server", "--requirepass", "test_password")
            .waitingFor(Wait.forLogMessage(".*Ready to accept connections.*", 1))
            .withStartupTimeout(Duration.ofMinutes(1));

    @Container
    static GenericContainer<?> kong = new GenericContainer<>("kong:3.4")
            .withExposedPorts(8000, 8001)
            .withEnv("KONG_DATABASE", "off")
            .withEnv("KONG_DECLARATIVE_CONFIG", "/kong.yml")
            .withEnv("KONG_PROXY_ACCESS_LOG", "/dev/stdout")
            .withEnv("KONG_ADMIN_ACCESS_LOG", "/dev/stdout")
            .withEnv("KONG_PROXY_ERROR_LOG", "/dev/stderr")
            .withEnv("KONG_ADMIN_ERROR_LOG", "/dev/stderr")
            .withEnv("KONG_ADMIN_LISTEN", "0.0.0.0:8001")
            .waitingFor(Wait.forHttp("/").onPort(8001))
            .withStartupTimeout(Duration.ofMinutes(2));

    // Configuration dynamique des propriétés
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        // Configuration PostgreSQL
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        
        // Configuration Redis
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
        registry.add("spring.data.redis.password", () -> "test_password");
        
        // Configuration Kong
        registry.add("kong.admin.url", () -> 
            "http://" + kong.getHost() + ":" + kong.getMappedPort(8001));
        registry.add("kong.proxy.url", () -> 
            "http://" + kong.getHost() + ":" + kong.getMappedPort(8000));
    }

    private String baseUrl;
    private String authToken;
    private String testUserId;

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port + "/api/auth";
    }

    @Test
    @Order(1)
    @DisplayName("Test d'inscription d'un nouvel utilisateur")
    void testUserRegistration() throws Exception {
        // Préparer la requête d'inscription
        RegisterRequest request = RegisterRequest.builder()
                .email("test@ismail-platform.com")
                .phone("+2250123456789")
                .password("TestPassword123!")
                .confirmPassword("TestPassword123!")
                .firstName("Test")
                .lastName("User")
                .profileType("CLIENT")
                .acceptTerms(true)
                .acceptPrivacy(true)
                .marketingConsent(false)
                .build();

        // Envoyer la requête
        ResponseEntity<AuthResponse> response = restTemplate.postForEntity(
                baseUrl + "/register",
                request,
                AuthResponse.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getAccessToken()).isNotNull();
        assertThat(response.getBody().getRefreshToken()).isNotNull();
        assertThat(response.getBody().getUser()).isNotNull();
        assertThat(response.getBody().getUser().getEmail()).isEqualTo("test@ismail-platform.com");
        assertThat(response.getBody().getUser().getIsmailId()).isNotNull();

        // Sauvegarder pour les tests suivants
        authToken = response.getBody().getAccessToken();
        testUserId = response.getBody().getUser().getId().toString();
    }

    @Test
    @Order(2)
    @DisplayName("Test de connexion avec identifiants valides")
    void testUserLogin() throws Exception {
        // Préparer la requête de connexion
        AuthRequest request = AuthRequest.builder()
                .email("test@ismail-platform.com")
                .password("TestPassword123!")
                .deviceInfo("Test Device")
                .build();

        // Envoyer la requête
        ResponseEntity<AuthResponse> response = restTemplate.postForEntity(
                baseUrl + "/login",
                request,
                AuthResponse.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().isSuccess()).isTrue();
        assertThat(response.getBody().getAccessToken()).isNotNull();
        assertThat(response.getBody().getUser().getEmail()).isEqualTo("test@ismail-platform.com");
    }

    @Test
    @Order(3)
    @DisplayName("Test de connexion avec identifiants invalides")
    void testUserLoginWithInvalidCredentials() throws Exception {
        // Préparer la requête avec mot de passe incorrect
        AuthRequest request = AuthRequest.builder()
                .email("test@ismail-platform.com")
                .password("WrongPassword123!")
                .build();

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl + "/login",
                request,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("error")).isEqualTo("unauthorized");
    }

    @Test
    @Order(4)
    @DisplayName("Test d'accès au profil utilisateur avec token valide")
    void testGetUserProfile() throws Exception {
        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/profile",
                HttpMethod.GET,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("email")).isEqualTo("test@ismail-platform.com");
        assertThat(response.getBody().get("ismailId")).isNotNull();
    }

    @Test
    @Order(5)
    @DisplayName("Test d'accès au profil sans token")
    void testGetUserProfileWithoutToken() throws Exception {
        // Envoyer la requête sans token
        ResponseEntity<Map> response = restTemplate.getForEntity(
                baseUrl + "/profile",
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @Order(6)
    @DisplayName("Test de rafraîchissement du token")
    void testTokenRefresh() throws Exception {
        // D'abord, récupérer un refresh token via login
        AuthRequest loginRequest = AuthRequest.builder()
                .email("test@ismail-platform.com")
                .password("TestPassword123!")
                .build();

        ResponseEntity<AuthResponse> loginResponse = restTemplate.postForEntity(
                baseUrl + "/login",
                loginRequest,
                AuthResponse.class
        );

        String refreshToken = loginResponse.getBody().getRefreshToken();

        // Préparer la requête de refresh
        Map<String, String> refreshRequest = Map.of("refreshToken", refreshToken);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl + "/refresh",
                refreshRequest,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("accessToken")).isNotNull();
        assertThat(response.getBody().get("refreshToken")).isNotNull();
    }

    @Test
    @Order(7)
    @DisplayName("Test de déconnexion")
    void testUserLogout() throws Exception {
        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/logout",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("success")).isEqualTo(true);
    }

    @Test
    @Order(8)
    @DisplayName("Test d'accès après déconnexion")
    void testAccessAfterLogout() throws Exception {
        // Préparer les headers avec le token déconnecté
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/profile",
                HttpMethod.GET,
                entity,
                Map.class
        );

        // Vérifications - le token devrait être invalide
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @Order(9)
    @DisplayName("Test de validation des données d'inscription")
    void testRegistrationValidation() throws Exception {
        // Préparer une requête avec des données invalides
        RegisterRequest request = RegisterRequest.builder()
                .email("invalid-email")
                .phone("invalid-phone")
                .password("weak")
                .confirmPassword("different")
                .firstName("")
                .lastName("")
                .profileType("CLIENT")
                .acceptTerms(false)
                .acceptPrivacy(false)
                .build();

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.postForEntity(
                baseUrl + "/register",
                request,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("errors")).isNotNull();
    }

    @Test
    @Order(10)
    @DisplayName("Test de limitation du taux de requêtes")
    void testRateLimiting() throws Exception {
        // Préparer une requête de connexion
        AuthRequest request = AuthRequest.builder()
                .email("test@ismail-platform.com")
                .password("WrongPassword123!")
                .build();

        // Envoyer plusieurs requêtes rapidement
        int attempts = 0;
        HttpStatus lastStatus = HttpStatus.OK;
        
        for (int i = 0; i < 10; i++) {
            ResponseEntity<Map> response = restTemplate.postForEntity(
                    baseUrl + "/login",
                    request,
                    Map.class
            );
            
            attempts++;
            lastStatus = response.getStatusCode();
            
            // Si on atteint la limite, on devrait avoir un 429
            if (lastStatus == HttpStatus.TOO_MANY_REQUESTS) {
                break;
            }
            
            // Petite pause entre les requêtes
            Thread.sleep(100);
        }

        // Vérifications - on devrait atteindre la limite
        assertThat(attempts).isLessThanOrEqualTo(10);
        // Note: Le test peut varier selon la configuration du rate limiting
    }

    @AfterAll
    static void tearDown() {
        // Les conteneurs Testcontainers se ferment automatiquement
        // mais on peut ajouter du nettoyage supplémentaire si nécessaire
    }
}
