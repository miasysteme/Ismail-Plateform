package com.ismail.platform.auth.domain.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Entité session utilisateur pour la gestion des sessions actives
 * 
 * Représente une session active d'un utilisateur avec les informations
 * de connexion et de sécurité associées.
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@Entity
@Table(name = "user_sessions", schema = "core")
@EntityListeners(AuditingEntityListener.class)
public class UserSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @NotNull(message = "Utilisateur obligatoire")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @NotBlank(message = "Token de session obligatoire")
    @Column(name = "session_token", unique = true, nullable = false)
    private String sessionToken;

    @NotBlank(message = "Token de rafraîchissement obligatoire")
    @Column(name = "refresh_token", unique = true, nullable = false)
    private String refreshToken;

    @Column(name = "device_id")
    private String deviceId;

    @Column(name = "device_type", length = 50)
    private String deviceType;

    @Column(name = "device_name")
    private String deviceName;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(name = "user_agent", columnDefinition = "TEXT")
    private String userAgent;

    @Column(name = "location", columnDefinition = "JSONB")
    private String location; // JSON avec pays, ville, coordonnées approximatives

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "last_activity_at", nullable = false)
    private LocalDateTime lastActivityAt;

    @NotNull(message = "Date d'expiration obligatoire")
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Constructeurs
    public UserSession() {}

    public UserSession(User user, String sessionToken, String refreshToken, 
                      LocalDateTime expiresAt) {
        this.user = user;
        this.sessionToken = sessionToken;
        this.refreshToken = refreshToken;
        this.expiresAt = expiresAt;
        this.lastActivityAt = LocalDateTime.now();
    }

    public UserSession(User user, String sessionToken, String refreshToken, 
                      LocalDateTime expiresAt, String deviceId, String deviceType, 
                      String deviceName, String ipAddress, String userAgent) {
        this(user, sessionToken, refreshToken, expiresAt);
        this.deviceId = deviceId;
        this.deviceType = deviceType;
        this.deviceName = deviceName;
        this.ipAddress = ipAddress;
        this.userAgent = userAgent;
    }

    // Méthodes utilitaires
    public boolean isExpired() {
        return expiresAt.isBefore(LocalDateTime.now());
    }

    public boolean isValid() {
        return isActive && !isExpired();
    }

    public void updateActivity() {
        this.lastActivityAt = LocalDateTime.now();
    }

    public void invalidate() {
        this.isActive = false;
    }

    public void extendExpiration(int additionalMinutes) {
        this.expiresAt = this.expiresAt.plusMinutes(additionalMinutes);
    }

    public long getMinutesUntilExpiration() {
        return java.time.Duration.between(LocalDateTime.now(), expiresAt).toMinutes();
    }

    public boolean isFromSameDevice(String deviceId, String userAgent) {
        return Objects.equals(this.deviceId, deviceId) && 
               Objects.equals(this.userAgent, userAgent);
    }

    // Getters et Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getSessionToken() { return sessionToken; }
    public void setSessionToken(String sessionToken) { this.sessionToken = sessionToken; }

    public String getRefreshToken() { return refreshToken; }
    public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }

    public String getDeviceId() { return deviceId; }
    public void setDeviceId(String deviceId) { this.deviceId = deviceId; }

    public String getDeviceType() { return deviceType; }
    public void setDeviceType(String deviceType) { this.deviceType = deviceType; }

    public String getDeviceName() { return deviceName; }
    public void setDeviceName(String deviceName) { this.deviceName = deviceName; }

    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }

    public String getUserAgent() { return userAgent; }
    public void setUserAgent(String userAgent) { this.userAgent = userAgent; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getLastActivityAt() { return lastActivityAt; }
    public void setLastActivityAt(LocalDateTime lastActivityAt) { this.lastActivityAt = lastActivityAt; }

    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    // equals, hashCode et toString
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserSession that = (UserSession) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "UserSession{" +
                "id=" + id +
                ", userId=" + (user != null ? user.getId() : null) +
                ", deviceType='" + deviceType + '\'' +
                ", ipAddress='" + ipAddress + '\'' +
                ", isActive=" + isActive +
                ", expiresAt=" + expiresAt +
                '}';
    }
}
