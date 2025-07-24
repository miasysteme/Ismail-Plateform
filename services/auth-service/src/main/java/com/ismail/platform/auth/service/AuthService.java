package com.ismail.platform.auth.service;

import com.ismail.platform.auth.dto.request.*;
import com.ismail.platform.auth.dto.response.*;
import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.UUID;

/**
 * Interface du service d'authentification ISMAIL
 * 
 * Définit les opérations d'authentification, gestion des utilisateurs,
 * sessions et cartes professionnelles.
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
public interface AuthService {

    // =====================================================
    // AUTHENTIFICATION ET INSCRIPTION
    // =====================================================

    /**
     * Inscription d'un nouvel utilisateur
     * 
     * @param request Données d'inscription
     * @param httpRequest Requête HTTP pour extraire les informations de contexte
     * @return Réponse d'authentification avec tokens
     */
    AuthResponse register(RegisterRequest request, HttpServletRequest httpRequest);

    /**
     * Connexion d'un utilisateur
     * 
     * @param request Données de connexion
     * @param httpRequest Requête HTTP pour extraire les informations de contexte
     * @return Réponse d'authentification avec tokens
     */
    AuthResponse login(LoginRequest request, HttpServletRequest httpRequest);

    /**
     * Rafraîchissement du token d'accès
     * 
     * @param request Token de rafraîchissement
     * @return Nouveaux tokens d'accès
     */
    TokenResponse refreshToken(RefreshTokenRequest request);

    /**
     * Déconnexion d'un utilisateur
     * 
     * @param authHeader Header d'autorisation contenant le token
     */
    void logout(String authHeader);

    /**
     * Déconnexion de toutes les sessions d'un utilisateur
     * 
     * @param userId Identifiant de l'utilisateur
     */
    void logoutAll(UUID userId);

    // =====================================================
    // GESTION DES MOTS DE PASSE
    // =====================================================

    /**
     * Demande de réinitialisation du mot de passe
     * 
     * @param request Email pour la réinitialisation
     */
    void forgotPassword(ForgotPasswordRequest request);

    /**
     * Réinitialisation du mot de passe
     * 
     * @param request Token et nouveau mot de passe
     */
    void resetPassword(ResetPasswordRequest request);

    /**
     * Changement du mot de passe
     * 
     * @param request Ancien et nouveau mot de passe
     * @param userId Identifiant de l'utilisateur
     */
    void changePassword(ChangePasswordRequest request, UUID userId);

    // =====================================================
    // VÉRIFICATION EMAIL
    // =====================================================

    /**
     * Vérification de l'adresse email
     * 
     * @param request Token de vérification
     */
    void verifyEmail(VerifyEmailRequest request);

    /**
     * Renvoyer l'email de vérification
     * 
     * @param userId Identifiant de l'utilisateur
     */
    void resendVerificationEmail(UUID userId);

    // =====================================================
    // GESTION DU PROFIL UTILISATEUR
    // =====================================================

    /**
     * Obtenir le profil de l'utilisateur
     * 
     * @param userId Identifiant de l'utilisateur
     * @return Profil utilisateur
     */
    UserProfileResponse getUserProfile(UUID userId);

    /**
     * Mettre à jour le profil utilisateur
     * 
     * @param request Nouvelles données du profil
     * @param userId Identifiant de l'utilisateur
     * @return Profil mis à jour
     */
    UserProfileResponse updateUserProfile(UpdateProfileRequest request, UUID userId);

    // =====================================================
    // GESTION DES SESSIONS
    // =====================================================

    /**
     * Obtenir les sessions actives d'un utilisateur
     * 
     * @param userId Identifiant de l'utilisateur
     * @return Liste des sessions actives
     */
    List<UserSessionResponse> getActiveSessions(UUID userId);

    /**
     * Terminer une session spécifique
     * 
     * @param sessionId Identifiant de la session
     * @param userId Identifiant de l'utilisateur
     */
    void terminateSession(UUID sessionId, UUID userId);

    /**
     * Nettoyer les sessions expirées
     */
    void cleanupExpiredSessions();

    // =====================================================
    // CARTES PROFESSIONNELLES
    // =====================================================

    /**
     * Générer une carte d'identité professionnelle
     * 
     * @param userId Identifiant de l'utilisateur
     * @return Carte professionnelle générée
     */
    ProfessionalCardResponse generateProfessionalCard(UUID userId);

    /**
     * Obtenir la carte d'identité professionnelle
     * 
     * @param userId Identifiant de l'utilisateur
     * @return Carte professionnelle
     */
    ProfessionalCardResponse getProfessionalCard(UUID userId);

    /**
     * Renouveler la carte d'identité professionnelle
     * 
     * @param userId Identifiant de l'utilisateur
     * @return Carte professionnelle renouvelée
     */
    ProfessionalCardResponse renewProfessionalCard(UUID userId);

    /**
     * Vérifier une carte d'identité professionnelle
     * 
     * @param request Données de vérification (QR code ou ID)
     * @return Résultat de la vérification
     */
    CardVerificationResponse verifyProfessionalCard(VerifyCardRequest request);

    // =====================================================
    // ADMINISTRATION
    // =====================================================

    /**
     * Suspendre un utilisateur
     * 
     * @param userId Identifiant de l'utilisateur
     * @param request Raison de la suspension
     */
    void suspendUser(UUID userId, SuspendUserRequest request);

    /**
     * Réactiver un utilisateur
     * 
     * @param userId Identifiant de l'utilisateur
     */
    void activateUser(UUID userId);

    /**
     * Obtenir les statistiques d'authentification
     * 
     * @return Statistiques d'authentification
     */
    AuthStatsResponse getAuthStats();

    // =====================================================
    // UTILITAIRES
    // =====================================================

    /**
     * Valider un token JWT
     * 
     * @param token Token à valider
     * @return Informations du token si valide
     */
    TokenValidationResponse validateToken(String token);

    /**
     * Extraire l'ID utilisateur d'un token
     * 
     * @param token Token JWT
     * @return ID de l'utilisateur
     */
    UUID extractUserIdFromToken(String token);

    /**
     * Vérifier si un utilisateur existe
     * 
     * @param email Email de l'utilisateur
     * @return true si l'utilisateur existe
     */
    boolean userExists(String email);

    /**
     * Vérifier si un numéro de téléphone est utilisé
     * 
     * @param phone Numéro de téléphone
     * @return true si le téléphone est utilisé
     */
    boolean phoneExists(String phone);

    /**
     * Générer un ID ISMAIL unique
     *
     * @param countryCode Code pays (ex: CI)
     * @param profileType Type de profil
     * @return ID ISMAIL généré
     */
    String generateIsmailId(String countryCode, String profileType);
}
}
