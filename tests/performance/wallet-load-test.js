// Test de charge pour le service portefeuille ISMAIL
// Simule des transactions, transferts et consultations de solde

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Métriques personnalisées
const transactionSuccessRate = new Rate('transaction_success_rate');
const transactionDuration = new Trend('transaction_duration');
const balanceCheckDuration = new Trend('balance_check_duration');
const transferSuccessRate = new Rate('transfer_success_rate');
const errorCount = new Counter('error_count');

// Configuration du test
export const options = {
  stages: [
    { duration: '1m', target: 5 },    // Démarrage lent
    { duration: '3m', target: 25 },   // Montée progressive
    { duration: '5m', target: 50 },   // Charge normale
    { duration: '3m', target: 100 },  // Pic de charge
    { duration: '5m', target: 50 },   // Retour à la normale
    { duration: '2m', target: 0 },    // Descente
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'], // 95% des requêtes < 3s
    http_req_failed: ['rate<0.02'],    // Taux d'erreur < 2%
    transaction_success_rate: ['rate>0.98'], // Taux de succès transactions > 98%
    transfer_success_rate: ['rate>0.95'],    // Taux de succès transferts > 95%
  },
};

// Configuration de l'environnement
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const AUTH_API = `${BASE_URL}/api/auth`;
const WALLET_API = `${BASE_URL}/api/wallet`;

// Pool d'utilisateurs de test
const testUsers = [];
let authenticatedUsers = [];

// Fonction pour créer un utilisateur de test
function createTestUser() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  
  return {
    email: `wallet${timestamp}${random}@ismail-platform.com`,
    phone: `+225012345${String(random).padStart(4, '0')}`,
    password: 'TestPassword123!',
    confirmPassword: 'TestPassword123!',
    firstName: `Wallet${random}`,
    lastName: `Test${timestamp}`,
    profileType: 'CLIENT',
    acceptTerms: true,
    acceptPrivacy: true,
    marketingConsent: false
  };
}

