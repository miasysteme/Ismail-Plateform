// Script d'initialisation MongoDB - Plateforme ISMAIL
// Création des collections, index et données de référence

// =====================================================
// CONNEXION ET CONFIGURATION
// =====================================================

// Connexion à la base principale
use ismail_main;

print("=== Initialisation MongoDB ISMAIL ===");

// =====================================================
// CRÉATION DES COLLECTIONS AVEC VALIDATION
// =====================================================

// Collection profils utilisateurs étendus
db.createCollection("user_profiles", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "createdAt"],
      properties: {
        userId: {
          bsonType: "string",
          pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
          description: "UUID de référence utilisateur PostgreSQL"
        },
        avatar: {
          bsonType: "object",
          properties: {
            url: { bsonType: "string" },
            thumbnailUrl: { bsonType: "string" }
          }
        },
        bio: {
          bsonType: "string",
          maxLength: 500
        },
        location: {
          bsonType: "object",
          required: ["type", "coordinates"],
          properties: {
            type: { enum: ["Point"] },
            coordinates: {
              bsonType: "array",
              minItems: 2,
              maxItems: 2,
              items: { bsonType: "double" }
            }
          }
        },
        address: {
          bsonType: "object",
          properties: {
            street: { bsonType: "string" },
            city: { bsonType: "string" },
            district: { bsonType: "string" },
            postalCode: { bsonType: "string" },
            country: { bsonType: "string" }
          }
        },
        preferences: {
          bsonType: "object",
          properties: {
            language: { enum: ["fr", "en", "ar"] },
            currency: { enum: ["XOF", "EUR", "USD"] },
            notifications: {
              bsonType: "object",
              properties: {
                email: { bsonType: "bool" },
                sms: { bsonType: "bool" },
                push: { bsonType: "bool" }
              }
            }
          }
        },
        socialLinks: {
          bsonType: "object",
          properties: {
            facebook: { bsonType: "string" },
            linkedin: { bsonType: "string" },
            website: { bsonType: "string" }
          }
        },
        documents: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["type", "url", "uploadedAt"],
            properties: {
              type: { enum: ["ID_CARD", "PASSPORT", "DRIVING_LICENSE", "BUSINESS_LICENSE"] },
              url: { bsonType: "string" },
              verificationStatus: { enum: ["PENDING", "VERIFIED", "REJECTED"] },
              uploadedAt: { bsonType: "date" },
              expiresAt: { bsonType: "date" }
            }
          }
        },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

// Collection catalogue produits
db.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["merchantId", "name", "price", "status", "createdAt"],
      properties: {
        merchantId: {
          bsonType: "string",
          pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        },
        sku: { bsonType: "string" },
        name: {
          bsonType: "string",
          minLength: 1,
          maxLength: 255
        },
        description: {
          bsonType: "string",
          maxLength: 2000
        },
        category: { bsonType: "string" },
        subcategory: { bsonType: "string" },
        brand: { bsonType: "string" },
        price: {
          bsonType: "decimal",
          minimum: 0
        },
        compareAtPrice: {
          bsonType: "decimal",
          minimum: 0
        },
        currency: { enum: ["XOF", "EUR", "USD"] },
        stock: {
          bsonType: "object",
          properties: {
            quantity: { bsonType: "int", minimum: 0 },
            lowStockThreshold: { bsonType: "int", minimum: 0 },
            trackQuantity: { bsonType: "bool" }
          }
        },
        variants: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              id: { bsonType: "string" },
              name: { bsonType: "string" },
              price: { bsonType: "decimal" },
              stock: { bsonType: "int" },
              sku: { bsonType: "string" }
            }
          }
        },
        images: {
          bsonType: "array",
          items: {
            bsonType: "object",
            properties: {
              url: { bsonType: "string" },
              alt: { bsonType: "string" },
              position: { bsonType: "int" }
            }
          }
        },
        specifications: { bsonType: "object" },
        seo: {
          bsonType: "object",
          properties: {
            title: { bsonType: "string" },
            description: { bsonType: "string" },
            keywords: {
              bsonType: "array",
              items: { bsonType: "string" }
            }
          }
        },
        rating: {
          bsonType: "object",
          properties: {
            average: { bsonType: "double", minimum: 0, maximum: 5 },
            count: { bsonType: "int", minimum: 0 }
          }
        },
        status: { enum: ["ACTIVE", "INACTIVE", "DRAFT"] },
        isDigital: { bsonType: "bool" },
        shippingRequired: { bsonType: "bool" },
        tags: {
          bsonType: "array",
          items: { bsonType: "string" }
        },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

