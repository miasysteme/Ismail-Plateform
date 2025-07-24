package com.ismail.platform.auth.dto.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.ismail.platform.auth.domain.entity.User;
import io.swagger.v3.oas.annotations.media.Schema;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * DTO de réponse pour l'authentification
 * 
 * Contient les informations de l'utilisateur authentifié et les tokens d'accès.
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@Schema(description = "Réponse d'authentification avec tokens et informations utilisateur")
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AuthResponse {

    @Schema(description = "Indicateur de succès", example = "true")
    private boolean success;

    @Schema(description = "Message de réponse", example = "Connexion réussie")
    private String message;

    @Schema(description = "Token d'accès JWT")
    private String accessToken;

    @Schema(description = "Token de rafraîchissement")
    private String refreshToken;

    @Schema(description = "Type de token", example = "Bearer")
    private String tokenType = "Bearer";

    @Schema(description = "Durée de validité du token en secondes", example = "3600")
    private Long expiresIn;

    @Schema(description = "Informations de l'utilisateur")
    private UserInfo user;

    @Schema(description = "Informations de session")
    private SessionInfo session;

    // Constructeurs
    public AuthResponse() {}

    public AuthResponse(boolean success, String message) {
        this.success = success;
        this.message = message;
    }

    public AuthResponse(boolean success, String message, String accessToken, 
                       String refreshToken, Long expiresIn, UserInfo user) {
        this.success = success;
        this.message = message;
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
        this.user = user;
    }

    // Getters et Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public String getAccessToken() { return accessToken; }
    public void setAccessToken(String accessToken) { this.accessToken = accessToken; }

    public String getRefreshToken() { return refreshToken; }
    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }

    public String getTokenType() { return tokenType; }
    public void setTokenType(String tokenType) { this.tokenType = tokenType; }

    public Long getExpiresIn() { return expiresIn; }
    public void setExpiresIn(Long expiresIn) { this.expiresIn = expiresIn; }

    public UserInfo getUser() { return user; }
    public void setUser(UserInfo user) { this.user = user; }

    public SessionInfo getSession() { return session; }
    public void setSession(SessionInfo session) { this.session = session; }

    /**
     * Classe interne pour les informations utilisateur
     */
    @Schema(description = "Informations de base de l'utilisateur")
    public static class UserInfo {
        
        @Schema(description = "Identifiant unique de l'utilisateur")
        private UUID id;

        @Schema(description = "Identifiant ISMAIL unique", example = "CI241201-A1B2-CL")
        private String ismailId;

        @Schema(description = "Adresse email", example = "user@example.com")
        private String email;

        @Schema(description = "Numéro de téléphone", example = "+2250123456789")
        private String phone;

        @Schema(description = "Prénom", example = "Jean")
        private String firstName;

        @Schema(description = "Nom de famille", example = "Dupont")
        private String lastName;

        @Schema(description = "Nom complet", example = "Jean Dupont")
        private String fullName;

        @Schema(description = "Type de profil", example = "CLIENT")
        private User.ProfileType profileType;

        @Schema(description = "Statut du compte", example = "ACTIVE")
        private User.UserStatus status;

        @Schema(description = "Statut de vérification KYC", example = "VERIFIED")
        private User.KycStatus kycStatus;

        @Schema(description = "Indicateur de vérification KYC", example = "true")
        private boolean isKycVerified;

        @Schema(description = "Date de dernière connexion")
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime lastLoginAt;

        @Schema(description = "Date de création du compte")
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime createdAt;

        // Constructeurs
        public UserInfo() {}

        public UserInfo(UUID id, String ismailId, String email, String phone,
                       String firstName, String lastName, User.ProfileType profileType,
                       User.UserStatus status, User.KycStatus kycStatus) {
            this.id = id;
            this.ismailId = ismailId;
            this.email = email;
            this.phone = phone;
            this.firstName = firstName;
            this.lastName = lastName;
            this.fullName = firstName + " " + lastName;
            this.profileType = profileType;
            this.status = status;
            this.kycStatus = kycStatus;
            this.isKycVerified = kycStatus == User.KycStatus.VERIFIED;
        }

        // Getters et Setters
        public UUID getId() { return id; }
        public void setId(UUID id) { this.id = id; }

        public String getIsmailId() { return ismailId; }
        public void setIsmailId(String ismailId) { this.ismailId = ismailId; }

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }

        public String getPhone() { return phone; }
        public void setPhone(String phone) { this.phone = phone; }

        public String getFirstName() { return firstName; }
        public void setFirstName(String firstName) { this.firstName = firstName; }

        public String getLastName() { return lastName; }
        public void setLastName(String lastName) { this.lastName = lastName; }

        public String getFullName() { return fullName; }
        public void setFullName(String fullName) { this.fullName = fullName; }

        public User.ProfileType getProfileType() { return profileType; }
        public void setProfileType(User.ProfileType profileType) { this.profileType = profileType; }

        public User.UserStatus getStatus() { return status; }
        public void setStatus(User.UserStatus status) { this.status = status; }

        public User.KycStatus getKycStatus() { return kycStatus; }
        public void setKycStatus(User.KycStatus kycStatus) { 
            this.kycStatus = kycStatus;
            this.isKycVerified = kycStatus == User.KycStatus.VERIFIED;
        }

        public boolean isKycVerified() { return isKycVerified; }
        public void setKycVerified(boolean kycVerified) { isKycVerified = kycVerified; }

        public LocalDateTime getLastLoginAt() { return lastLoginAt; }
        public void setLastLoginAt(LocalDateTime lastLoginAt) { this.lastLoginAt = lastLoginAt; }

        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    }

    /**
     * Classe interne pour les informations de session
     */
    @Schema(description = "Informations de la session utilisateur")
    public static class SessionInfo {
        
        @Schema(description = "Identifiant de session")
        private UUID sessionId;

        @Schema(description = "Type d'appareil", example = "mobile")
        private String deviceType;

        @Schema(description = "Nom de l'appareil", example = "iPhone 13")
        private String deviceName;

        @Schema(description = "Adresse IP", example = "192.168.1.100")
        private String ipAddress;

        @Schema(description = "Date de création de la session")
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime createdAt;

        @Schema(description = "Date d'expiration de la session")
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime expiresAt;

        // Constructeurs
        public SessionInfo() {}

        public SessionInfo(UUID sessionId, String deviceType, String deviceName,
                          String ipAddress, LocalDateTime createdAt, LocalDateTime expiresAt) {
            this.sessionId = sessionId;
            this.deviceType = deviceType;
            this.deviceName = deviceName;
            this.ipAddress = ipAddress;
            this.createdAt = createdAt;
            this.expiresAt = expiresAt;
        }

        // Getters et Setters
        public UUID getSessionId() { return sessionId; }
        public void setSessionId(UUID sessionId) { this.sessionId = sessionId; }

        public String getDeviceType() { return deviceType; }
        public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

        public String getDeviceName() { return deviceName; }
        public void setDeviceName(String deviceName) { this.deviceName = deviceName; }

        public String getIpAddress() { return ipAddress; }
        public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

        public LocalDateTime getExpiresAt() { return expiresAt; }
        public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    }

    @Override
    public String toString() {
        return "AuthResponse{" +
                "success=" + success +
                ", message='" + message + '\'' +
                ", tokenType='" + tokenType + '\'' +
                ", expiresIn=" + expiresIn +
                ", user=" + (user != null ? user.getEmail() : null) +
                '}';
    }
}