// Fonction pour s'authentifier et récupérer un token
function authenticateUser(user) {
  const loginData = {
    email: user.email,
    password: user.password,
    deviceInfo: 'K6 Wallet Test'
  };
  
  const response = http.post(`${AUTH_API}/login`, JSON.stringify(loginData), {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  if (response.status === 200) {
    try {
      const body = JSON.parse(response.body);
      return {
        token: body.accessToken,
        refreshToken: body.refreshToken,
        user: body.user
      };
    } catch (e) {
      console.error('Error parsing auth response:', e);
      return null;
    }
  }
  
  return null;
}

// Test de consultation du solde
export function testBalanceCheck(token) {
  const response = http.get(`${WALLET_API}/balance`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'balance check status is 200': (r) => r.status === 200,
    'balance response has balance': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.balance !== undefined;
      } catch (e) {
        return false;
      }
    },
    'balance check response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  balanceCheckDuration.add(response.timings.duration);
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Test de crédit du portefeuille
export function testWalletCredit(token) {
  const creditData = {
    amount: Math.floor(Math.random() * 10000) + 1000, // 1000-11000 FCFA
    currency: 'XOF',
    paymentMethod: 'ORANGE_MONEY',
    paymentReference: `OM${Date.now()}${Math.floor(Math.random() * 1000)}`,
    description: 'K6 Load Test Credit'
  };
  
  const response = http.post(`${WALLET_API}/credit`, JSON.stringify(creditData), {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'credit status is 200': (r) => r.status === 200,
    'credit response has transaction ID': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.transactionId !== undefined;
      } catch (e) {
        return false;
      }
    },
    'credit response time < 3s': (r) => r.timings.duration < 3000,
  });
  
  transactionSuccessRate.add(success);
  transactionDuration.add(response.timings.duration);
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Test de transfert entre portefeuilles
export function testWalletTransfer(token, recipientIsmailId) {
  const transferData = {
    recipientIsmailId: recipientIsmailId,
    amount: Math.floor(Math.random() * 1000) + 100, // 100-1100 FCFA
    currency: 'XOF',
    description: 'K6 Load Test Transfer',
    pin: '1234'
  };
  
  const response = http.post(`${WALLET_API}/transfer`, JSON.stringify(transferData), {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'transfer status is 200 or 400': (r) => r.status === 200 || r.status === 400,
    'transfer response time < 2s': (r) => r.timings.duration < 2000,
  });
  
  // Considérer comme succès si 200, échec si autre chose
  const transferSuccess = response.status === 200;
  transferSuccessRate.add(transferSuccess);
  transactionDuration.add(response.timings.duration);
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Test de consultation de l'historique des transactions
export function testTransactionHistory(token) {
  const response = http.get(`${WALLET_API}/transactions?page=0&size=10`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'history status is 200': (r) => r.status === 200,
    'history response has content': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.content !== undefined;
      } catch (e) {
        return false;
      }
    },
    'history response time < 1.5s': (r) => r.timings.duration < 1500,
  });
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Test de retrait
export function testWalletWithdraw(token) {
  const withdrawData = {
    amount: Math.floor(Math.random() * 500) + 100, // 100-600 FCFA
    currency: 'XOF',
    withdrawMethod: 'ORANGE_MONEY',
    phoneNumber: '+2250123456789',
    pin: '1234'
  };
  
  const response = http.post(`${WALLET_API}/withdraw`, JSON.stringify(withdrawData), {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'withdraw status is 200 or 400': (r) => r.status === 200 || r.status === 400,
    'withdraw response time < 3s': (r) => r.timings.duration < 3000,
  });
  
  transactionSuccessRate.add(response.status === 200);
  transactionDuration.add(response.timings.duration);
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Scénario principal du test
export default function () {
  // Sélectionner un utilisateur authentifié aléatoirement
  if (authenticatedUsers.length === 0) {
    console.log('No authenticated users available');
    return;
  }
  
  const userAuth = authenticatedUsers[Math.floor(Math.random() * authenticatedUsers.length)];
  const token = userAuth.token;
  
  // Scénarios pondérés selon l'usage réel
  const scenario = Math.random();
  
  if (scenario < 0.4) {
    // 40% - Consultation du solde (action la plus fréquente)
    console.log('Executing balance check scenario');
    testBalanceCheck(token);
    
  } else if (scenario < 0.6) {
    // 20% - Consultation de l'historique
    console.log('Executing transaction history scenario');
    testTransactionHistory(token);
    
  } else if (scenario < 0.75) {
    // 15% - Crédit du portefeuille
    console.log('Executing wallet credit scenario');
    testWalletCredit(token);
    
    // Après un crédit, vérifier le nouveau solde
    sleep(1);
    testBalanceCheck(token);
    
  } else if (scenario < 0.9) {
    // 15% - Transfert entre portefeuilles
    console.log('Executing wallet transfer scenario');
    
    // Sélectionner un destinataire différent
    const recipients = authenticatedUsers.filter(u => u.user.id !== userAuth.user.id);
    if (recipients.length > 0) {
      const recipient = recipients[Math.floor(Math.random() * recipients.length)];
      testWalletTransfer(token, recipient.user.ismailId);
      
      // Vérifier le solde après transfert
      sleep(1);
      testBalanceCheck(token);
    }
    
  } else {
    // 10% - Retrait
    console.log('Executing wallet withdraw scenario');
    testWalletWithdraw(token);
    
    // Vérifier le solde après retrait
    sleep(1);
    testBalanceCheck(token);
  }
  
  // Pause réaliste entre les actions
  sleep(Math.random() * 2 + 0.5); // 0.5-2.5 secondes
}

// Fonction de setup
export function setup() {
  console.log('Starting wallet service load test');
  console.log(`Target URL: ${WALLET_API}`);
  
  // Créer et authentifier des utilisateurs de test
  for (let i = 0; i < 20; i++) {
    const user = createTestUser();
    
    // Inscrire l'utilisateur
    const registerResponse = http.post(`${AUTH_API}/register`, JSON.stringify(user), {
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (registerResponse.status === 201) {
      // Authentifier l'utilisateur
      const auth = authenticateUser(user);
      if (auth) {
        authenticatedUsers.push(auth);
        console.log(`Created and authenticated user: ${user.email}`);
        
        // Créditer le portefeuille pour les tests
        const creditData = {
          amount: 50000, // 50,000 FCFA
          currency: 'XOF',
          paymentMethod: 'ORANGE_MONEY',
          paymentReference: `SETUP${Date.now()}${i}`,
          description: 'Initial credit for load test'
        };
        
        http.post(`${WALLET_API}/credit`, JSON.stringify(creditData), {
          headers: {
            'Authorization': `Bearer ${auth.token}`,
            'Content-Type': 'application/json',
          },
        });
      }
    }
    
    // Pause pour éviter de surcharger le système pendant le setup
    sleep(0.5);
  }
  
  console.log(`Setup completed with ${authenticatedUsers.length} authenticated users`);
  return { authenticatedUsers: authenticatedUsers };
}

// Fonction de teardown
export function teardown(data) {
  console.log('Wallet service load test completed');
  console.log(`Total authenticated users: ${data.authenticatedUsers.length}`);
  
  // Afficher un résumé des métriques
  console.log('Test Summary:');
  console.log(`- Total errors: ${errorCount.count}`);
  console.log(`- Transaction success rate: ${transactionSuccessRate.rate * 100}%`);
  console.log(`- Transfer success rate: ${transferSuccessRate.rate * 100}%`);
}

// Configuration des tags
export const tags = {
  service: 'wallet-service',
  environment: __ENV.ENVIRONMENT || 'test',
  test_type: 'load_test'
};