// Collection avis et évaluations
db.createCollection("reviews", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["authorId", "targetId", "targetType", "rating", "createdAt"],
      properties: {
        authorId: {
          bsonType: "string",
          pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        },
        targetId: {
          bsonType: "string",
          pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        },
        targetType: { enum: ["PRODUCT", "SERVICE", "PROVIDER", "HOTEL", "PROPERTY"] },
        rating: {
          bsonType: "int",
          minimum: 1,
          maximum: 5
        },
        title: {
          bsonType: "string",
          maxLength: 100
        },
        comment: {
          bsonType: "string",
          maxLength: 1000
        },
        images: {
          bsonType: "array",
          items: { bsonType: "string" }
        },
        isVerifiedPurchase: { bsonType: "bool" },
        helpfulVotes: { bsonType: "int", minimum: 0 },
        reportedCount: { bsonType: "int", minimum: 0 },
        status: { enum: ["PUBLISHED", "PENDING", "REJECTED", "HIDDEN"] },
        moderatedBy: { bsonType: "string" },
        moderatedAt: { bsonType: "date" },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

// Collection notifications
db.createCollection("notifications", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["userId", "type", "title", "message", "createdAt"],
      properties: {
        userId: {
          bsonType: "string",
          pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
        },
        type: {
          enum: [
            "ORDER_CONFIRMED", "ORDER_SHIPPED", "ORDER_DELIVERED",
            "BOOKING_CONFIRMED", "BOOKING_REMINDER", "BOOKING_CANCELLED",
            "PAYMENT_RECEIVED", "PAYMENT_FAILED", "WALLET_CREDITED",
            "COMMISSION_EARNED", "REVIEW_RECEIVED", "SYSTEM_MAINTENANCE"
          ]
        },
        title: {
          bsonType: "string",
          maxLength: 100
        },
        message: {
          bsonType: "string",
          maxLength: 500
        },
        data: { bsonType: "object" },
        channels: {
          bsonType: "array",
          items: { enum: ["PUSH", "EMAIL", "SMS", "IN_APP"] }
        },
        status: { enum: ["PENDING", "SENT", "DELIVERED", "READ", "FAILED"] },
        priority: { enum: ["LOW", "NORMAL", "HIGH", "URGENT"] },
        scheduledAt: { bsonType: "date" },
        sentAt: { bsonType: "date" },
        deliveredAt: { bsonType: "date" },
        readAt: { bsonType: "date" },
        failureReason: { bsonType: "string" },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

// Collection événements analytics
db.createCollection("analytics_events", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["eventType", "timestamp"],
      properties: {
        userId: { bsonType: "string" },
        sessionId: { bsonType: "string" },
        eventType: {
          enum: [
            "PAGE_VIEW", "PRODUCT_VIEW", "SEARCH", "ADD_TO_CART",
            "PURCHASE", "LOGIN", "LOGOUT", "REGISTRATION",
            "SERVICE_BOOKING", "REVIEW_SUBMITTED", "WALLET_TRANSACTION"
          ]
        },
        eventData: { bsonType: "object" },
        userAgent: { bsonType: "string" },
        ipAddress: { bsonType: "string" },
        location: {
          bsonType: "object",
          properties: {
            country: { bsonType: "string" },
            city: { bsonType: "string" },
            coordinates: {
              bsonType: "array",
              items: { bsonType: "double" }
            }
          }
        },
        timestamp: { bsonType: "date" }
      }
    }
  }
});

// Collection contenus CMS
db.createCollection("cms_contents", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["contentType", "slug", "title", "status"],
      properties: {
        contentType: { enum: ["PAGE", "ARTICLE", "FAQ", "LEGAL", "HELP"] },
        slug: { bsonType: "string" },
        title: { bsonType: "string" },
        content: { bsonType: "string" },
        excerpt: { bsonType: "string" },
        featuredImage: { bsonType: "string" },
        seo: {
          bsonType: "object",
          properties: {
            metaTitle: { bsonType: "string" },
            metaDescription: { bsonType: "string" },
            keywords: {
              bsonType: "array",
              items: { bsonType: "string" }
            }
          }
        },
        status: { enum: ["DRAFT", "PUBLISHED", "ARCHIVED"] },
        publishedAt: { bsonType: "date" },
        authorId: { bsonType: "string" },
        createdAt: { bsonType: "date" },
        updatedAt: { bsonType: "date" }
      }
    }
  }
});

