package com.ismail.platform.auth.domain.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Entité utilisateur pour l'authentification ISMAIL
 * 
 * Représente un utilisateur de la plateforme avec toutes ses informations
 * d'authentification et de profil de base.
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@Entity
@Table(name = "users", schema = "core")
@EntityListeners(AuditingEntityListener.class)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "ismail_id", unique = true, nullable = false, length = 16)
    @Pattern(regexp = "^[A-Z]{2}\\d{6}-[A-Z0-9]{4}-[A-Z]{2}$", 
             message = "Format ISMAIL ID invalide")
    private String ismailId;

    @Email(message = "Format email invalide")
    @NotBlank(message = "Email obligatoire")
    @Column(name = "email", unique = true, nullable = false)
    private String email;

    @Pattern(regexp = "^\\+[1-9]\\d{1,14}$", message = "Format téléphone invalide")
    @NotBlank(message = "Téléphone obligatoire")
    @Column(name = "phone", unique = true, nullable = false, length = 20)
    private String phone;

    @NotBlank(message = "Mot de passe obligatoire")
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @NotBlank(message = "Prénom obligatoire")
    @Size(min = 2, max = 100, message = "Prénom doit contenir entre 2 et 100 caractères")
    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    @NotBlank(message = "Nom obligatoire")
    @Size(min = 2, max = 100, message = "Nom doit contenir entre 2 et 100 caractères")
    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    @Past(message = "Date de naissance doit être dans le passé")
    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Enumerated(EnumType.STRING)
    @Column(name = "gender", length = 10)
    private Gender gender;

    @NotNull(message = "Type de profil obligatoire")
    @Enumerated(EnumType.STRING)
    @Column(name = "profile_type", nullable = false, length = 20)
    private ProfileType profileType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private UserStatus status = UserStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(name = "kyc_status", nullable = false, length = 20)
    private KycStatus kycStatus = KycStatus.PENDING;

    @Column(name = "kyc_verified_at")
    private LocalDateTime kycVerifiedAt;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    @Min(value = 0, message = "Tentatives de connexion ne peut être négative")
    @Column(name = "login_attempts", nullable = false)
    private Integer loginAttempts = 0;

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "password_changed_at")
    private LocalDateTime passwordChangedAt;

    @Column(name = "terms_accepted_at")
    private LocalDateTime termsAcceptedAt;

    @Column(name = "privacy_accepted_at")
    private LocalDateTime privacyAcceptedAt;

    @Column(name = "marketing_consent", nullable = false)
    private Boolean marketingConsent = false;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // Constructeurs
    public User() {}

    public User(String email, String phone, String passwordHash, 
                String firstName, String lastName, ProfileType profileType) {
        this.email = email;
        this.phone = phone;
        this.passwordHash = passwordHash;
        this.firstName = firstName;
        this.lastName = lastName;
        this.profileType = profileType;
        this.passwordChangedAt = LocalDateTime.now();
    }

    // Méthodes utilitaires
    public boolean isAccountLocked() {
        return lockedUntil != null && lockedUntil.isAfter(LocalDateTime.now());
    }

    public boolean isKycVerified() {
        return kycStatus == KycStatus.VERIFIED;
    }

    public boolean isActive() {
        return status == UserStatus.ACTIVE;
    }

    public String getFullName() {
        return firstName + " " + lastName;
    }

    public void incrementLoginAttempts() {
        this.loginAttempts = (this.loginAttempts == null) ? 1 : this.loginAttempts + 1;
    }

    public void resetLoginAttempts() {
        this.loginAttempts = 0;
        this.lockedUntil = null;
    }

    public void lockAccount(int lockoutDurationMinutes) {
        this.lockedUntil = LocalDateTime.now().plusMinutes(lockoutDurationMinutes);
    }

    public void updateLastLogin() {
        this.lastLoginAt = LocalDateTime.now();
        resetLoginAttempts();
    }

    public void verifyKyc() {
        this.kycStatus = KycStatus.VERIFIED;
        this.kycVerifiedAt = LocalDateTime.now();
        if (this.status == UserStatus.PENDING) {
            this.status = UserStatus.ACTIVE;
        }
    }

    public void rejectKyc() {
        this.kycStatus = KycStatus.REJECTED;
        this.kycVerifiedAt = null;
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

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { 
        this.passwordHash = passwordHash;
        this.passwordChangedAt = LocalDateTime.now();
    }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(LocalDate dateOfBirth) { this.dateOfBirth = dateOfBirth; }

    public Gender getGender() { return gender; }
    public void setGender(Gender gender) { this.gender = gender; }

    public ProfileType getProfileType() { return profileType; }
    public void setProfileType(ProfileType profileType) { this.profileType = profileType; }

    public UserStatus getStatus() { return status; }
    public void setStatus(UserStatus status) { this.status = status; }

    public KycStatus getKycStatus() { return kycStatus; }
    public void setKycStatus(KycStatus kycStatus) { this.kycStatus = kycStatus; }

    public LocalDateTime getKycVerifiedAt() { return kycVerifiedAt; }
    public void setKycVerifiedAt(LocalDateTime kycVerifiedAt) { this.kycVerifiedAt = kycVerifiedAt; }

    public LocalDateTime getLastLoginAt() { return lastLoginAt; }
    public void setLastLoginAt(LocalDateTime lastLoginAt) { this.lastLoginAt = lastLoginAt; }

    public Integer getLoginAttempts() { return loginAttempts; }
    public void setLoginAttempts(Integer loginAttempts) { this.loginAttempts = loginAttempts; }

    public LocalDateTime getLockedUntil() { return lockedUntil; }
    public void setLockedUntil(LocalDateTime lockedUntil) { this.lockedUntil = lockedUntil; }

    public LocalDateTime getPasswordChangedAt() { return passwordChangedAt; }
    public void setPasswordChangedAt(LocalDateTime passwordChangedAt) { this.passwordChangedAt = passwordChangedAt; }

    public LocalDateTime getTermsAcceptedAt() { return termsAcceptedAt; }
    public void setTermsAcceptedAt(LocalDateTime termsAcceptedAt) { this.termsAcceptedAt = termsAcceptedAt; }

    public LocalDateTime getPrivacyAcceptedAt() { return privacyAcceptedAt; }
    public void setPrivacyAcceptedAt(LocalDateTime privacyAcceptedAt) { this.privacyAcceptedAt = privacyAcceptedAt; }

    public Boolean getMarketingConsent() { return marketingConsent; }
    public void setMarketingConsent(Boolean marketingConsent) { this.marketingConsent = marketingConsent; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    // equals, hashCode et toString
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        User user = (User) o;
        return Objects.equals(id, user.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", ismailId='" + ismailId + '\'' +
                ", email='" + email + '\'' +
                ", firstName='" + firstName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", profileType=" + profileType +
                ", status=" + status +
                ", kycStatus=" + kycStatus +
                '}';
    }

    // Enums
    public enum Gender {
        MALE, FEMALE, OTHER
    }

    public enum ProfileType {
        CLIENT, PARTNER, COMMERCIAL, ADMIN
    }

    public enum UserStatus {
        PENDING, ACTIVE, SUSPENDED, BLOCKED
    }

    public enum KycStatus {
        PENDING, VERIFIED, REJECTED
    }
}
