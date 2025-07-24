package com.ismail.platform.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ismail.platform.integration.config.TestConfiguration;
import com.ismail.platform.integration.dto.*;
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

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Tests d'intégration pour le service portefeuille ISMAIL
 * 
 * Teste les scénarios end-to-end pour :
 * - Gestion des portefeuilles
 * - Transactions et transferts
 * - Commissions commerciales
 * - Intégration avec les moyens de paiement
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
class WalletServiceIntegrationTest {

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

    // Configuration dynamique des propriétés
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
        registry.add("spring.data.redis.password", () -> "test_password");
    }

    private String baseUrl;
    private String authToken;
    private String walletId;

    @BeforeEach
    void setUp() {
        baseUrl = "http://localhost:" + port + "/api/wallet";
        
        // Créer un utilisateur et récupérer le token pour les tests
        authToken = createTestUserAndGetToken();
    }

    private String createTestUserAndGetToken() {
        // Créer un utilisateur de test via le service auth
        RegisterRequest registerRequest = RegisterRequest.builder()
                .email("wallet-test@ismail-platform.com")
                .phone("+2250123456790")
                .password("TestPassword123!")
                .confirmPassword("TestPassword123!")
                .firstName("Wallet")
                .lastName("Test")
                .profileType("CLIENT")
                .acceptTerms(true)
                .acceptPrivacy(true)
                .build();

        ResponseEntity<AuthResponse> authResponse = restTemplate.postForEntity(
                "http://localhost:" + port + "/api/auth/register",
                registerRequest,
                AuthResponse.class
        );

        return authResponse.getBody().getAccessToken();
    }

    @Test
    @Order(1)
    @DisplayName("Test de récupération du solde du portefeuille")
    void testGetWalletBalance() throws Exception {
        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/balance",
                HttpMethod.GET,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("balance")).isNotNull();
        assertThat(response.getBody().get("currency")).isEqualTo("XOF");
        
        // Sauvegarder l'ID du portefeuille
        walletId = response.getBody().get("walletId").toString();
    }

    @Test
    @Order(2)
    @DisplayName("Test de crédit du portefeuille")
    void testCreditWallet() throws Exception {
        // Préparer la requête de crédit
        CreditWalletRequest request = CreditWalletRequest.builder()
                .amount(new BigDecimal("10000.00"))
                .currency("XOF")
                .paymentMethod("ORANGE_MONEY")
                .paymentReference("OM123456789")
                .description("Test credit")
                .build();

        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<CreditWalletRequest> entity = new HttpEntity<>(request, headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/credit",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("success")).isEqualTo(true);
        assertThat(response.getBody().get("transactionId")).isNotNull();
        assertThat(response.getBody().get("newBalance")).isNotNull();
    }

    @Test
    @Order(3)
    @DisplayName("Test de transfert entre portefeuilles")
    void testTransferBetweenWallets() throws Exception {
        // Créer un deuxième utilisateur pour le transfert
        RegisterRequest recipientRequest = RegisterRequest.builder()
                .email("recipient@ismail-platform.com")
                .phone("+2250123456791")
                .password("TestPassword123!")
                .confirmPassword("TestPassword123!")
                .firstName("Recipient")
                .lastName("Test")
                .profileType("CLIENT")
                .acceptTerms(true)
                .acceptPrivacy(true)
                .build();

        ResponseEntity<AuthResponse> recipientAuth = restTemplate.postForEntity(
                "http://localhost:" + port + "/api/auth/register",
                recipientRequest,
                AuthResponse.class
        );

        String recipientIsmailId = recipientAuth.getBody().getUser().getIsmailId();

        // Préparer la requête de transfert
        TransferRequest request = TransferRequest.builder()
                .recipientIsmailId(recipientIsmailId)
                .amount(new BigDecimal("1000.00"))
                .currency("XOF")
                .description("Test transfer")
                .pin("1234")
                .build();

        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<TransferRequest> entity = new HttpEntity<>(request, headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfer",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("success")).isEqualTo(true);
        assertThat(response.getBody().get("transactionId")).isNotNull();
    }

    @Test
    @Order(4)
    @DisplayName("Test de transfert avec solde insuffisant")
    void testTransferWithInsufficientBalance() throws Exception {
        // Préparer une requête avec un montant trop élevé
        TransferRequest request = TransferRequest.builder()
                .recipientIsmailId("CI241201-TEST-CL")
                .amount(new BigDecimal("1000000.00")) // Montant très élevé
                .currency("XOF")
                .description("Test insufficient balance")
                .pin("1234")
                .build();

        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<TransferRequest> entity = new HttpEntity<>(request, headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfer",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("error")).isEqualTo("insufficient_balance");
    }

    @Test
    @Order(5)
    @DisplayName("Test de récupération de l'historique des transactions")
    void testGetTransactionHistory() throws Exception {
        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transactions?page=0&size=10",
                HttpMethod.GET,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("content")).isNotNull();
        assertThat(response.getBody().get("totalElements")).isNotNull();
    }

    @Test
    @Order(6)
    @DisplayName("Test de retrait vers mobile money")
    void testWithdrawToMobileMoney() throws Exception {
        // Préparer la requête de retrait
        WithdrawRequest request = WithdrawRequest.builder()
                .amount(new BigDecimal("500.00"))
                .currency("XOF")
                .withdrawMethod("ORANGE_MONEY")
                .phoneNumber("+2250123456789")
                .pin("1234")
                .build();

        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<WithdrawRequest> entity = new HttpEntity<>(request, headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/withdraw",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("success")).isEqualTo(true);
        assertThat(response.getBody().get("transactionId")).isNotNull();
    }

    @Test
    @Order(7)
    @DisplayName("Test de validation du PIN")
    void testPinValidation() throws Exception {
        // Préparer une requête avec un PIN incorrect
        TransferRequest request = TransferRequest.builder()
                .recipientIsmailId("CI241201-TEST-CL")
                .amount(new BigDecimal("100.00"))
                .currency("XOF")
                .description("Test wrong PIN")
                .pin("0000") // PIN incorrect
                .build();

        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<TransferRequest> entity = new HttpEntity<>(request, headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfer",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("error")).isEqualTo("invalid_pin");
    }

    @Test
    @Order(8)
    @DisplayName("Test de récupération des statistiques du portefeuille")
    void testGetWalletStats() throws Exception {
        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/stats",
                HttpMethod.GET,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("totalTransactions")).isNotNull();
        assertThat(response.getBody().get("totalCredits")).isNotNull();
        assertThat(response.getBody().get("totalDebits")).isNotNull();
    }

    @Test
    @Order(9)
    @DisplayName("Test de vérification des limites de transaction")
    void testTransactionLimits() throws Exception {
        // Préparer une requête qui dépasse les limites quotidiennes
        TransferRequest request = TransferRequest.builder()
                .recipientIsmailId("CI241201-TEST-CL")
                .amount(new BigDecimal("2000000.00")) // Dépasse la limite quotidienne
                .currency("XOF")
                .description("Test daily limit")
                .pin("1234")
                .build();

        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<TransferRequest> entity = new HttpEntity<>(request, headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/transfer",
                HttpMethod.POST,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("error")).isEqualTo("daily_limit_exceeded");
    }

    @Test
    @Order(10)
    @DisplayName("Test de conversion de devises")
    void testCurrencyConversion() throws Exception {
        // Préparer les headers avec token
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(authToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Envoyer la requête
        ResponseEntity<Map> response = restTemplate.exchange(
                baseUrl + "/convert?amount=1000&from=XOF&to=EUR",
                HttpMethod.GET,
                entity,
                Map.class
        );

        // Vérifications
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("convertedAmount")).isNotNull();
        assertThat(response.getBody().get("exchangeRate")).isNotNull();
    }

    @AfterAll
    static void tearDown() {
        // Les conteneurs Testcontainers se ferment automatiquement
    }
}
