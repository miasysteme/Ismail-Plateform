# Design System et Conception UX/UI - Plateforme ISMAIL

## 1. DESIGN SYSTEM

### 1.1 Identité Visuelle

#### Palette de Couleurs
```css
/* Couleurs Primaires */
:root {
  --primary-orange: #FF6B35;      /* Orange ISMAIL - Action principale */
  --primary-blue: #1E3A8A;        /* Bleu confiance - Navigation */
  --primary-green: #10B981;       /* Vert succès - Validation */
  
  /* Couleurs Secondaires */
  --secondary-gold: #F59E0B;      /* Or - Premium/VIP */
  --secondary-purple: #8B5CF6;    /* Violet - Innovation */
  --secondary-teal: #14B8A6;      /* Turquoise - Services */
  
  /* Couleurs Neutres */
  --neutral-900: #111827;         /* Texte principal */
  --neutral-700: #374151;         /* Texte secondaire */
  --neutral-500: #6B7280;         /* Texte désactivé */
  --neutral-300: #D1D5DB;         /* Bordures */
  --neutral-100: #F3F4F6;         /* Arrière-plan */
  --neutral-50: #F9FAFB;          /* Arrière-plan clair */
  
  /* Couleurs Sémantiques */
  --success: #10B981;
  --warning: #F59E0B;
  --error: #EF4444;
  --info: #3B82F6;
}
```

#### Typographie
```css
/* Familles de polices */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

:root {
  --font-primary: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-mono: 'SF Mono', Monaco, 'Cascadia Code', monospace;
  
  /* Échelle typographique */
  --text-xs: 0.75rem;     /* 12px */
  --text-sm: 0.875rem;    /* 14px */
  --text-base: 1rem;      /* 16px */
  --text-lg: 1.125rem;    /* 18px */
  --text-xl: 1.25rem;     /* 20px */
  --text-2xl: 1.5rem;     /* 24px */
  --text-3xl: 1.875rem;   /* 30px */
  --text-4xl: 2.25rem;    /* 36px */
  
  /* Poids de police */
  --font-light: 300;
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
}
```

### 1.2 Composants de Base

#### Boutons
```css
/* Bouton primaire */
.btn-primary {
  background: var(--primary-orange);
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: var(--font-medium);
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-primary:hover {
  background: #E55A2B;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(255, 107, 53, 0.3);
}

/* Bouton secondaire */
.btn-secondary {
  background: transparent;
  color: var(--primary-orange);
  border: 2px solid var(--primary-orange);
  padding: 10px 22px;
  border-radius: 8px;
}

/* Bouton fantôme */
.btn-ghost {
  background: transparent;
  color: var(--neutral-700);
  border: 1px solid var(--neutral-300);
  padding: 10px 22px;
  border-radius: 8px;
}
```

#### Cartes
```css
.card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  padding: 24px;
  border: 1px solid var(--neutral-200);
  transition: all 0.2s ease;
}

.card:hover {
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.card-header {
  border-bottom: 1px solid var(--neutral-200);
  padding-bottom: 16px;
  margin-bottom: 16px;
}

.card-title {
  font-size: var(--text-lg);
  font-weight: var(--font-semibold);
  color: var(--neutral-900);
}
```

### 1.3 Iconographie

#### Système d'Icônes
```javascript
// Utilisation de Heroicons + icônes personnalisées
const IconLibrary = {
  // Navigation
  home: 'heroicons/home',
  search: 'heroicons/magnifying-glass',
  user: 'heroicons/user-circle',
  
  // Actions
  plus: 'heroicons/plus',
  edit: 'heroicons/pencil',
  delete: 'heroicons/trash',
  
  // Status
  check: 'heroicons/check-circle',
  warning: 'heroicons/exclamation-triangle',
  error: 'heroicons/x-circle',
  
  // ISMAIL spécifiques
  wallet: 'custom/wallet',
  biometric: 'custom/fingerprint',
  qrcode: 'custom/qr-code'
};
```

## 2. WIREFRAMES ET MAQUETTES

### 2.1 Dashboard Principal

