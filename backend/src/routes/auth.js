/**
 * Authentication Routes for ISMAIL Platform
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { db } = require('../config/supabase');
const { generateIsmailId } = require('../utils/idGenerator');

const router = express.Router();

// ==============================================
// VALIDATION RULES
// ==============================================

const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email invalide'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Le mot de passe doit contenir au moins 8 caractères')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Le mot de passe doit contenir au moins une majuscule, une minuscule, un chiffre et un caractère spécial'),
  body('firstName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Le prénom doit contenir entre 2 et 50 caractères'),
  body('lastName')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Le nom doit contenir entre 2 et 50 caractères'),
  body('phone')
    .isMobilePhone(['fr-CI', 'fr-BF', 'fr-ML', 'fr-SN'])
    .withMessage('Numéro de téléphone invalide'),
  body('profileType')
    .isIn(['CLIENT', 'PARTNER', 'COMMERCIAL'])
    .withMessage('Type de profil invalide'),
  body('country')
    .isLength({ min: 2, max: 2 })
    .withMessage('Code pays invalide (format ISO 3166-1 alpha-2)')
];

const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Email invalide'),
  body('password')
    .notEmpty()
    .withMessage('Mot de passe requis')
];

// ==============================================
// HELPER FUNCTIONS
// ==============================================

const generateTokens = (user) => {
  const payload = {
    id: user.id,
    email: user.email,
    ismailId: user.ismail_id,
    profileType: user.profile_type
  };

  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '24h'
  });

  const refreshToken = jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d'
  });

  return { accessToken, refreshToken };
};

const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: {
        message: 'Données invalides',
        code: 'VALIDATION_ERROR',
        details: errors.array()
      }
    });
  }
  next();
};

// ==============================================
// ROUTES
// ==============================================

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', registerValidation, handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password, firstName, lastName, phone, profileType, country } = req.body;

    // Check if user already exists
    const existingUser = await db.users.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Un utilisateur avec cet email existe déjà',
          code: 'USER_ALREADY_EXISTS'
        }
      });
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Generate ISMAIL ID
    const ismailId = generateIsmailId(country, profileType);

    // Create user
    const userData = {
      ismail_id: ismailId,
      email,
      password_hash: hashedPassword,
      first_name: firstName,
      last_name: lastName,
      phone,
      profile_type: profileType,
      country,
      status: 'PENDING_VERIFICATION',
      created_at: new Date().toISOString()
    };

    const newUser = await db.users.create(userData);

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(newUser);

    // Remove sensitive data
    const { password_hash, ...userResponse } = newUser;

    res.status(201).json({
      success: true,
      message: 'Utilisateur créé avec succès',
      data: {
        user: userResponse,
        tokens: {
          accessToken,
          refreshToken
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', loginValidation, handleValidationErrors, async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Find user by email
    const user = await db.users.findByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Email ou mot de passe incorrect',
          code: 'INVALID_CREDENTIALS'
        }
      });
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Email ou mot de passe incorrect',
          code: 'INVALID_CREDENTIALS'
        }
      });
    }

    // Check if user is active
    if (user.status === 'SUSPENDED') {
      return res.status(403).json({
        success: false,
        error: {
          message: 'Compte suspendu. Contactez le support.',
          code: 'ACCOUNT_SUSPENDED'
        }
      });
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user);

    // Update last login
    await db.users.update(user.id, {
      last_login_at: new Date().toISOString()
    });

    // Remove sensitive data
    const { password_hash, ...userResponse } = user;

    res.json({
      success: true,
      message: 'Connexion réussie',
      data: {
        user: userResponse,
        tokens: {
          accessToken,
          refreshToken
        }
      }
    });

  } catch (error) {
    next(error);
  }
});

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refresh access token
 * @access  Public
 */
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: {
          message: 'Refresh token requis',
          code: 'REFRESH_TOKEN_REQUIRED'
        }
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    
    // Find user
    const user = await db.users.findById(decoded.id);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Utilisateur non trouvé',
          code: 'USER_NOT_FOUND'
        }
      });
    }

    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(user);

    res.json({
      success: true,
      message: 'Token rafraîchi avec succès',
      data: {
        tokens: {
          accessToken,
          refreshToken: newRefreshToken
        }
      }
    });

  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: {
          message: 'Refresh token invalide ou expiré',
          code: 'INVALID_REFRESH_TOKEN'
        }
      });
    }
    next(error);
  }
});

/**
 * @route   GET /api/v1/auth/me
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/me', async (req, res, next) => {
  // This route will need authentication middleware
  // For now, return a placeholder
  res.json({
    success: true,
    message: 'Route protégée - middleware d\'authentification requis',
    data: null
  });
});

module.exports = router;
