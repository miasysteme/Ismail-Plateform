package com.ismail.platform.auth.dto.request;

import com.ismail.platform.auth.domain.entity.User;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;

import java.time.LocalDate;

/**
 * DTO pour la requête d'inscription d'un nouvel utilisateur
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@Schema(description = "Données d'inscription d'un nouvel utilisateur")
public class RegisterRequest {

    @Schema(description = "Adresse email", example = "user@example.com")
    @NotBlank(message = "Email obligatoire")
    @Email(message = "Format email invalide")
    @Size(max = 255, message = "Email trop long")
    private String email;

    @Schema(description = "Numéro de téléphone au format international", example = "+2250123456789")
    @NotBlank(message = "Téléphone obligatoire")
    @Pattern(regexp = "^\\+[1-9]\\d{1,14}$", message = "Format téléphone invalide")
    private String phone;

    @Schema(description = "Mot de passe", example = "MotDePasse123!")
    @NotBlank(message = "Mot de passe obligatoire")
    @Size(min = 8, max = 128, message = "Mot de passe doit contenir entre 8 et 128 caractères")
    @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&].*$",
             message = "Mot de passe doit contenir au moins une minuscule, une majuscule, un chiffre et un caractère spécial")
    private String password;

    @Schema(description = "Confirmation du mot de passe", example = "MotDePasse123!")
    @NotBlank(message = "Confirmation du mot de passe obligatoire")
    private String confirmPassword;

    @Schema(description = "Prénom", example = "Jean")
    @NotBlank(message = "Prénom obligatoire")
    @Size(min = 2, max = 100, message = "Prénom doit contenir entre 2 et 100 caractères")
    @Pattern(regexp = "^[a-zA-ZÀ-ÿ\\s'-]+$", message = "Prénom contient des caractères invalides")
    private String firstName;

    @Schema(description = "Nom de famille", example = "Dupont")
    @NotBlank(message = "Nom obligatoire")
    @Size(min = 2, max = 100, message = "Nom doit contenir entre 2 et 100 caractères")
    @Pattern(regexp = "^[a-zA-ZÀ-ÿ\\s'-]+$", message = "Nom contient des caractères invalides")
    private String lastName;

    @Schema(description = "Date de naissance", example = "1990-01-15")
    @Past(message = "Date de naissance doit être dans le passé")
    private LocalDate dateOfBirth;

    @Schema(description = "Genre", example = "MALE", allowableValues = {"MALE", "FEMALE", "OTHER"})
    private User.Gender gender;

    @Schema(description = "Type de profil", example = "CLIENT", 
            allowableValues = {"CLIENT", "PARTNER", "COMMERCIAL", "ADMIN"})
    @NotNull(message = "Type de profil obligatoire")
    private User.ProfileType profileType;

    @Schema(description = "Acceptation des conditions d'utilisation", example = "true")
    @NotNull(message = "Acceptation des conditions obligatoire")
    @AssertTrue(message = "Vous devez accepter les conditions d'utilisation")
    private Boolean acceptTerms;

    @Schema(description = "Acceptation de la politique de confidentialité", example = "true")
    @NotNull(message = "Acceptation de la politique de confidentialité obligatoire")
    @AssertTrue(message = "Vous devez accepter la politique de confidentialité")
    private Boolean acceptPrivacy;

    @Schema(description = "Consentement marketing", example = "false")
    private Boolean marketingConsent = false;

    @Schema(description = "Code de parrainage (optionnel)", example = "REF123456")
    @Size(max = 20, message = "Code de parrainage trop long")
    private String referralCode;

    @Schema(description = "Informations sur l'appareil", example = "iPhone 13")
    private String deviceInfo;

    // Constructeurs
    public RegisterRequest() {}

    public RegisterRequest(String email, String phone, String password, String confirmPassword,
                          String firstName, String lastName, User.ProfileType profileType,
                          Boolean acceptTerms, Boolean acceptPrivacy) {
        this.email = email;
        this.phone = phone;
        this.password = password;
        this.confirmPassword = confirmPassword;
        this.firstName = firstName;
        this.lastName = lastName;
        this.profileType = profileType;
        this.acceptTerms = acceptTerms;
        this.acceptPrivacy = acceptPrivacy;
    }

    // Méthodes de validation personnalisées
    @AssertTrue(message = "Les mots de passe ne correspondent pas")
    public boolean isPasswordMatching() {
        return password != null && password.equals(confirmPassword);
    }

    @AssertTrue(message = "Vous devez avoir au moins 18 ans")
    public boolean isAdult() {
        if (dateOfBirth == null) return true; // Validation optionnelle
        return dateOfBirth.isBefore(LocalDate.now().minusYears(18));
    }

    // Getters et Setters
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getConfirmPassword() { return confirmPassword; }
    public void setConfirmPassword(String confirmPassword) { this.confirmPassword = confirmPassword; }

    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }

    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }

    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(LocalDate dateOfBirth) { this.dateOfBirth = dateOfBirth; }

    public User.Gender getGender() { return gender; }
    public void setGender(User.Gender gender) { this.gender = gender; }

    public User.ProfileType getProfileType() { return profileType; }
    public void setProfileType(User.ProfileType profileType) { this.profileType = profileType; }

    public Boolean getAcceptTerms() { return acceptTerms; }
    public void setAcceptTerms(Boolean acceptTerms) { this.acceptTerms = acceptTerms; }

    public Boolean getAcceptPrivacy() { return acceptPrivacy; }
    public void setAcceptPrivacy(Boolean acceptPrivacy) { this.acceptPrivacy = acceptPrivacy; }

    public Boolean getMarketingConsent() { return marketingConsent; }
    public void setMarketingConsent(Boolean marketingConsent) { this.marketingConsent = marketingConsent; }

    public String getReferralCode() { return referralCode; }
    public void setReferralCode(String referralCode) { this.referralCode = referralCode; }

    public String getDeviceInfo() { return deviceInfo; }
    public void setDeviceInfo(String deviceInfo) { this.deviceInfo = deviceInfo; }

    @Override
    public String toString() {
        return "RegisterRequest{" +
                "email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", firstName='" + firstName + '\'' +
                ", lastName='" + lastName + '\'' +
                ", profileType=" + profileType +
                ", acceptTerms=" + acceptTerms +
                ", acceptPrivacy=" + acceptPrivacy +
                '}';
    }
}
