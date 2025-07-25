/**
 * Global Error Handler Middleware for ISMAIL Platform
 */

const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  console.error('Error:', err);

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Ressource non trouvée';
    error = { message, statusCode: 404 };
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const message = 'Ressource déjà existante';
    error = { message, statusCode: 400 };
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message).join(', ');
    error = { message, statusCode: 400 };
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Token invalide';
    error = { message, statusCode: 401 };
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expiré';
    error = { message, statusCode: 401 };
  }

  // Supabase errors
  if (err.code === 'PGRST301') {
    const message = 'Accès non autorisé';
    error = { message, statusCode: 401 };
  }

  if (err.code === 'PGRST116') {
    const message = 'Ressource non trouvée';
    error = { message, statusCode: 404 };
  }

  // Rate limit errors
  if (err.type === 'entity.too.large') {
    const message = 'Fichier trop volumineux';
    error = { message, statusCode: 413 };
  }

  // Default error response
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Erreur interne du serveur';

  // Error response format
  const errorResponse = {
    success: false,
    error: {
      message,
      code: err.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && {
        stack: err.stack,
        details: err
      })
    },
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    method: req.method
  };

  res.status(statusCode).json(errorResponse);
};

module.exports = errorHandler;
