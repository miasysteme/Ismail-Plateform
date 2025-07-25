/**
 * Supabase Configuration for ISMAIL Platform
 */

const { createClient } = require('@supabase/supabase-js');

// Validate required environment variables
const requiredEnvVars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
  throw new Error(`Missing required environment variables: ${missingEnvVars.join(', ')}`);
}

// Supabase configuration
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

// Create Supabase client for general use (with RLS)
const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: false, // Server-side, no session persistence needed
  },
  db: {
    schema: 'ismail', // Use our custom schema
  },
});

// Create Supabase admin client (bypasses RLS)
const supabaseAdmin = supabaseServiceKey 
  ? createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
      db: {
        schema: 'ismail',
      },
    })
  : null;

// Database helper functions
const db = {
  // Users table operations
  users: {
    async findById(id) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) throw error;
      return data;
    },

    async findByEmail(email) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .single();
      
      if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned
      return data;
    },

    async findByIsmailId(ismailId) {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('ismail_id', ismailId)
        .single();
      
      if (error && error.code !== 'PGRST116') throw error;
      return data;
    },

    async create(userData) {
      const { data, error } = await supabase
        .from('users')
        .insert(userData)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async update(id, updates) {
      const { data, error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    }
  },

  // Wallets table operations
  wallets: {
    async findByUserId(userId) {
      const { data, error } = await supabase
        .from('wallets')
        .select('*')
        .eq('user_id', userId);
      
      if (error) throw error;
      return data;
    },

    async findByUserIdAndCurrency(userId, currency) {
      const { data, error } = await supabase
        .from('wallets')
        .select('*')
        .eq('user_id', userId)
        .eq('currency', currency)
        .single();
      
      if (error && error.code !== 'PGRST116') throw error;
      return data;
    },

    async updateBalance(walletId, newBalance) {
      const { data, error } = await supabase
        .from('wallets')
        .update({ 
          balance: newBalance,
          updated_at: new Date().toISOString()
        })
        .eq('id', walletId)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    }
  },

  // Transactions table operations
  transactions: {
    async create(transactionData) {
      const { data, error } = await supabase
        .from('transactions')
        .insert(transactionData)
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },

    async findByUserId(userId, limit = 50, offset = 0) {
      const { data, error } = await supabase
        .from('transactions_with_user')
        .select('*')
        .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);
      
      if (error) throw error;
      return data;
    },

    async findById(id) {
      const { data, error } = await supabase
        .from('transactions')
        .select('*')
        .eq('id', id)
        .single();
      
      if (error) throw error;
      return data;
    }
  }
};

// Test database connection
async function testConnection() {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('count')
      .limit(1);
    
    if (error) throw error;
    
    console.log('✅ Supabase connection successful');
    return true;
  } catch (error) {
    console.error('❌ Supabase connection failed:', error.message);
    return false;
  }
}

module.exports = {
  supabase,
  supabaseAdmin,
  db,
  testConnection
};
