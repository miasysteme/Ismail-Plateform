package com.ismail.platform.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Application principale du service d'authentification ISMAIL
 * 
 * Ce service gère :
 * - L'authentification et l'autorisation des utilisateurs
 * - La vérification KYC biométrique
 * - La génération et validation des tokens JWT
 * - La gestion des sessions utilisateur
 * - Les cartes d'identité professionnelles digitales
 * 
 * @author ISMAIL Platform Team
 * @version 1.0.0
 */
@SpringBootApplication
@EnableJpaAuditing
@EnableAsync
@EnableScheduling
@EnableTransactionManagement
@EnableFeignClients
public class AuthServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}
