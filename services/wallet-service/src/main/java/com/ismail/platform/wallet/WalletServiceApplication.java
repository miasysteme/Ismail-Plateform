package com.ismail.platform.wallet;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * Application principale du service portefeuille ISMAIL
 * 
 * Ce service gère :
 * - Les portefeuilles électroniques des utilisateurs
 * - Les transactions et transferts de crédits
 * - Les commissions commerciales
 * - L'intégration avec les moyens de paiement
 * - Les statistiques et rapports financiers
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
public class WalletServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(WalletServiceApplication.class, args);
    }
}