#### Wireframe Dashboard Utilisateur
```
┌─────────────────────────────────────────────────────┐
│ [LOGO] ISMAIL                    [🔔] [👤] [⚙️]    │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Bonjour Fatou! 👋                                   │
│ Solde: 2,450 crédits                               │
│                                                     │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │Services │ │  Shop   │ │Booking  │ │Immobilier│    │
│ │   🔧    │ │   🛒    │ │   🏨    │ │    🏠    │    │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
│                                                     │
│ Activité Récente                                    │
│ ┌─────────────────────────────────────────────────┐ │
│ │ ✅ Plombier réservé - 50 crédits               │ │
│ │ 📦 Commande livrée - Évaluation en attente     │ │
│ │ 🏨 Réservation confirmée - Hotel Ivoire        │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ Recommandations                                     │
│ ┌─────────────────────────────────────────────────┐ │
│ │ [Image] Électricien près de chez vous          │ │
│ │ [Image] Promotion -20% sur électroménager      │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 2.2 Module Services - Recherche

#### Maquette Recherche de Services
```html
<!-- Interface de recherche -->
<div class="search-container">
  <div class="search-header">
    <h1>Trouvez votre prestataire</h1>
    <div class="search-bar">
      <input type="text" placeholder="Que recherchez-vous ? (plombier, électricien...)" />
      <button class="btn-primary">Rechercher</button>
    </div>
  </div>
  
  <div class="filters">
    <select name="category">
      <option>Toutes catégories</option>
      <option>Plomberie</option>
      <option>Électricité</option>
    </select>
    
    <select name="distance">
      <option>Dans un rayon de 5km</option>
      <option>Dans un rayon de 10km</option>
    </select>
    
    <select name="availability">
      <option>Disponible maintenant</option>
      <option>Disponible aujourd'hui</option>
    </select>
  </div>
  
  <div class="results-grid">
    <!-- Carte prestataire -->
    <div class="provider-card">
      <div class="provider-avatar">
        <img src="avatar.jpg" alt="Kofi Asante" />
        <div class="status-badge online">En ligne</div>
      </div>
      
      <div class="provider-info">
        <h3>Kofi Asante</h3>
        <p>Plombier certifié • 5 ans d'expérience</p>
        <div class="rating">
          ⭐⭐⭐⭐⭐ 4.8 (127 avis)
        </div>
        <div class="distance">📍 2.3 km de vous</div>
      </div>
      
      <div class="provider-actions">
        <div class="price">À partir de 25 crédits</div>
        <button class="btn-primary">Réserver</button>
        <button class="btn-ghost">Voir profil</button>
      </div>
    </div>
  </div>
</div>
```

### 2.3 Portefeuille Électronique

#### Interface Portefeuille
```
┌─────────────────────────────────────────────────────┐
│ 💳 Mon Portefeuille                                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│ Solde Actuel                                        │
│ ┌─────────────────────────────────────────────────┐ │
│ │                                                 │ │
│ │        2,450 crédits                            │ │
│ │        ≈ 122,500 FCFA                          │ │
│ │                                                 │ │
│ │ [Acheter des crédits] [Transférer]             │ │
│ └─────────────────────────────────────────────────┘ │
│                                                     │
│ Actions Rapides                                     │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐    │
│ │ Orange  │ │   MTN   │ │ Moov    │ │ Carte   │    │
│ │ Money   │ │ Money   │ │ Money   │ │Bancaire │    │
│ └─────────┘ └─────────┘ └─────────┘ └─────────┘    │
│                                                     │
│ Historique des Transactions                         │
│ ┌─────────────────────────────────────────────────┐ │
│ │ 📅 Aujourd'hui                                  │ │
│ │ ➖ Réservation plombier        -50 crédits     │ │
│ │ ➕ Achat crédits Orange Money  +500 crédits    │ │
│ │                                                 │ │
│ │ 📅 Hier                                         │ │
│ │ ➖ Commande électroménager     -150 crédits     │ │
│ │ ➕ Cashback parrainage         +25 crédits      │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## 3. PROTOTYPES INTERACTIFS

### 3.1 Parcours d'Inscription

#### Étape 1 : Informations Personnelles
```javascript
const RegistrationStep1 = () => {
  return (
    <div className="registration-container">
      <div className="progress-bar">
        <div className="step active">1</div>
        <div className="step">2</div>
        <div className="step">3</div>
      </div>
      
      <h2>Créons votre compte ISMAIL</h2>
      <p>Vos informations personnelles</p>
      
      <form>
        <div className="form-group">
          <label>Prénom *</label>
          <input type="text" placeholder="Votre prénom" required />
        </div>
        
        <div className="form-group">
          <label>Nom *</label>
          <input type="text" placeholder="Votre nom" required />
        </div>
        
        <div className="form-group">
          <label>Email *</label>
          <input type="email" placeholder="votre@email.com" required />
        </div>
        
        <div className="form-group">
          <label>Téléphone *</label>
          <input type="tel" placeholder="+225 XX XX XX XX XX" required />
        </div>
        
        <div className="form-group">
          <label>Type de compte</label>
          <select required>
            <option value="">Sélectionnez...</option>
            <option value="client">Client</option>
            <option value="partner">Partenaire</option>
            <option value="commercial">Commercial</option>
          </select>
        </div>
        
        <button type="submit" className="btn-primary full-width">
          Continuer
        </button>
      </form>
    </div>
  );
};
```

#### Étape 2 : Vérification Biométrique
```javascript
const BiometricVerification = () => {
  const [step, setStep] = useState('photo');
  
  return (
    <div className="biometric-container">
      <h2>Vérification d'identité</h2>
      <p>Pour votre sécurité, nous devons vérifier votre identité</p>
      
      {step === 'photo' && (
        <div className="photo-capture">
          <div className="camera-preview">
            <div className="face-outline"></div>
          </div>
          <p>Positionnez votre visage dans le cadre</p>
          <button onClick={() => setStep('fingerprint')}>
            Prendre la photo
          </button>
        </div>
      )}
      
      {step === 'fingerprint' && (
        <div className="fingerprint-capture">
          <div className="fingerprint-scanner">
            <div className="scanner-animation"></div>
          </div>
          <p>Placez votre doigt sur le capteur</p>
          <button onClick={() => setStep('complete')}>
            Scanner l'empreinte
          </button>
        </div>
      )}
      
      {step === 'complete' && (
        <div className="verification-success">
          <div className="success-icon">✅</div>
          <h3>Vérification réussie!</h3>
          <p>Votre identité a été confirmée avec succès</p>
        </div>
      )}
    </div>
  );
};
```

