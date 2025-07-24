-- Plugin Kong personnalisé pour l'authentification ISMAIL
-- Gère la validation des tokens JWT et l'extraction des informations utilisateur

local jwt_decoder = require "resty.jwt"
local cjson = require "cjson"

local ISMAILAuthHandler = {}

ISMAILAuthHandler.PRIORITY = 1000
ISMAILAuthHandler.VERSION = "1.0.0"

-- Configuration du plugin
local plugin_config_schema = {
  type = "record",
  fields = {
    {
      jwt_secret = {
        type = "string",
        required = true,
        description = "Secret JWT pour la validation des tokens"
      }
    },
    {
      jwt_algorithm = {
        type = "string",
        default = "HS256",
        description = "Algorithme de signature JWT"
      }
    },
    {
      header_names = {
        type = "array",
        elements = { type = "string" },
        default = { "authorization", "x-auth-token" },
        description = "Noms des headers contenant le token JWT"
      }
    },
    {
      cookie_names = {
        type = "array",
        elements = { type = "string" },
        default = { "jwt", "auth_token" },
        description = "Noms des cookies contenant le token JWT"
      }
    },
    {
      uri_param_names = {
        type = "array",
        elements = { type = "string" },
        default = { "jwt", "token" },
        description = "Noms des paramètres URI contenant le token JWT"
      }
    },
    {
      claims_to_verify = {
        type = "array",
        elements = { type = "string" },
        default = { "exp", "iat", "iss" },
        description = "Claims JWT à vérifier"
      }
    },
    {
      issuer = {
        type = "string",
        default = "ismail-platform",
        description = "Émetteur attendu du token JWT"
      }
    },
    {
      audience = {
        type = "string",
        default = "ismail-api",
        description = "Audience attendue du token JWT"
      }
    },
    {
      leeway = {
        type = "number",
        default = 0,
        description = "Tolérance en secondes pour la validation des timestamps"
      }
    },
    {
      anonymous = {
        type = "string",
        description = "ID du consumer anonyme à utiliser si l'authentification échoue"
      }
    },
    {
      run_on_preflight = {
        type = "boolean",
        default = true,
        description = "Exécuter le plugin sur les requêtes OPTIONS"
      }
    }
  }
}

-- Fonction pour extraire le token JWT de la requête
local function extract_token(conf)
  local token = nil
  local request = kong.request
  
  -- Chercher dans les headers
  for _, header_name in ipairs(conf.header_names) do
    local header_value = request.get_header(header_name)
    if header_value then
      if header_name:lower() == "authorization" then
        -- Extraire le token du header Authorization (Bearer <token>)
        local bearer_token = header_value:match("Bearer%s+(.+)")
        if bearer_token then
          token = bearer_token
          break
        end
      else
        token = header_value
        break
      end
    end
  end
  
  -- Chercher dans les cookies si pas trouvé dans les headers
  if not token then
    for _, cookie_name in ipairs(conf.cookie_names) do
      local cookie_value = request.get_cookie(cookie_name)
      if cookie_value then
        token = cookie_value
        break
      end
    end
  end
  
  -- Chercher dans les paramètres URI si pas trouvé
  if not token then
    for _, param_name in ipairs(conf.uri_param_names) do
      local param_value = request.get_query_arg(param_name)
      if param_value then
        token = param_value
        break
      end
    end
  end
  
  return token
end

-- Fonction pour valider le token JWT
local function validate_jwt_token(token, conf)
  if not token then
    return false, "Token JWT manquant"
  end
  
  -- Décoder le token JWT
  local jwt_obj = jwt_decoder:verify(conf.jwt_secret, token, {
    alg = conf.jwt_algorithm
  })
  
  if not jwt_obj.valid then
    return false, "Token JWT invalide: " .. (jwt_obj.reason or "raison inconnue")
  end
  
  local claims = jwt_obj.payload
  
  -- Vérifier les claims obligatoires
  for _, claim in ipairs(conf.claims_to_verify) do
    if claim == "exp" then
      -- Vérifier l'expiration
      if not claims.exp or claims.exp <= ngx.time() - conf.leeway then
        return false, "Token JWT expiré"
      end
    elseif claim == "iat" then
      -- Vérifier la date d'émission
      if not claims.iat or claims.iat > ngx.time() + conf.leeway then
        return false, "Token JWT émis dans le futur"
      end
    elseif claim == "iss" then
      -- Vérifier l'émetteur
      if not claims.iss or claims.iss ~= conf.issuer then
        return false, "Émetteur JWT invalide"
      end
    elseif claim == "aud" then
      -- Vérifier l'audience
      if not claims.aud or claims.aud ~= conf.audience then
        return false, "Audience JWT invalide"
      end
    end
  end
  
  return true, claims
