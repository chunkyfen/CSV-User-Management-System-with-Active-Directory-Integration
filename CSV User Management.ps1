# ============================================================================
# EXERCISE 3: CSV USER MANAGEMENT SYSTEM WITH ACTIVE DIRECTORY INTEGRATION
# ============================================================================
# Domain: script.local
# This script manages user accounts through a CSV file and can export them
# to Active Directory. It provides a menu-driven interface for all operations.
# ============================================================================

# Import Active Directory module for AD operations
Import-Module ActiveDirectory

# Define the CSV file path - this will be in the same directory as the script
$csvPath = "C:\Users\Administrator\Downloads\utilisateurs.csv"

# Define the Active Directory domain
$domain = "script.local"

# ============================================================================
# FUNCTION: Initialize-CSVFile
# Purpose: Create the CSV file with sample data if it doesn't exist
# ============================================================================
function Initialize-CSVFile {
    # Check if the CSV file already exists
    if (-not (Test-Path $csvPath)) {
        Write-Host "Creating utilisateurs.csv file..." -ForegroundColor Yellow
        
        # Create an array of user objects with sample data
        $users = @(
            [PSCustomObject]@{
                Nom = "Pierre"
                Prénom = "André"
                Poste = "TTP"
                UserName = "pAndre"
                Password = "pA12345!"
                Statut = "Actif"
                DateDernierLogin = "2024-08-24 9:00:00"
            },
            [PSCustomObject]@{
                Nom = "Nicholas"
                Prénom = "Judith"
                Poste = "Secrétaire"
                Poste = "nJudith"
                Password = "nJ12345!"
                Statut = "Verrouillé"
                DateDernierLogin = "2024-08-24 9:00:00"
            },
            [PSCustomObject]@{
                Nom = "Tremblay"
                Prénom = "Antoine"
                Poste = "admin"
                UserName = "tAntoine"
                Password = "tA12345!"
                Statut = "Actif"
                DateDernierLogin = "2024-08-24 9:00:00"
            },
            [PSCustomObject]@{
                Nom = "Joseph"
                Prénom = "Mariah"
                Poste = "TTP"
                UserName = "jMariah"
                Password = "jM12345!"
                Statut = "Inactif"
                DateDernierLogin = "2024-08-24 9:00:00"
            },
            [PSCustomObject]@{
                Nom = "Lafrancois"
                Prénom = "Etienne"
                Poste = "Secrétaire"
                UserName = "lEtienne"
                Password = "lE12345!"
                Statut = "Actif"
                DateDernierLogin = "2024-08-24 9:00:00"
            }
        )
        
        # Export the users to CSV with semicolon delimiter as specified
        $users | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
        
        Write-Host "✓ CSV file created successfully!" -ForegroundColor Green
        Write-Host ""
    }
}

# ============================================================================
# FUNCTION: Validate-Password
# Purpose: Validate password strength (reused from Exercise 1)
# Returns: $true if valid, $false otherwise
# ============================================================================
function Validate-Password {
    param (
        [string]$password
    )
    
    # Check all password requirements
    $hasMinLength = $password.Length -ge 8
    $hasLowercase = $password -cmatch "[a-z]"
    $hasUppercase = $password -cmatch "[A-Z]"
    $hasSpecialChar = $password -match "[!|»/$%?&*()\-_+<>\[\]^{}]"
    
    # Return true only if all criteria are met
    return ($hasMinLength -and $hasLowercase -and $hasUppercase -and $hasSpecialChar)
}

