/**
 * ISMAIL ID Generator Utility
 * Generates unique IDs in format: CCYYMMDD-XXXX-UL
 */

const crypto = require('crypto');

/**
 * Generate a unique ISMAIL ID
 * @param {string} country - Country code (ISO 3166-1 alpha-2)
 * @param {string} profileType - User profile type
 * @returns {string} Generated ISMAIL ID
 */
function generateIsmailId(country = 'CI', profileType = 'CLIENT') {
  // Validate inputs
  if (!country || country.length !== 2) {
    throw new Error('Country code must be 2 characters (ISO 3166-1 alpha-2)');
  }

  const validProfileTypes = ['CLIENT', 'PARTNER', 'COMMERCIAL', 'ADMIN'];
  if (!validProfileTypes.includes(profileType)) {
    throw new Error(`Profile type must be one of: ${validProfileTypes.join(', ')}`);
  }

  // Country code (uppercase)
  const countryCode = country.toUpperCase();

  // Date part (YYMMDD)
  const now = new Date();
  const year = now.getFullYear().toString().slice(-2);
  const month = (now.getMonth() + 1).toString().padStart(2, '0');
  const day = now.getDate().toString().padStart(2, '0');
  const datePart = `${year}${month}${day}`;

  // Random part (4 characters alphanumeric)
  const randomPart = crypto.randomBytes(2).toString('hex').toUpperCase();

  // User type suffix
  const suffixMap = {
    'CLIENT': 'CL',
    'PARTNER': 'PT',
    'COMMERCIAL': 'CM',
    'ADMIN': 'AD'
  };
  const userSuffix = suffixMap[profileType];

  // Combine all parts
  const ismailId = `${countryCode}${datePart}-${randomPart}-${userSuffix}`;

  return ismailId;
}

/**
 * Validate ISMAIL ID format
 * @param {string} ismailId - ISMAIL ID to validate
 * @returns {boolean} True if valid format
 */
function validateIsmailId(ismailId) {
  if (!ismailId || typeof ismailId !== 'string') {
    return false;
  }

  // Regex pattern: CC + YYMMDD + - + XXXX + - + UL
  const pattern = /^[A-Z]{2}\d{6}-[A-F0-9]{4}-(CL|PT|CM|AD)$/;
  return pattern.test(ismailId);
}

/**
 * Parse ISMAIL ID to extract components
 * @param {string} ismailId - ISMAIL ID to parse
 * @returns {object} Parsed components or null if invalid
 */
function parseIsmailId(ismailId) {
  if (!validateIsmailId(ismailId)) {
    return null;
  }

  const parts = ismailId.split('-');
  const countryAndDate = parts[0];
  const randomPart = parts[1];
  const userType = parts[2];

  const country = countryAndDate.slice(0, 2);
  const dateStr = countryAndDate.slice(2);
  
  // Parse date
  const year = 2000 + parseInt(dateStr.slice(0, 2));
  const month = parseInt(dateStr.slice(2, 4));
  const day = parseInt(dateStr.slice(4, 6));

  // Map user type
  const typeMap = {
    'CL': 'CLIENT',
    'PT': 'PARTNER',
    'CM': 'COMMERCIAL',
    'AD': 'ADMIN'
  };

  return {
    country,
    creationDate: new Date(year, month - 1, day),
    randomPart,
    profileType: typeMap[userType],
    userTypeSuffix: userType
  };
}

/**
 * Generate a batch of unique ISMAIL IDs
 * @param {number} count - Number of IDs to generate
 * @param {string} country - Country code
 * @param {string} profileType - Profile type
 * @returns {string[]} Array of unique ISMAIL IDs
 */
function generateBatchIsmailIds(count, country = 'CI', profileType = 'CLIENT') {
  const ids = new Set();
  
  while (ids.size < count) {
    const id = generateIsmailId(country, profileType);
    ids.add(id);
  }
  
  return Array.from(ids);
}

/**
 * Check if ISMAIL ID belongs to a specific profile type
 * @param {string} ismailId - ISMAIL ID to check
 * @param {string} profileType - Profile type to check against
 * @returns {boolean} True if matches profile type
 */
function isProfileType(ismailId, profileType) {
  const parsed = parseIsmailId(ismailId);
  return parsed && parsed.profileType === profileType;
}

/**
 * Get country from ISMAIL ID
 * @param {string} ismailId - ISMAIL ID
 * @returns {string|null} Country code or null if invalid
 */
function getCountryFromId(ismailId) {
  const parsed = parseIsmailId(ismailId);
  return parsed ? parsed.country : null;
}

module.exports = {
  generateIsmailId,
  validateIsmailId,
  parseIsmailId,
  generateBatchIsmailIds,
  isProfileType,
  getCountryFromId
};
