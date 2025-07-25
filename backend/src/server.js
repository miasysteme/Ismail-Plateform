/**
 * ISMAIL Platform - Backend API Server
 * Node.js/Express server with Supabase integration
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

// Import routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const walletRoutes = require('./routes/wallets');
const transactionRoutes = require('./routes/transactions');

// Import middleware
const errorHandler = require('./middleware/errorHandler');
const notFound = require('./middleware/notFound');

// Import config
const { supabase } = require('./config/supabase');

const app = express();
const PORT = process.env.PORT || 8080;
const API_VERSION = process.env.API_VERSION || 'v1';

// ==============================================
// MIDDLEWARE CONFIGURATION
// ==============================================

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

// CORS configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: process.env.CORS_CREDENTIALS === 'true',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard.',
    code: 'RATE_LIMIT_EXCEEDED'
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression middleware
app.use(compression());

// Logging middleware
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined'));
}

// ==============================================
// HEALTH CHECK ENDPOINTS
// ==============================================

app.get('/health', async (req, res) => {
  try {
    // Test Supabase connection
    const { data, error } = await supabase
      .from('users')
      .select('count')
      .limit(1);

    if (error) throw error;

    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: API_VERSION,
      services: {
        database: 'connected',
        api: 'running'
      }
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

app.get('/', (req, res) => {
  res.json({
    message: 'ISMAIL Platform API',
    version: API_VERSION,
    status: 'running',
    timestamp: new Date().toISOString(),
    endpoints: {
      health: '/health',
      auth: `/api/${API_VERSION}/auth`,
      users: `/api/${API_VERSION}/users`,
      wallets: `/api/${API_VERSION}/wallets`,
      transactions: `/api/${API_VERSION}/transactions`
    }
  });
});

// ==============================================
// API ROUTES
// ==============================================

const apiRouter = express.Router();

// Mount route modules
apiRouter.use('/auth', authRoutes);
apiRouter.use('/users', userRoutes);
apiRouter.use('/wallets', walletRoutes);
apiRouter.use('/transactions', transactionRoutes);

// Mount API router
app.use(`/api/${API_VERSION}`, apiRouter);

// ==============================================
// ERROR HANDLING MIDDLEWARE
// ==============================================

app.use(notFound);
app.use(errorHandler);

// ==============================================
// SERVER STARTUP
// ==============================================

const server = app.listen(PORT, () => {
  console.log(`🚀 ISMAIL Platform API Server`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Server running on port ${PORT}`);
  console.log(`📡 API Version: ${API_VERSION}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API Base URL: http://localhost:${PORT}/api/${API_VERSION}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Process terminated');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Process terminated');
    process.exit(0);
  });
});

module.exports = app;