# ============================================================================
# FUNCTION: Show-Menu
# Purpose: Display the main menu with all available options
# ============================================================================
function Show-Menu {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    USER MANAGEMENT SYSTEM - MENU" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Lister les comptes utilisateurs" -ForegroundColor White
    Write-Host "  2. Ajouter un nouveau compte" -ForegroundColor White
    Write-Host "  3. Se connecter à un compte" -ForegroundColor White
    Write-Host "  4. Exporter vers Active Directory" -ForegroundColor White
    Write-Host "  5. Sortir du script" -ForegroundColor White
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# FUNCTION: Option1-ListUsers
# Purpose: List all active user accounts from the CSV file
# Points: 10
# ============================================================================
function Option1-ListUsers {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   LISTE DES COMPTES UTILISATEURS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Import users from CSV file
    $users = Import-Csv -Path $csvPath -Delimiter ";"
    
    # Filter only active users
    $activeUsers = $users | Where-Object { $_.Statut -eq "Actif" }
    
    # Check if there are any active users
    if ($activeUsers.Count -eq 0) {
        Write-Host "Aucun utilisateur actif trouvé." -ForegroundColor Yellow
        return
    }
    
    # Display each active user with the specified format
    $userNumber = 1
    foreach ($user in $activeUsers) {
        Write-Host "Utilisateur no : $userNumber" -ForegroundColor Green
        Write-Host "Nom : $($user.Prénom), $($user.Nom)" -ForegroundColor White
        Write-Host "Poste : $($user.Poste)" -ForegroundColor White
        Write-Host "Dernière date de login : $($user.DateDernierLogin)" -ForegroundColor White
        Write-Host "---" -ForegroundColor Gray
        $userNumber++
    }
    
    Write-Host ""
    Write-Host "Total d'utilisateurs actifs : $($activeUsers.Count)" -ForegroundColor Cyan
}

# ============================================================================
# FUNCTION: Option2-AddNewUser
# Purpose: Add a new user to the CSV file with auto-generated credentials
# Points: 10
# ============================================================================
function Option2-AddNewUser {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   AJOUTER UN NOUVEAU COMPTE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Prompt for last name
    $nom = Read-Host "Entrez le nom de famille"
    if ([string]::IsNullOrWhiteSpace($nom)) {
        Write-Host "✗ Le nom est obligatoire!" -ForegroundColor Red
        return
    }
    
    # Prompt for first name
    $prenom = Read-Host "Entrez le prénom"
    if ([string]::IsNullOrWhiteSpace($prenom)) {
        Write-Host "✗ Le prénom est obligatoire!" -ForegroundColor Red
        return
    }
    
    # Prompt for position with validation
    Write-Host ""
    Write-Host "Choisissez le poste:" -ForegroundColor Yellow
    Write-Host "  1. TTP" -ForegroundColor White
    Write-Host "  2. Secrétaire" -ForegroundColor White
    Write-Host "  3. Admin" -ForegroundColor White
    $posteChoice = Read-Host "Entrez le numéro (1-3)"
    
    # Map the choice to position name
    $poste = switch ($posteChoice) {
        "1" { "TTP" }
        "2" { "Secrétaire" }
        "3" { "admin" }
        default {
            Write-Host "✗ Choix invalide!" -ForegroundColor Red
            return
        }
    }
    
    # Generate username: first letter of first name + last name
    # Convert to lowercase and remove spaces
    $userName = ($prenom[0].ToString() + $nom).ToLower() -replace '\s', ''
    
    # Check if username already exists in CSV
    $existingUsers = Import-Csv -Path $csvPath -Delimiter ";"
    $userExists = $existingUsers | Where-Object { $_.UserName -eq $userName }
    
    if ($userExists) {
        Write-Host "✗ Un utilisateur avec le nom '$userName' existe déjà!" -ForegroundColor Red
        
        # Add numbers to make username unique
        $counter = 1
        do {
            $userName = ($prenom[0].ToString() + $nom + $counter).ToLower() -replace '\s', ''
            $userExists = $existingUsers | Where-Object { $_.UserName -eq $userName }
            $counter++
        } while ($userExists)
        
        Write-Host "→ Nouveau nom d'utilisateur généré: $userName" -ForegroundColor Yellow
    }
    
    # Generate and validate password
    Write-Host ""
    Write-Host "Génération du mot de passe..." -ForegroundColor Yellow
    Write-Host "Le mot de passe doit contenir:" -ForegroundColor Gray
    Write-Host "  • Au moins 8 caractères" -ForegroundColor Gray
    Write-Host "  • Une lettre minuscule" -ForegroundColor Gray
    Write-Host "  • Une lettre majuscule" -ForegroundColor Gray
    Write-Host "  • Un caractère spécial" -ForegroundColor Gray
    Write-Host ""
    
    # Loop until valid password is entered
    do {
        $password = Read-Host "Entrez le mot de passe"
        $isValid = Validate-Password -password $password
        
        if (-not $isValid) {
            Write-Host "✗ Mot de passe faible! Réessayez." -ForegroundColor Red
        }
    } while (-not $isValid)
    
    Write-Host "✓ Mot de passe fort accepté!" -ForegroundColor Green
    
    # Get current date and time for last login
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Create new user object
    $newUser = [PSCustomObject]@{
        Nom = $nom
        Prénom = $prenom
        Poste = $poste
        UserName = $userName
        Password = $password
        Statut = "Actif"
        DateDernierLogin = $currentDateTime
    }
    
    # Append to CSV file
    $newUser | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Append -Encoding UTF8
    
    # Display summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✓ UTILISATEUR CRÉÉ AVEC SUCCÈS!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Nom complet : $prenom $nom" -ForegroundColor White
    Write-Host "Nom d'utilisateur : $userName" -ForegroundColor White
    Write-Host "Poste : $poste" -ForegroundColor White
    Write-Host "Statut : Actif" -ForegroundColor White
    Write-Host "Date de création : $currentDateTime" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# FUNCTION: Option3-ConnectToAccount
# Purpose: Authenticate a user against the CSV database
# Points: 10
# ============================================================================
function Option3-ConnectToAccount {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   SE CONNECTER À UN COMPTE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Prompt for credentials
    $inputUserName = Read-Host "Nom d'utilisateur"
    $inputPassword = Read-Host "Mot de passe"
    
    # Import users from CSV
    $users = Import-Csv -Path $csvPath -Delimiter ";"
    
    # Find the user by username
    $user = $users | Where-Object { $_.UserName -eq $inputUserName }
    
    # Check if user exists
    if (-not $user) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "       ✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Raison : Nom d'utilisateur introuvable" -ForegroundColor Red
        Write-Host ""
        return
    }
    
    # Check if user is locked or inactive
    if ($user.Statut -eq "Verrouillé") {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "       ✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Raison : Compte verrouillé" -ForegroundColor Red
        Write-Host "Contactez l'administrateur système." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    if ($user.Statut -eq "Inactif") {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "       ✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Raison : Compte inactif" -ForegroundColor Red
        Write-Host "Contactez l'administrateur système." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # Check password
    if ($user.Password -ne $inputPassword) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "       ✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Raison : Mot de passe incorrect" -ForegroundColor Red
        Write-Host ""
        return
    }
    
    # Login successful - update last login date
    $user.DateDernierLogin = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Save updated CSV
    $users | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
    
    # Display success message
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "       ✓ LOGIN RÉUSSI" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Bienvenue, $($user.Prénom) $($user.Nom)!" -ForegroundColor Green
    Write-Host "Poste : $($user.Poste)" -ForegroundColor White
    Write-Host "Dernière connexion : $($user.DateDernierLogin)" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# FUNCTION: Option4-ExportToAD
# Purpose: Export all CSV users to Active Directory with appropriate groups
# Points: 10
# ============================================================================
function Option4-ExportToAD {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   EXPORTER VERS ACTIVE DIRECTORY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Import users from CSV
    $users = Import-Csv -Path $csvPath -Delimiter ";"
    
    # Counters for statistics
    $successCount = 0
    $skipCount = 0
    $errorCount = 0
    
    # Define group mapping based on position
    $groupMapping = @{
        "TTP" = "CN=TTP,CN=Users,DC=script,DC=local"
        "Secrétaire" = "CN=Secretaire,CN=Users,DC=script,DC=local"
        "admin" = "CN=Administrators,CN=Builtin,DC=script,DC=local"
    }
    
    Write-Host "Début de l'exportation..." -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($user in $users) {
        Write-Host "Traitement de $($user.UserName)..." -ForegroundColor Gray
        
        try {
            # Check if user already exists in AD
            $adUser = Get-ADUser -Filter "SamAccountName -eq '$($user.UserName)'" -ErrorAction SilentlyContinue
            
            if ($adUser) {
                Write-Host "  → Utilisateur existe déjà, ignoré" -ForegroundColor Yellow
                $skipCount++
                continue
            }
            
            # Convert password to secure string
            $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force
            
            # Determine the group based on position
            $groupDN = $groupMapping[$user.Poste]
            
            if (-not $groupDN) {
                Write-Host "  ✗ Poste invalide: $($user.Poste)" -ForegroundColor Red
                $errorCount++
                continue
            }
            
            # Create the AD user
            $adParams = @{
                Name = "$($user.Prénom) $($user.Nom)"
                GivenName = $user.Prénom
                Surname = $user.Nom
                SamAccountName = $user.UserName
                UserPrincipalName = "$($user.UserName)@$domain"
                AccountPassword = $securePassword
                Enabled = ($user.Statut -eq "Actif")
                Path = "CN=Users,DC=script,DC=local"
                ChangePasswordAtLogon = $true
            }
            
            New-ADUser @adParams
            
            # Add user to appropriate group
            Add-ADGroupMember -Identity $groupDN -Members $user.UserName
            
            Write-Host "  ✓ Créé et ajouté au groupe $($user.Poste)" -ForegroundColor Green
            $successCount++
            
        } catch {
            Write-Host "  ✗ Erreur: $($_.Exception.Message)" -ForegroundColor Red
            $errorCount++
        }
    }
    
    # Display summary
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   RÉSUMÉ DE L'EXPORTATION" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Utilisateurs créés : $successCount" -ForegroundColor Green
    Write-Host "Utilisateurs ignorés : $skipCount" -ForegroundColor Yellow
    Write-Host "Erreurs : $errorCount" -ForegroundColor Red
    Write-Host "Total traité : $($users.Count)" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# MAIN PROGRAM EXECUTION
# ============================================================================

# Display welcome banner
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SYSTÈME DE GESTION DES UTILISATEURS" -ForegroundColor Cyan
Write-Host "  Domaine: script.local" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Initialize CSV file if it doesn't exist
Initialize-CSVFile

# Main program loop
do {
    # Display menu
    Show-Menu
    
    # Get user choice
    $choice = Read-Host "Choisissez une option (1-5)"
    
    # Execute the selected option
    switch ($choice) {
        "1" {
            Option1-ListUsers
        }
        "2" {
            Option2-AddNewUser
        }
        "3" {
            Option3-ConnectToAccount
        }
        "4" {
            Option4-ExportToAD
        }
        "5" {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "  Au revoir! Merci d'avoir utilisé" -ForegroundColor Cyan
            Write-Host "  le système de gestion." -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
            break
        }
        default {
            Write-Host ""
            Write-Host "✗ Option invalide! Choisissez entre 1 et 5." -ForegroundColor Red
        }
    }
    
    # Pause before showing menu again (except for exit)
    if ($choice -ne "5") {
        Write-Host ""
        Write-Host "Appuyez sur Entrée pour continuer..." -ForegroundColor Gray
        Read-Host
    }
    
} while ($choice -ne "5")