print("Collections créées avec validation des schémas");

// =====================================================
// CRÉATION DES INDEX
// =====================================================

print("Création des index...");

// Index pour user_profiles
db.user_profiles.createIndex({ "userId": 1 }, { unique: true });
db.user_profiles.createIndex({ "location": "2dsphere" });
db.user_profiles.createIndex({ "createdAt": 1 });
db.user_profiles.createIndex({ "preferences.language": 1 });

// Index pour products
db.products.createIndex({ "merchantId": 1 });
db.products.createIndex({ "category": 1, "subcategory": 1 });
db.products.createIndex({ "name": "text", "description": "text" }, { 
  weights: { "name": 10, "description": 5 },
  name: "product_text_search"
});
db.products.createIndex({ "price": 1 });
db.products.createIndex({ "rating.average": -1 });
db.products.createIndex({ "status": 1 });
db.products.createIndex({ "createdAt": -1 });
db.products.createIndex({ "tags": 1 });
db.products.createIndex({ "sku": 1 }, { unique: true, sparse: true });

// Index pour reviews
db.reviews.createIndex({ "targetId": 1, "targetType": 1 });
db.reviews.createIndex({ "authorId": 1 });
db.reviews.createIndex({ "rating": -1 });
db.reviews.createIndex({ "status": 1 });
db.reviews.createIndex({ "createdAt": -1 });
db.reviews.createIndex({ "isVerifiedPurchase": 1 });

// Index pour notifications
db.notifications.createIndex({ "userId": 1, "createdAt": -1 });
db.notifications.createIndex({ "status": 1 });
db.notifications.createIndex({ "type": 1 });
db.notifications.createIndex({ "priority": 1 });
db.notifications.createIndex({ "scheduledAt": 1 });
db.notifications.createIndex({ "readAt": 1 });

// Index pour analytics_events avec TTL (90 jours)
db.analytics_events.createIndex({ "userId": 1, "timestamp": -1 });
db.analytics_events.createIndex({ "eventType": 1, "timestamp": -1 });
db.analytics_events.createIndex({ "sessionId": 1 });
db.analytics_events.createIndex({ "timestamp": 1 }, { 
  expireAfterSeconds: 7776000  // 90 jours
});

// Index pour cms_contents
db.cms_contents.createIndex({ "slug": 1 }, { unique: true });
db.cms_contents.createIndex({ "contentType": 1, "status": 1 });
db.cms_contents.createIndex({ "publishedAt": -1 });
db.cms_contents.createIndex({ "title": "text", "content": "text" });

print("Index créés avec succès");

// =====================================================
// DONNÉES DE RÉFÉRENCE
// =====================================================

print("Insertion des données de référence...");

// Catégories de produits
db.product_categories.insertMany([
  {
    _id: "electronics",
    name: "Électronique",
    description: "Appareils électroniques et accessoires",
    subcategories: [
      { id: "smartphones", name: "Smartphones" },
      { id: "laptops", name: "Ordinateurs portables" },
      { id: "tablets", name: "Tablettes" },
      { id: "accessories", name: "Accessoires" }
    ],
    isActive: true,
    createdAt: new Date()
  },
  {
    _id: "fashion",
    name: "Mode",
    description: "Vêtements et accessoires de mode",
    subcategories: [
      { id: "men-clothing", name: "Vêtements homme" },
      { id: "women-clothing", name: "Vêtements femme" },
      { id: "shoes", name: "Chaussures" },
      { id: "bags", name: "Sacs et maroquinerie" }
    ],
    isActive: true,
    createdAt: new Date()
  },
  {
    _id: "home-garden",
    name: "Maison & Jardin",
    description: "Articles pour la maison et le jardin",
    subcategories: [
      { id: "furniture", name: "Mobilier" },
      { id: "decoration", name: "Décoration" },
      { id: "appliances", name: "Électroménager" },
      { id: "garden", name: "Jardin" }
    ],
    isActive: true,
    createdAt: new Date()
  }
]);

