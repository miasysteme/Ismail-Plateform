# ISMAIL Platform - Script de Déploiement PowerShell
# Ce script prépare et déploie la plateforme ISMAIL sur Windows

param(
    [switch]$SkipTests,
    [switch]$SkipPush,
    [switch]$Force
)

# Fonction pour afficher les messages colorés
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Log-Info($message) {
    Write-ColorOutput Blue "[INFO] $message"
}

function Log-Success($message) {
    Write-ColorOutput Green "[SUCCESS] $message"
}

function Log-Warning($message) {
    Write-ColorOutput Yellow "[WARNING] $message"
}

function Log-Error($message) {
    Write-ColorOutput Red "[ERROR] $message"
}

# Vérification des prérequis
function Test-Prerequisites {
    Log-Info "Vérification des prérequis..."
    
    # Vérifier Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Log-Error "Git n'est pas installé ou pas dans le PATH"
        exit 1
    }
    
    # Vérifier Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Log-Error "Node.js n'est pas installé ou pas dans le PATH"
        exit 1
    }
    
    # Vérifier npm
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Log-Error "npm n'est pas installé ou pas dans le PATH"
        exit 1
    }
    
    # Vérifier les versions
    $nodeVersion = node --version
    $npmVersion = npm --version
    Log-Info "Node.js version: $nodeVersion"
    Log-Info "npm version: $npmVersion"
    
    Log-Success "Tous les prérequis sont satisfaits"
}

# Installation des dépendances
function Install-Dependencies {
    Log-Info "Installation des dépendances..."
    
    try {
        # Dépendances racine
        Log-Info "Installation des dépendances racine..."
        npm install
        
        # Dépendances backend
        Log-Info "Installation des dépendances backend..."
        Set-Location backend
        npm install
        Set-Location ..
        
        # Dépendances frontend
        Log-Info "Installation des dépendances frontend..."
        Set-Location frontend
        npm install
        Set-Location ..
        
        Log-Success "Toutes les dépendances sont installées"
    }
    catch {
        Log-Error "Erreur lors de l'installation des dépendances: $_"
        exit 1
    }
}

# Construction des projets
function Build-Projects {
    Log-Info "Construction des projets..."
    
    try {
        # Build backend
        Log-Info "Construction du backend..."
        Set-Location backend
        if (Test-Path "package.json") {
            $packageJson = Get-Content "package.json" | ConvertFrom-Json
            if ($packageJson.scripts.build) {
                npm run build
            } else {
                Log-Warning "Script de build non trouvé pour le backend"
            }
        }
        Set-Location ..
        
        # Build frontend
        Log-Info "Construction du frontend..."
        Set-Location frontend
        if (Test-Path "package.json") {
            $packageJson = Get-Content "package.json" | ConvertFrom-Json
            if ($packageJson.scripts.build) {
                npm run build
            } else {
                Log-Warning "Script de build non trouvé pour le frontend"
            }
        }
        Set-Location ..
        
        Log-Success "Construction terminée avec succès"
    }
    catch {
        Log-Error "Erreur lors de la construction: $_"
        exit 1
    }
}

# Exécution des tests
function Invoke-Tests {
    if ($SkipTests) {
        Log-Warning "Tests ignorés (paramètre -SkipTests)"
        return
    }
    
    Log-Info "Exécution des tests..."
    
    try {
        # Tests backend
        Set-Location backend
        if (Test-Path "package.json") {
            $packageJson = Get-Content "package.json" | ConvertFrom-Json
            if ($packageJson.scripts.test) {
                Log-Info "Tests backend..."
                npm test
            }
        }
        Set-Location ..
        
        # Tests frontend
        Set-Location frontend
        if (Test-Path "package.json") {
            $packageJson = Get-Content "package.json" | ConvertFrom-Json
            if ($packageJson.scripts.test) {
                Log-Info "Tests frontend..."
                npm test
            }
        }
        Set-Location ..
        
        Log-Success "Tous les tests sont passés"
    }
    catch {
        Log-Error "Erreur lors des tests: $_"
        if (-not $Force) {
            exit 1
        }
    }
}

# Préparation Git
function Prepare-Git {
    Log-Info "Préparation pour Git..."
    
    try {
        # Vérifier si on est dans un repo Git
        if (-not (Test-Path ".git")) {
            Log-Warning "Initialisation du repository Git..."
            git init
            git remote add origin https://github.com/miasysteme/Ismail-Plateform.git
        }
        
        # Vérifier le statut Git
        $gitStatus = git status --porcelain
        if ($gitStatus) {
            Log-Info "Fichiers modifiés détectés, ajout au staging..."
            git add .
            
            # Commit avec message automatique
            $commitMessage = "feat: deploy ISMAIL Platform v1.0.0 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            git commit -m $commitMessage
        } else {
            Log-Warning "Aucun changement à commiter"
        }
        
        Log-Success "Repository Git préparé"
    }
    catch {
        Log-Error "Erreur lors de la préparation Git: $_"
        exit 1
    }
}

# Push vers GitHub
function Push-ToGitHub {
    if ($SkipPush) {
        Log-Warning "Push ignoré (paramètre -SkipPush)"
        return
    }
    
    Log-Info "Push vers GitHub..."
    
    try {
        # Vérifier la branche actuelle
        $currentBranch = git branch --show-current
        Log-Info "Branche actuelle: $currentBranch"
        
        # Push vers GitHub
        git push -u origin $currentBranch
        
        Log-Success "Code poussé vers GitHub avec succès"
    }
    catch {
        Log-Error "Erreur lors du push: $_"
        exit 1
    }
}

# Vérification du déploiement Render
function Test-RenderDeployment {
    Log-Info "Vérification du déploiement Render..."
    
    # Attendre quelques secondes
    Start-Sleep -Seconds 10
    
    $renderUrl = "https://ismail-plateform.onrender.com"
    
    try {
        Log-Info "Test de connectivité vers $renderUrl..."
        $response = Invoke-WebRequest -Uri "$renderUrl/health" -TimeoutSec 30 -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Log-Success "Déploiement Render réussi! Application accessible sur $renderUrl"
        }
    }
    catch {
        Log-Warning "Le déploiement Render est en cours... Cela peut prendre quelques minutes."
        Log-Info "Vérifiez le statut sur: https://dashboard.render.com"
    }
}

# Fonction principale
function Main {
    Write-Host "🚀 ISMAIL Platform - Script de Déploiement PowerShell" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-Prerequisites
    Install-Dependencies
    Build-Projects
    
    if (-not $SkipTests) {
        $runTests = Read-Host "Voulez-vous exécuter les tests? (y/N)"
        if ($runTests -eq 'y' -or $runTests -eq 'Y') {
            Invoke-Tests
        }
    }
    
    Prepare-Git
    
    if (-not $SkipPush) {
        $pushToGit = Read-Host "Voulez-vous pousser vers GitHub? (y/N)"
        if ($pushToGit -eq 'y' -or $pushToGit -eq 'Y') {
            Push-ToGitHub
            Test-RenderDeployment
        } else {
            Log-Info "Push annulé. Vous pouvez pousser manuellement avec: git push"
        }
    }
    
    Write-Host ""
    Log-Success "🎉 Déploiement terminé!"
    Write-Host "📊 Dashboard Render: https://dashboard.render.com" -ForegroundColor Yellow
    Write-Host "🌐 Application: https://ismail-plateform.onrender.com" -ForegroundColor Yellow
    Write-Host "📚 Repository: https://github.com/miasysteme/Ismail-Plateform" -ForegroundColor Yellow
}

# Exécuter le script principal
Main
