#!/usr/bin/env node

/**
 * Script de test pour simuler le build Netlify
 * Simule exactement l'environnement Netlify
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🧪 ISMAIL Platform - Test Simulation Netlify');
console.log('=============================================\n');

// Simulation de l'environnement Netlify
const netlifyEnv = {
  NODE_VERSION: '20',
  BUILD_BASE: path.resolve(__dirname, 'frontend'),
  PUBLISH_DIR: 'dist'
};

console.log('🌐 Environnement simulé Netlify:');
console.log(`  Base directory: ${netlifyEnv.BUILD_BASE}`);
console.log(`  Publish directory: ${netlifyEnv.PUBLISH_DIR}`);
console.log(`  Node version: ${netlifyEnv.NODE_VERSION}`);

// Vérifier que nous sommes dans le bon répertoire
console.log('\n📁 Vérification de la structure:');
const frontendDir = path.join(__dirname, 'frontend');
const indexHtml = path.join(frontendDir, 'index.html');
const packageJson = path.join(frontendDir, 'package.json');
const viteConfig = path.join(frontendDir, 'vite.config.js');

console.log(`  ✅ Frontend directory: ${fs.existsSync(frontendDir)}`);
console.log(`  ✅ index.html: ${fs.existsSync(indexHtml)}`);
console.log(`  ✅ package.json: ${fs.existsSync(packageJson)}`);
console.log(`  ✅ vite.config.js: ${fs.existsSync(viteConfig)}`);

// Simulation du build Netlify
console.log('\n🔨 Simulation du build Netlify:');
try {
  // Changer vers le répertoire frontend (comme Netlify avec base = "frontend")
  process.chdir(frontendDir);
  console.log(`  📂 Changed to: ${process.cwd()}`);
  
  // Vérifier que index.html est accessible depuis le répertoire de travail
  const indexFromCwd = path.resolve('./index.html');
  console.log(`  📄 index.html path: ${indexFromCwd}`);
  console.log(`  ✅ index.html accessible: ${fs.existsSync(indexFromCwd)}`);
  
  // Simuler npm run build
  console.log('\n  🚀 Exécution de npm run build...');
  const buildOutput = execSync('npm run build', { encoding: 'utf8' });
  console.log('  ✅ Build réussi !');
  
  // Vérifier le répertoire de sortie
  const distDir = path.resolve('./dist');
  const distIndex = path.join(distDir, 'index.html');
  console.log(`\n  📦 Vérification du répertoire dist:`);
  console.log(`    📂 dist directory: ${fs.existsSync(distDir)}`);
  console.log(`    📄 dist/index.html: ${fs.existsSync(distIndex)}`);
  
  if (fs.existsSync(distDir)) {
    const distFiles = fs.readdirSync(distDir);
    console.log(`    📋 Fichiers générés: ${distFiles.join(', ')}`);
  }
  
  console.log('\n✅ Test de simulation Netlify RÉUSSI !');
  console.log('🎉 Le déploiement devrait maintenant fonctionner sur Netlify.');
  
} catch (error) {
  console.error('\n❌ Erreur lors du test de simulation:');
  console.error(error.message);
  process.exit(1);
}
