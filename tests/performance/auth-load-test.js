// Test de charge pour le service d'authentification ISMAIL
// Simule des scénarios réalistes de connexion et d'inscription

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Métriques personnalisées
const loginSuccessRate = new Rate('login_success_rate');
const loginDuration = new Trend('login_duration');
const registrationSuccessRate = new Rate('registration_success_rate');
const registrationDuration = new Trend('registration_duration');
const errorCount = new Counter('error_count');

// Configuration du test
export const options = {
  stages: [
    // Montée en charge progressive
    { duration: '2m', target: 10 },   // 10 utilisateurs pendant 2 minutes
    { duration: '5m', target: 50 },   // 50 utilisateurs pendant 5 minutes
    { duration: '10m', target: 100 }, // 100 utilisateurs pendant 10 minutes
    { duration: '5m', target: 200 },  // 200 utilisateurs pendant 5 minutes (pic)
    { duration: '10m', target: 100 }, // Retour à 100 utilisateurs
    { duration: '5m', target: 0 },    // Descente progressive
  ],
  thresholds: {
    // Seuils de performance
    http_req_duration: ['p(95)<2000'], // 95% des requêtes < 2s
    http_req_failed: ['rate<0.05'],    // Taux d'erreur < 5%
    login_success_rate: ['rate>0.95'], // Taux de succès connexion > 95%
    registration_success_rate: ['rate>0.90'], // Taux de succès inscription > 90%
  },
};

// Configuration de l'environnement
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
const API_BASE = `${BASE_URL}/api/auth`;

// Données de test
const testUsers = [];
let userCounter = 0;

// Fonction pour générer des données utilisateur aléatoires
function generateRandomUser() {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  
  return {
    email: `test${timestamp}${random}@ismail-platform.com`,
    phone: `+225012345${String(random).padStart(4, '0')}`,
    password: 'TestPassword123!',
    confirmPassword: 'TestPassword123!',
    firstName: `User${random}`,
    lastName: `Test${timestamp}`,
    profileType: 'CLIENT',
    acceptTerms: true,
    acceptPrivacy: true,
    marketingConsent: false
  };
}

// Fonction pour générer des données de connexion
function generateLoginData() {
  if (testUsers.length === 0) {
    // Si pas d'utilisateurs créés, utiliser un utilisateur par défaut
    return {
      email: 'default@ismail-platform.com',
      password: 'TestPassword123!',
      deviceInfo: 'K6 Load Test'
    };
  }
  
  // Utiliser un utilisateur existant aléatoirement
  const user = testUsers[Math.floor(Math.random() * testUsers.length)];
  return {
    email: user.email,
    password: user.password,
    deviceInfo: 'K6 Load Test'
  };
}

// Test d'inscription
export function testRegistration() {
  const userData = generateRandomUser();
  
  const response = http.post(`${API_BASE}/register`, JSON.stringify(userData), {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'registration status is 201': (r) => r.status === 201,
    'registration response has token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.accessToken !== undefined;
      } catch (e) {
        return false;
      }
    },
    'registration response time < 3s': (r) => r.timings.duration < 3000,
  });
  
  registrationSuccessRate.add(success);
  registrationDuration.add(response.timings.duration);
  
  if (success && response.status === 201) {
    // Ajouter l'utilisateur à la liste pour les tests de connexion
    testUsers.push(userData);
  } else {
    errorCount.add(1);
  }
  
  return response;
}

// Test de connexion
export function testLogin() {
  const loginData = generateLoginData();
  
  const response = http.post(`${API_BASE}/login`, JSON.stringify(loginData), {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'login status is 200': (r) => r.status === 200,
    'login response has token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.accessToken !== undefined;
      } catch (e) {
        return false;
      }
    },
    'login response time < 2s': (r) => r.timings.duration < 2000,
  });
  
  loginSuccessRate.add(success);
  loginDuration.add(response.timings.duration);
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Test d'accès au profil avec token
export function testProfileAccess(token) {
  const response = http.get(`${API_BASE}/profile`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'profile access status is 200': (r) => r.status === 200,
    'profile response has user data': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.email !== undefined;
      } catch (e) {
        return false;
      }
    },
    'profile response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Test de rafraîchissement de token
export function testTokenRefresh(refreshToken) {
  const response = http.post(`${API_BASE}/refresh`, JSON.stringify({
    refreshToken: refreshToken
  }), {
    headers: {
      'Content-Type': 'application/json',
    },
  });
  
  const success = check(response, {
    'token refresh status is 200': (r) => r.status === 200,
    'refresh response has new token': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.accessToken !== undefined;
      } catch (e) {
        return false;
      }
    },
    'refresh response time < 1s': (r) => r.timings.duration < 1000,
  });
  
  if (!success) {
    errorCount.add(1);
  }
  
  return response;
}

// Scénario principal du test
export default function () {
  const scenario = Math.random();
  
  if (scenario < 0.3) {
    // 30% des utilisateurs s'inscrivent
    console.log('Executing registration scenario');
    testRegistration();
    
  } else if (scenario < 0.8) {
    // 50% des utilisateurs se connectent
    console.log('Executing login scenario');
    const loginResponse = testLogin();
    
    if (loginResponse.status === 200) {
      try {
        const loginBody = JSON.parse(loginResponse.body);
        const token = loginBody.accessToken;
        const refreshToken = loginBody.refreshToken;
        
        // Accéder au profil après connexion
        sleep(1);
        testProfileAccess(token);
        
        // Parfois tester le refresh token
        if (Math.random() < 0.2) {
          sleep(1);
          testTokenRefresh(refreshToken);
        }
      } catch (e) {
        console.error('Error parsing login response:', e);
        errorCount.add(1);
      }
    }
    
  } else {
    // 20% des utilisateurs testent l'accès au profil directement
    console.log('Executing profile access scenario');
    // Utiliser un token fictif pour tester la validation
    testProfileAccess('invalid-token');
  }
  
  // Pause entre les requêtes pour simuler un comportement réaliste
  sleep(Math.random() * 3 + 1); // 1-4 secondes
}

// Fonction de setup (exécutée une fois au début)
export function setup() {
  console.log('Starting auth service load test');
  console.log(`Target URL: ${API_BASE}`);
  
  // Créer quelques utilisateurs de base pour les tests de connexion
  for (let i = 0; i < 5; i++) {
    const user = generateRandomUser();
    const response = http.post(`${API_BASE}/register`, JSON.stringify(user), {
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (response.status === 201) {
      testUsers.push(user);
      console.log(`Created test user: ${user.email}`);
    }
  }
  
  return { testUsers: testUsers };
}

// Fonction de teardown (exécutée une fois à la fin)
export function teardown(data) {
  console.log('Auth service load test completed');
  console.log(`Total test users created: ${data.testUsers.length}`);
  
  // Afficher un résumé des métriques
  console.log('Test Summary:');
  console.log(`- Total errors: ${errorCount.count}`);
  console.log(`- Login success rate: ${loginSuccessRate.rate * 100}%`);
  console.log(`- Registration success rate: ${registrationSuccessRate.rate * 100}%`);
}

// Configuration des tags pour le monitoring
export const tags = {
  service: 'auth-service',
  environment: __ENV.ENVIRONMENT || 'test',
  test_type: 'load_test'
};
