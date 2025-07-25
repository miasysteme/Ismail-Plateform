#!/usr/bin/env node

/**
 * Script de diagnostic pour le build Netlify
 * Vérifie la présence et la configuration des fichiers nécessaires
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 ISMAIL Platform - Diagnostic de Build');
console.log('==========================================\n');

// Vérification des fichiers essentiels
const essentialFiles = [
  'index.html',
  'package.json',
  'vite.config.js',
  'src/main.jsx',
  'src/App.jsx'
];

console.log('📁 Vérification des fichiers essentiels:');
essentialFiles.forEach(file => {
  const filePath = path.resolve(__dirname, file);
  const exists = fs.existsSync(filePath);
  console.log(`  ${exists ? '✅' : '❌'} ${file}`);

  if (!exists) {
    console.log(`     ⚠️  Fichier manquant: ${filePath}`);
  }
});

console.log('\n📋 Configuration Vite:');
try {
  const viteConfigPath = path.resolve(__dirname, 'vite.config.js');
  if (fs.existsSync(viteConfigPath)) {
    const viteConfig = fs.readFileSync(viteConfigPath, 'utf8');
    console.log('  ✅ vite.config.js trouvé');

    // Vérifier la configuration d'entrée
    if (viteConfig.includes('input:')) {
      console.log('  ✅ Configuration d\'entrée trouvée');
    } else {
      console.log('  ⚠️  Configuration d\'entrée manquante');
    }
  }
} catch (error) {
  console.log(`  ❌ Erreur lors de la lecture de vite.config.js: ${error.message}`);
}

console.log('\n📦 Package.json:');
try {
  const packagePath = path.resolve(__dirname, 'package.json');
  const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
  
  console.log(`  ✅ Nom: ${packageJson.name}`);
  console.log(`  ✅ Version: ${packageJson.version}`);
  console.log(`  ✅ Type: ${packageJson.type || 'commonjs'}`);
  
  if (packageJson.scripts && packageJson.scripts.build) {
    console.log(`  ✅ Script build: ${packageJson.scripts.build}`);
  } else {
    console.log('  ❌ Script build manquant');
  }
} catch (error) {
  console.log(`  ❌ Erreur lors de la lecture de package.json: ${error.message}`);
}

console.log('\n🌐 Variables d\'environnement:');
console.log(`  NODE_ENV: ${process.env.NODE_ENV || 'non défini'}`);
console.log(`  NODE_VERSION: ${process.version}`);
console.log(`  PWD: ${process.cwd()}`);

console.log('\n✅ Diagnostic terminé');
