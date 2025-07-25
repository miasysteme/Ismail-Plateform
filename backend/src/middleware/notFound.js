/**
 * 404 Not Found Middleware for ISMAIL Platform
 */

const notFound = (req, res, next) => {
  const error = new Error(`Route non trouvée - ${req.originalUrl}`);
  error.statusCode = 404;
  
  res.status(404).json({
    success: false,
    error: {
      message: `Route non trouvée - ${req.originalUrl}`,
      code: 'ROUTE_NOT_FOUND'
    },
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    method: req.method,
    availableEndpoints: {
      health: '/health',
      auth: '/api/v1/auth',
      users: '/api/v1/users',
      wallets: '/api/v1/wallets',
      transactions: '/api/v1/transactions'
    }
  });
};

module.exports = notFound;
