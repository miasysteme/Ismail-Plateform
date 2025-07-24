# Spécifications Fonctionnelles Détaillées - Plateforme ISMAIL

## 1. MODULE CORE PLATFORM

### 1.1 Système d'Authentification et KYC

#### User Stories
```
En tant qu'utilisateur, je veux créer un compte sécurisé
GIVEN je suis un nouvel utilisateur
WHEN je fournis mes informations personnelles et biométriques
THEN un ID unique est généré et ma carte professionnelle est créée
AND je reçois une notification de confirmation
```

#### Critères d'Acceptation
- [ ] Formulaire d'inscription en 3 étapes max
- [ ] Capture biométrique (empreinte + photo) obligatoire
- [ ] Validation documents d'identité automatique
- [ ] Génération ID unique format CCYYMMDD-XXXX-UL
- [ ] Création carte professionnelle avec QR code
- [ ] Notification multi-canal (SMS + Email)
- [ ] Conformité RGPD (consentement explicite)

#### Règles Métier
- Âge minimum : 18 ans
- Documents acceptés : CNI, Passeport, Permis de conduire
- Délai validation : 24h maximum
- Tentatives biométriques : 3 maximum
- Renouvellement carte : 12 mois

### 1.2 Portefeuille Électronique

#### User Stories
```
En tant qu'utilisateur, je veux gérer mes crédits facilement
GIVEN j'ai un compte validé
WHEN j'achète des crédits via mobile money
THEN mon solde est mis à jour instantanément
AND je reçois une facture électronique
```

#### Fonctionnalités Clés
- **Achat de crédits** : Mobile money, carte bancaire, virement
- **Consommation** : Débit automatique lors des transactions
- **Historique** : Toutes transactions avec détails
- **Transferts** : Entre comptes autorisés (limites)
- **Bonus/Cashback** : Système de récompenses
- **Commissions** : Calcul et versement automatiques

#### API Endpoints
```
POST /api/wallet/purchase-credits
GET /api/wallet/balance
GET /api/wallet/transactions
POST /api/wallet/transfer
GET /api/wallet/commissions
```

## 2. MODULE ISMAIL SERVICES

### 2.1 Gestion des Prestataires

#### User Stories
```
En tant que prestataire, je veux créer mon profil professionnel
GIVEN je suis un artisan validé KYC
WHEN je complète mon profil avec services et tarifs
THEN je suis visible dans les recherches clients
AND je peux recevoir des demandes de devis
```

#### Fonctionnalités
- **Profil détaillé** : Photos, descriptions, certifications
- **Catalogue services** : Tarifs, durées, disponibilités
- **Géolocalisation** : Zone d'intervention paramétrable
- **Calendrier** : Disponibilités en temps réel
- **Portfolio** : Galerie photos réalisations
- **Évaluations** : Système de notation clients

### 2.2 Recherche et Réservation

#### User Stories
```
En tant que client, je veux trouver un plombier rapidement
GIVEN j'ai une urgence plomberie
WHEN je recherche "plombier" avec ma localisation
THEN je vois les plombiers disponibles triés par proximité
AND je peux réserver directement avec paiement sécurisé
```

#### Critères de Recherche
- **Géographique** : Rayon paramétrable (1-50km)
- **Catégorie** : Plomberie, Électricité, Serrurerie, etc.
- **Disponibilité** : Immédiate, aujourd'hui, cette semaine
- **Prix** : Fourchettes tarifaires
- **Évaluation** : Minimum 4 étoiles par défaut
- **Urgence** : Intervention <2h disponible

## 3. MODULE ISMAIL SHOP

### 3.1 Gestion Catalogue

#### User Stories
```
En tant que marchand, je veux gérer mon inventaire facilement
GIVEN j'ai des produits à vendre
WHEN j'ajoute un produit avec photos et description
THEN il est immédiatement visible aux clients
AND le stock est mis à jour automatiquement
```

#### Fonctionnalités Catalogue
- **Produits** : Fiches détaillées avec variantes
- **Catégorisation** : Arbre hiérarchique personnalisable
- **Stocks** : Gestion temps réel avec alertes
- **Prix** : Tarification dynamique, promotions
- **Médias** : Photos HD, vidéos, 360°
- **SEO** : Optimisation recherche interne

### 3.2 Commandes et Livraisons

#### Workflow Commande
```
1. Ajout panier → 2. Validation → 3. Paiement → 4. Préparation → 5. Expédition → 6. Livraison → 7. Évaluation
```

#### Statuts de Commande
- **En attente** : Paiement en cours
- **Confirmée** : Paiement validé
- **En préparation** : Marchand prépare
- **Expédiée** : En cours de livraison
- **Livrée** : Client a reçu
- **Annulée** : Annulation avant expédition

## 4. MODULE ISMAIL BOOKING

### 4.1 Gestion des Disponibilités

#### User Stories
```
En tant qu'hôtelier, je veux gérer mes chambres facilement
GIVEN j'ai un hôtel avec 20 chambres
WHEN je mets à jour mes disponibilités
THEN les clients voient les créneaux libres en temps réel
AND les réservations bloquent automatiquement les dates
```

