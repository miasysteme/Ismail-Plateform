package com.ismail.platform.auth.controller;

import com.ismail.platform.auth.dto.request.*;
import com.ismail.platform.auth.dto.response.*;
import com.ismail.platform.auth.service.AuthService;
import com.ismail.platform.auth.service.KycService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

/**
 * Contrôleur REST pour l'authentification et la gestion des utilisateurs
 * 
 * Fournit les endpoints pour :
 * - Inscription et connexion des utilisateurs
 * - Gestion des sessions et tokens JWT
 * - Vérification KYC biométrique
 * - Gestion des mots de passe
 * - Cartes d'identité professionnelles
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "API d'authentification et gestion des utilisateurs")
public class AuthController {

    private final AuthService authService;
    private final KycService kycService;

    @Autowired
    public AuthController(AuthService authService, KycService kycService) {
        this.authService = authService;
        this.kycService = kycService;
    }

    @Operation(summary = "Inscription d'un nouvel utilisateur")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "201", description = "Utilisateur créé avec succès"),
        @ApiResponse(responseCode = "400", description = "Données d'inscription invalides"),
        @ApiResponse(responseCode = "409", description = "Email ou téléphone déjà utilisé")
    })
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(
            @Valid @RequestBody RegisterRequest request,
            HttpServletRequest httpRequest) {
        
        AuthResponse response = authService.register(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(summary = "Connexion d'un utilisateur")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Connexion réussie"),
        @ApiResponse(responseCode = "401", description = "Identifiants invalides"),
        @ApiResponse(responseCode = "423", description = "Compte verrouillé")
    })
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(
            @Valid @RequestBody LoginRequest request,
            HttpServletRequest httpRequest) {
        
        AuthResponse response = authService.login(request, httpRequest);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Rafraîchissement du token d'accès")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Token rafraîchi avec succès"),
        @ApiResponse(responseCode = "401", description = "Token de rafraîchissement invalide")
    })
    @PostMapping("/refresh")
    public ResponseEntity<TokenResponse> refreshToken(
            @Valid @RequestBody RefreshTokenRequest request) {
        
        TokenResponse response = authService.refreshToken(request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Déconnexion de l'utilisateur")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Déconnexion réussie"),
        @ApiResponse(responseCode = "401", description = "Token invalide")
    })
    @PostMapping("/logout")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse> logout(
            @RequestHeader("Authorization") String authHeader) {
        
        authService.logout(authHeader);
        return ResponseEntity.ok(new ApiResponse("Déconnexion réussie", true));
    }

    @Operation(summary = "Déconnexion de toutes les sessions")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/logout-all")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse> logoutAll(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        authService.logoutAll(userId);
        return ResponseEntity.ok(new ApiResponse("Toutes les sessions ont été fermées", true));
    }

    @Operation(summary = "Vérification de l'email")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Email vérifié avec succès"),
        @ApiResponse(responseCode = "400", description = "Token de vérification invalide")
    })
    @PostMapping("/verify-email")
    public ResponseEntity<ApiResponse> verifyEmail(
            @Valid @RequestBody VerifyEmailRequest request) {
        
        authService.verifyEmail(request);
        return ResponseEntity.ok(new ApiResponse("Email vérifié avec succès", true));
    }

    @Operation(summary = "Demande de réinitialisation du mot de passe")
    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {
        
        authService.forgotPassword(request);
        return ResponseEntity.ok(new ApiResponse("Instructions envoyées par email", true));
    }

    @Operation(summary = "Réinitialisation du mot de passe")
    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {
        
        authService.resetPassword(request);
        return ResponseEntity.ok(new ApiResponse("Mot de passe réinitialisé avec succès", true));
    }

    @Operation(summary = "Changement du mot de passe")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/change-password")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse> changePassword(
            @Valid @RequestBody ChangePasswordRequest request,
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        authService.changePassword(request, userId);
        return ResponseEntity.ok(new ApiResponse("Mot de passe modifié avec succès", true));
    }

    @Operation(summary = "Obtenir le profil de l'utilisateur connecté")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/profile")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<UserProfileResponse> getProfile(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        UserProfileResponse profile = authService.getUserProfile(userId);
        return ResponseEntity.ok(profile);
    }

    @Operation(summary = "Mettre à jour le profil utilisateur")
    @SecurityRequirement(name = "bearerAuth")
    @PutMapping("/profile")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<UserProfileResponse> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        UserProfileResponse profile = authService.updateUserProfile(request, userId);
        return ResponseEntity.ok(profile);
    }

    @Operation(summary = "Obtenir les sessions actives")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/sessions")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<UserSessionResponse>> getActiveSessions(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        List<UserSessionResponse> sessions = authService.getActiveSessions(userId);
        return ResponseEntity.ok(sessions);
    }

    @Operation(summary = "Terminer une session spécifique")
    @SecurityRequirement(name = "bearerAuth")
    @DeleteMapping("/sessions/{sessionId}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse> terminateSession(
            @PathVariable UUID sessionId,
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        authService.terminateSession(sessionId, userId);
        return ResponseEntity.ok(new ApiResponse("Session terminée avec succès", true));
    }

    // =====================================================
    // ENDPOINTS KYC BIOMÉTRIQUE
    // =====================================================

    @Operation(summary = "Démarrer le processus de vérification KYC")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/kyc/start")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<KycStartResponse> startKyc(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        KycStartResponse response = kycService.startKycProcess(userId);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Soumettre les documents d'identité")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/kyc/documents")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse> submitDocuments(
            @RequestParam("idCard") MultipartFile idCard,
            @RequestParam("selfie") MultipartFile selfie,
            @RequestParam(value = "additionalDoc", required = false) MultipartFile additionalDoc,
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        kycService.submitDocuments(userId, idCard, selfie, additionalDoc);
        return ResponseEntity.ok(new ApiResponse("Documents soumis avec succès", true));
    }

    @Operation(summary = "Soumettre les données biométriques")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/kyc/biometric")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<BiometricVerificationResponse> submitBiometric(
            @Valid @RequestBody BiometricDataRequest request,
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        BiometricVerificationResponse response = kycService.submitBiometricData(request, userId);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Obtenir le statut de la vérification KYC")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/kyc/status")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<KycStatusResponse> getKycStatus(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        KycStatusResponse status = kycService.getKycStatus(userId);
        return ResponseEntity.ok(status);
    }

    // =====================================================
    // ENDPOINTS CARTES PROFESSIONNELLES
    // =====================================================

    @Operation(summary = "Générer une carte d'identité professionnelle")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/professional-card/generate")
    @PreAuthorize("isAuthenticated() and hasRole('VERIFIED')")
    public ResponseEntity<ProfessionalCardResponse> generateProfessionalCard(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        ProfessionalCardResponse card = authService.generateProfessionalCard(userId);
        return ResponseEntity.status(HttpStatus.CREATED).body(card);
    }

    @Operation(summary = "Obtenir la carte d'identité professionnelle")
    @SecurityRequirement(name = "bearerAuth")
    @GetMapping("/professional-card")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ProfessionalCardResponse> getProfessionalCard(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        ProfessionalCardResponse card = authService.getProfessionalCard(userId);
        return ResponseEntity.ok(card);
    }

    @Operation(summary = "Renouveler la carte d'identité professionnelle")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/professional-card/renew")
    @PreAuthorize("isAuthenticated() and hasRole('VERIFIED')")
    public ResponseEntity<ProfessionalCardResponse> renewProfessionalCard(
            @Parameter(hidden = true) @RequestAttribute("userId") UUID userId) {
        
        ProfessionalCardResponse card = authService.renewProfessionalCard(userId);
        return ResponseEntity.ok(card);
    }

    @Operation(summary = "Vérifier une carte d'identité professionnelle via QR code")
    @PostMapping("/professional-card/verify")
    public ResponseEntity<CardVerificationResponse> verifyProfessionalCard(
            @Valid @RequestBody VerifyCardRequest request) {
        
        CardVerificationResponse verification = authService.verifyProfessionalCard(request);
        return ResponseEntity.ok(verification);
    }

    // =====================================================
    // ENDPOINTS ADMINISTRATIFS
    // =====================================================

    @Operation(summary = "Approuver la vérification KYC (Admin)")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/admin/kyc/{userId}/approve")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse> approveKyc(
            @PathVariable UUID userId,
            @Valid @RequestBody KycDecisionRequest request) {
        
        kycService.approveKyc(userId, request);
        return ResponseEntity.ok(new ApiResponse("KYC approuvé avec succès", true));
    }

    @Operation(summary = "Rejeter la vérification KYC (Admin)")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/admin/kyc/{userId}/reject")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse> rejectKyc(
            @PathVariable UUID userId,
            @Valid @RequestBody KycDecisionRequest request) {
        
        kycService.rejectKyc(userId, request);
        return ResponseEntity.ok(new ApiResponse("KYC rejeté", true));
    }

    @Operation(summary = "Suspendre un utilisateur (Admin)")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/admin/users/{userId}/suspend")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse> suspendUser(
            @PathVariable UUID userId,
            @Valid @RequestBody SuspendUserRequest request) {
        
        authService.suspendUser(userId, request);
        return ResponseEntity.ok(new ApiResponse("Utilisateur suspendu", true));
    }

    @Operation(summary = "Réactiver un utilisateur (Admin)")
    @SecurityRequirement(name = "bearerAuth")
    @PostMapping("/admin/users/{userId}/activate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse> activateUser(@PathVariable UUID userId) {
        
        authService.activateUser(userId);
        return ResponseEntity.ok(new ApiResponse("Utilisateur réactivé", true));
    }
}