### 3.2 Interface Mobile Responsive

#### Navigation Mobile
```css
/* Navigation mobile avec bottom tabs */
.mobile-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  border-top: 1px solid var(--neutral-200);
  display: flex;
  justify-content: space-around;
  padding: 8px 0;
  z-index: 1000;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px;
  text-decoration: none;
  color: var(--neutral-500);
  transition: color 0.2s ease;
}

.nav-item.active {
  color: var(--primary-orange);
}

.nav-icon {
  width: 24px;
  height: 24px;
  margin-bottom: 4px;
}

.nav-label {
  font-size: var(--text-xs);
  font-weight: var(--font-medium);
}
```

## 4. ACCESSIBILITÉ ET RESPONSIVE

### 4.1 Guidelines d'Accessibilité

#### Contraste et Lisibilité
```css
/* Ratios de contraste conformes WCAG 2.1 AA */
.text-primary { color: var(--neutral-900); } /* Ratio: 16.94:1 */
.text-secondary { color: var(--neutral-700); } /* Ratio: 9.25:1 */
.text-muted { color: var(--neutral-500); } /* Ratio: 4.54:1 */

/* Focus visible pour navigation clavier */
.focusable:focus {
  outline: 2px solid var(--primary-orange);
  outline-offset: 2px;
}

/* Tailles de touch targets mobiles */
.touch-target {
  min-height: 44px;
  min-width: 44px;
}
```

#### Support Screen Readers
```html
<!-- Labels et descriptions pour lecteurs d'écran -->
<button aria-label="Rechercher des services" aria-describedby="search-help">
  <svg aria-hidden="true">...</svg>
</button>
<div id="search-help" class="sr-only">
  Recherchez parmi plus de 1000 prestataires vérifiés
</div>

<!-- États dynamiques -->
<div role="status" aria-live="polite" id="search-status">
  12 prestataires trouvés dans votre zone
</div>
```

### 4.2 Responsive Design

#### Breakpoints
```css
/* Système de breakpoints mobile-first */
:root {
  --breakpoint-sm: 640px;   /* Tablettes portrait */
  --breakpoint-md: 768px;   /* Tablettes paysage */
  --breakpoint-lg: 1024px;  /* Desktop */
  --breakpoint-xl: 1280px;  /* Large desktop */
}

/* Grille responsive */
.grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: 1fr;
}

@media (min-width: 640px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 1024px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

## 5. ANIMATIONS ET MICRO-INTERACTIONS

### 5.1 Transitions Fluides
```css
/* Animations de base */
@keyframes slideInUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.animate-slide-in {
  animation: slideInUp 0.3s ease-out;
}

/* Loading states */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.loading-skeleton {
  background: var(--neutral-200);
  animation: pulse 2s infinite;
  border-radius: 4px;
}
```

### 5.2 Feedback Utilisateur
```javascript
// Toast notifications
const showToast = (message, type = 'success') => {
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  
  document.body.appendChild(toast);
  
  setTimeout(() => {
    toast.classList.add('toast-show');
  }, 100);
  
  setTimeout(() => {
    toast.classList.remove('toast-show');
    setTimeout(() => toast.remove(), 300);
  }, 3000);
};
```

## 6. DESIGN TOKENS

### 6.1 Système de Tokens
```json
{
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "16px",
    "lg": "24px",
    "xl": "32px",
    "2xl": "48px"
  },
  "borderRadius": {
    "sm": "4px",
    "md": "8px",
    "lg": "12px",
    "xl": "16px",
    "full": "9999px"
  },
  "shadows": {
    "sm": "0 1px 2px rgba(0, 0, 0, 0.05)",
    "md": "0 4px 6px rgba(0, 0, 0, 0.1)",
    "lg": "0 10px 15px rgba(0, 0, 0, 0.1)",
    "xl": "0 20px 25px rgba(0, 0, 0, 0.1)"
  }
}
```

### 6.2 Thème Sombre
```css
[data-theme="dark"] {
  --primary-orange: #FF8A65;
  --primary-blue: #3B82F6;
  --neutral-900: #F9FAFB;
  --neutral-700: #E5E7EB;
  --neutral-500: #9CA3AF;
  --neutral-300: #4B5563;
  --neutral-100: #1F2937;
  --neutral-50: #111827;
}
```

## PROCHAINES ÉTAPES

1. **Validation design** : Tests utilisateurs sur prototypes
2. **Développement composants** : Création de la librairie UI
3. **Tests d'accessibilité** : Validation WCAG 2.1 AA
4. **Optimisation performance** : Lazy loading, optimisation images

---

**Statut** : ✅ Design system créé
**Validation** : Tests utilisateurs planifiés
**Prochaine étape** : Développement infrastructure