end

-- Fonction pour définir les headers utilisateur
local function set_user_headers(claims)
  if claims.user_id then
    kong.service.request.set_header("X-User-ID", claims.user_id)
  end
  
  if claims.ismail_id then
    kong.service.request.set_header("X-ISMAIL-ID", claims.ismail_id)
  end
  
  if claims.profile_type then
    kong.service.request.set_header("X-User-Type", claims.profile_type)
  end
  
  if claims.email then
    kong.service.request.set_header("X-User-Email", claims.email)
  end
  
  if claims.permissions then
    kong.service.request.set_header("X-User-Permissions", cjson.encode(claims.permissions))
  end
  
  if claims.session_id then
    kong.service.request.set_header("X-Session-ID", claims.session_id)
  end
  
  -- Ajouter le timestamp de validation
  kong.service.request.set_header("X-Auth-Validated-At", tostring(ngx.time()))
end

-- Fonction pour gérer l'authentification anonyme
local function handle_anonymous_access(conf)
  if conf.anonymous then
    -- Définir le consumer anonyme
    kong.client.authenticate(nil, conf.anonymous)
    
    -- Définir des headers par défaut pour l'accès anonyme
    kong.service.request.set_header("X-User-ID", "anonymous")
    kong.service.request.set_header("X-User-Type", "ANONYMOUS")
    kong.service.request.set_header("X-Auth-Validated-At", tostring(ngx.time()))
    
    return true
  end
  
  return false
end

-- Fonction principale d'accès
function ISMAILAuthHandler:access(conf)
  -- Ignorer les requêtes OPTIONS si configuré
  if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
    return
  end
  
  -- Extraire le token JWT
  local token = extract_token(conf)
  
  if not token then
    -- Essayer l'accès anonyme
    if handle_anonymous_access(conf) then
      return
    end
    
    return kong.response.exit(401, {
      error = "unauthorized",
      message = "Token d'authentification requis"
    })
  end
  
  -- Valider le token JWT
  local valid, claims_or_error = validate_jwt_token(token, conf)
  
  if not valid then
    -- Essayer l'accès anonyme en cas d'échec
    if handle_anonymous_access(conf) then
      return
    end
    
    return kong.response.exit(401, {
      error = "unauthorized",
      message = claims_or_error
    })
  end
  
  -- Token valide, définir les headers utilisateur
  set_user_headers(claims_or_error)
  
  -- Authentifier l'utilisateur avec Kong
  local consumer_id = claims_or_error.user_id or claims_or_error.sub
  if consumer_id then
    kong.client.authenticate(consumer_id, nil)
  end
  
  -- Ajouter les informations utilisateur au contexte Kong
  kong.ctx.shared.authenticated_user = claims_or_error
  kong.ctx.shared.auth_method = "jwt"
end

-- Fonction pour ajouter des headers de réponse
function ISMAILAuthHandler:header_filter(conf)
  local user_info = kong.ctx.shared.authenticated_user
  
  if user_info then
    -- Ajouter des headers de réponse pour le debugging (en développement)
    if conf.environment ~= "prod" then
      kong.response.set_header("X-Debug-User-ID", user_info.user_id or "unknown")
      kong.response.set_header("X-Debug-Auth-Method", kong.ctx.shared.auth_method or "unknown")
    end
    
    -- Ajouter des headers de sécurité
    kong.response.set_header("X-Content-Type-Options", "nosniff")
    kong.response.set_header("X-Frame-Options", "DENY")
    kong.response.set_header("X-XSS-Protection", "1; mode=block")
  end
end

-- Fonction pour logger les événements d'authentification
function ISMAILAuthHandler:log(conf)
  local user_info = kong.ctx.shared.authenticated_user
  local request_info = {
    method = kong.request.get_method(),
    path = kong.request.get_path(),
    ip = kong.client.get_ip(),
    user_agent = kong.request.get_header("user-agent"),
    timestamp = ngx.time()
  }
  
  if user_info then
    -- Logger l'authentification réussie
    kong.log.info("ISMAIL Auth Success: ", cjson.encode({
      user_id = user_info.user_id,
      ismail_id = user_info.ismail_id,
      profile_type = user_info.profile_type,
      request = request_info
    }))
  else
    -- Logger l'échec d'authentification
    kong.log.warn("ISMAIL Auth Failed: ", cjson.encode({
      reason = "token_missing_or_invalid",
      request = request_info
    }))
  end
end

-- Schéma de configuration du plugin
ISMAILAuthHandler.schema = plugin_config_schema

return ISMAILAuthHandler
