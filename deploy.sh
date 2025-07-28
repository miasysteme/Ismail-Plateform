#!/bin/bash

# ISMAIL Platform - Script de Déploiement Automatisé
# Ce script prépare et déploie la plateforme ISMAIL

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier Git
    if ! command -v git &> /dev/null; then
        log_error "Git n'est pas installé"
        exit 1
    fi
    
    # Vérifier Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js n'est pas installé"
        exit 1
    fi
    
    # Vérifier npm
    if ! command -v npm &> /dev/null; then
        log_error "npm n'est pas installé"
        exit 1
    fi
    
    log_success "Tous les prérequis sont satisfaits"
}

# Installation des dépendances
install_dependencies() {
    log_info "Installation des dépendances..."
    
    # Dépendances racine
    npm install
    
    # Dépendances backend
    log_info "Installation des dépendances backend..."
    cd backend && npm install && cd ..
    
    # Dépendances frontend
    log_info "Installation des dépendances frontend..."
    cd frontend && npm install && cd ..
    
    log_success "Toutes les dépendances sont installées"
}

# Construction des projets
build_projects() {
    log_info "Construction des projets..."
    
    # Build backend
    log_info "Construction du backend..."
    cd backend && npm run build && cd ..
    
    # Build frontend
    log_info "Construction du frontend..."
    cd frontend && npm run build && cd ..
    
    log_success "Construction terminée avec succès"
}

# Tests
run_tests() {
    log_info "Exécution des tests..."
    
    # Tests backend
    if [ -f "backend/package.json" ] && grep -q "test" backend/package.json; then
        log_info "Tests backend..."
        cd backend && npm test && cd ..
    fi
    
    # Tests frontend
    if [ -f "frontend/package.json" ] && grep -q "test" frontend/package.json; then
        log_info "Tests frontend..."
        cd frontend && npm test && cd ..
    fi
    
    log_success "Tous les tests sont passés"
}

# Préparation pour Git
prepare_git() {
    log_info "Préparation pour Git..."
    
    # Vérifier si on est dans un repo Git
    if [ ! -d ".git" ]; then
        log_warning "Initialisation du repository Git..."
        git init
        git remote add origin https://github.com/miasysteme/Ismail-Plateform.git
    fi
    
    # Ajouter tous les fichiers
    git add .
    
    # Commit avec message automatique
    COMMIT_MESSAGE="feat: deploy ISMAIL Platform v1.0.0 - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MESSAGE" || log_warning "Aucun changement à commiter"
    
    log_success "Repository Git préparé"
}

# Push vers GitHub
push_to_github() {
    log_info "Push vers GitHub..."
    
    # Vérifier la branche actuelle
    CURRENT_BRANCH=$(git branch --show-current)
    log_info "Branche actuelle: $CURRENT_BRANCH"
    
    # Push vers GitHub
    git push -u origin $CURRENT_BRANCH
    
    log_success "Code poussé vers GitHub avec succès"
}

# Vérification du déploiement Render
check_render_deployment() {
    log_info "Vérification du déploiement Render..."
    
    # Attendre quelques secondes pour que Render commence le déploiement
    sleep 10
    
    # Tester l'endpoint
    RENDER_URL="https://ismail-plateform.onrender.com"
    
    log_info "Test de connectivité vers $RENDER_URL..."
    
    if curl -f -s "$RENDER_URL/health" > /dev/null 2>&1; then
        log_success "Déploiement Render réussi! Application accessible sur $RENDER_URL"
    else
        log_warning "Le déploiement Render est en cours... Cela peut prendre quelques minutes."
        log_info "Vérifiez le statut sur: https://dashboard.render.com"
    fi
}

# Fonction principale
main() {
    echo "🚀 ISMAIL Platform - Script de Déploiement"
    echo "=========================================="
    
    check_prerequisites
    install_dependencies
    build_projects
    
    # Demander si on veut exécuter les tests
    read -p "Voulez-vous exécuter les tests? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_tests
    fi
    
    prepare_git
    
    # Demander confirmation pour le push
    read -p "Voulez-vous pousser vers GitHub? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        push_to_github
        check_render_deployment
    else
        log_info "Push annulé. Vous pouvez pousser manuellement avec: git push"
    fi
    
    echo
    log_success "🎉 Déploiement terminé!"
    echo "📊 Dashboard Render: https://dashboard.render.com"
    echo "🌐 Application: https://ismail-plateform.onrender.com"
    echo "📚 Repository: https://github.com/miasysteme/Ismail-Plateform"
}

# Exécuter le script principal
main "$@"