// Types de services
db.service_categories.insertMany([
  {
    _id: "home-services",
    name: "Services à domicile",
    description: "Services de réparation et maintenance",
    subcategories: [
      { id: "plumbing", name: "Plomberie" },
      { id: "electricity", name: "Électricité" },
      { id: "locksmith", name: "Serrurerie" },
      { id: "cleaning", name: "Ménage" }
    ],
    isActive: true,
    createdAt: new Date()
  },
  {
    _id: "professional-services",
    name: "Services professionnels",
    description: "Services aux entreprises et particuliers",
    subcategories: [
      { id: "accounting", name: "Comptabilité" },
      { id: "legal", name: "Juridique" },
      { id: "consulting", name: "Conseil" },
      { id: "marketing", name: "Marketing" }
    ],
    isActive: true,
    createdAt: new Date()
  }
]);

// Templates de notifications
db.notification_templates.insertMany([
  {
    _id: "welcome_user",
    type: "WELCOME",
    title: "Bienvenue sur ISMAIL !",
    message: "Votre compte a été créé avec succès. Découvrez nos services.",
    channels: ["EMAIL", "PUSH"],
    isActive: true,
    createdAt: new Date()
  },
  {
    _id: "order_confirmed",
    type: "ORDER_CONFIRMED",
    title: "Commande confirmée",
    message: "Votre commande #{orderNumber} a été confirmée et sera traitée sous peu.",
    channels: ["EMAIL", "SMS", "PUSH"],
    isActive: true,
    createdAt: new Date()
  },
  {
    _id: "wallet_credited",
    type: "WALLET_CREDITED",
    title: "Portefeuille crédité",
    message: "Votre portefeuille a été crédité de {amount} crédits.",
    channels: ["PUSH", "SMS"],
    isActive: true,
    createdAt: new Date()
  }
]);

print("Données de référence insérées");

// =====================================================
// CONFIGURATION DES RÔLES ET PERMISSIONS
// =====================================================

// Basculer vers admin pour créer les rôles
use admin;

// Rôle pour l'application
db.createRole({
  role: "ismailAppRole",
  privileges: [
    {
      resource: { db: "ismail_main", collection: "" },
      actions: ["find", "insert", "update", "remove", "createIndex"]
    }
  ],
  roles: []
});

// Rôle lecture seule
db.createRole({
  role: "ismailReadOnlyRole",
  privileges: [
    {
      resource: { db: "ismail_main", collection: "" },
      actions: ["find"]
    }
  ],
  roles: []
});

// Rôle backup
db.createRole({
  role: "ismailBackupRole",
  privileges: [
    {
      resource: { db: "ismail_main", collection: "" },
      actions: ["find"]
    },
    {
      resource: { cluster: true },
      actions: ["listCollections", "listIndexes"]
    }
  ],
  roles: []
});

print("Rôles créés avec succès");

// =====================================================
// FINALISATION
// =====================================================

use ismail_main;

// Statistiques finales
print("=== Statistiques de la base ===");
print("Collections créées: " + db.getCollectionNames().length);
print("Index créés: " + db.stats().indexes);

// Vérification de l'intégrité
db.runCommand({ "validate": "user_profiles" });
db.runCommand({ "validate": "products" });
db.runCommand({ "validate": "reviews" });
db.runCommand({ "validate": "notifications" });

print("=== Initialisation MongoDB ISMAIL terminée ===");
print("Base de données prête pour la production !");

// Affichage des informations de connexion
print("\n=== Informations de connexion ===");
print("Base de données: ismail_main");
print("Utilisateurs créés:");
print("- ismail_app (lecture/écriture)");
print("- ismail_readonly (lecture seule)");
print("- ismail_backup (backup)");
print("\nCollections principales:");
print("- user_profiles (profils utilisateurs)");
print("- products (catalogue produits)");
print("- reviews (avis et évaluations)");
print("- notifications (notifications)");
print("- analytics_events (événements analytics)");
print("- cms_contents (contenus CMS)");