#### Fonctionnalités Calendrier
- **Multi-ressources** : Chambres, salles, véhicules
- **Tarification dynamique** : Prix selon demande/saison
- **Règles métier** : Durée min/max, délais annulation
- **Overbooking** : Gestion intelligente avec alertes
- **Synchronisation** : APIs externes (Booking.com, etc.)

### 4.2 Processus de Réservation

#### Étapes Réservation
```
1. Recherche → 2. Sélection → 3. Options → 4. Paiement → 5. Confirmation → 6. Rappels → 7. Check-in
```

#### Politiques Flexibles
- **Annulation gratuite** : Jusqu'à 24h avant
- **Modification** : Une fois sans frais
- **No-show** : Facturation 50% du montant
- **Remboursement** : Selon conditions partenaire

## 5. MODULE ISMAIL IMMOBILIER

### 5.1 Gestion des Annonces

#### User Stories
```
En tant qu'agent immobilier, je veux publier des biens attractifs
GIVEN j'ai un appartement à louer
WHEN je crée une annonce avec photos et détails
THEN elle est visible avec géolocalisation précise
AND les candidats peuvent demander des visites
```

#### Champs Obligatoires
- **Type** : Appartement, Maison, Bureau, Terrain
- **Transaction** : Vente, Location, Saisonnière
- **Surface** : Habitable et totale
- **Localisation** : Adresse précise + carte
- **Prix** : Montant + charges éventuelles
- **Photos** : Minimum 5, maximum 20
- **Description** : Détaillée avec équipements

### 5.2 Gestion Locative

#### Fonctionnalités Propriétaire
- **Contrats** : Génération automatique baux
- **Quittances** : Émission mensuelle automatique
- **Charges** : Répartition et facturation
- **État des lieux** : Templates numériques
- **Relances** : Intégration module Recouvrement

## 6. MODULE ISMAIL RECOUVREMENT

### 6.1 Gestion des Créances

#### User Stories
```
En tant que propriétaire, je veux automatiser le recouvrement
GIVEN un locataire a 15 jours de retard
WHEN le système détecte l'impayé
THEN une relance automatique est envoyée
AND le dossier est créé dans le module recouvrement
```

#### Types de Créances
- **Locatives** : Loyers, charges, dépôts
- **Commerciales** : Factures impayées
- **Services** : Prestations non réglées
- **Pénalités** : Retards, dommages

### 6.2 Scénarios de Relance

#### Escalade Automatique
```
J+1 : SMS de rappel amical
J+7 : Email de mise en demeure
J+15 : Courrier recommandé
J+30 : Procédure judiciaire
```

#### Personnalisation
- **Ton** : Amical → Ferme → Juridique
- **Canaux** : SMS, Email, Courrier, Appel
- **Fréquence** : Paramétrable par créancier
- **Seuils** : Montants déclencheurs

## 7. SYSTÈME DE NOTIFICATIONS

### 7.1 Types de Notifications

#### Transactionnelles
- Confirmation commande/réservation
- Paiement reçu/débité
- Livraison en cours
- Évaluation demandée

#### Marketing
- Promotions personnalisées
- Nouveaux services disponibles
- Cashback disponible
- Parrainage récompensé

#### Alertes Système
- Solde insuffisant
- Document expiré
- Maintenance programmée
- Sécurité compromise

### 7.2 Canaux de Communication

#### Configuration par Utilisateur
```json
{
  "preferences": {
    "push": true,
    "sms": true,
    "email": false,
    "whatsapp": true
  },
  "frequency": {
    "marketing": "weekly",
    "transactional": "immediate",
    "alerts": "immediate"
  }
}
```

## 8. APIS ET INTÉGRATIONS

### 8.1 APIs Internes

#### Core APIs
```
/api/auth/* - Authentification
/api/users/* - Gestion utilisateurs
/api/wallet/* - Portefeuille
/api/notifications/* - Notifications
/api/documents/* - Gestion documentaire
```

#### Module APIs
```
/api/services/* - ISMAIL Services
/api/shop/* - ISMAIL Shop
/api/booking/* - ISMAIL Booking
/api/realestate/* - ISMAIL Immobilier
/api/recovery/* - ISMAIL Recouvrement
```

### 8.2 Intégrations Externes

#### Paiements
- **Orange Money** : API REST + Webhooks
- **MTN Money** : API SOAP + Callbacks
- **Visa/Mastercard** : Tokenisation + 3DS
- **Banques** : Open Banking APIs

#### Services Tiers
- **Google Maps** : Géolocalisation + Directions
- **SendGrid** : Email transactionnel
- **Twilio** : SMS + Voice
- **Firebase** : Push notifications

## PROCHAINES ÉTAPES

1. **Validation** : Review avec équipe métier
2. **Priorisation** : MoSCoW des fonctionnalités
3. **Architecture** : Conception technique détaillée
4. **Prototypage** : Maquettes interactives

---

**Statut** : ✅ Spécifications complétées
**Validation** : En attente stakeholders
**Prochaine étape** : Architecture Technique
