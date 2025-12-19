# ============================================================================
# EXERCISE 3: CSV USER MANAGEMENT SYSTEM WITH ACTIVE DIRECTORY INTEGRATION
# ============================================================================
# Domain: script.local
# This script manages user accounts through a CSV file and can export them
# to Active Directory. It provides a menu-driven interface for all operations.
# ============================================================================

Import-Module ActiveDirectory

$csvPath = "C:\Users\Administrator\Downloads\utilisateurs.csv"
$domain = "script.local"

# ============================================================================
# FUNCTION: Initialize-CSVFile
# ============================================================================
function Initialize-CSVFile {
    if (-not (Test-Path $csvPath)) {
        Write-Host "Creating utilisateurs.csv file..." -ForegroundColor Yellow

        $users = @(
            [PSCustomObject]@{Nom="Pierre";Prénom="André";Poste="TTP";UserName="pAndre";Password="pA12345!";Statut="Actif";DateDernierLogin="2024-08-24 9:00:00"},
            [PSCustomObject]@{Nom="Nicholas";Prénom="Judith";Poste="Secrétaire";UserName="nJudith";Password="nJ12345!";Statut="Verrouillé";DateDernierLogin="2024-08-24 9:00:00"},
            [PSCustomObject]@{Nom="Tremblay";Prénom="Antoine";Poste="admin";UserName="tAntoine";Password="tA12345!";Statut="Actif";DateDernierLogin="2024-08-24 9:00:00"},
            [PSCustomObject]@{Nom="Joseph";Prénom="Mariah";Poste="TTP";UserName="jMariah";Password="jM12345!";Statut="Inactif";DateDernierLogin="2024-08-24 9:00:00"},
            [PSCustomObject]@{Nom="Lafrancois";Prénom="Etienne";Poste="Secrétaire";UserName="lEtienne";Password="lE12345!";Statut="Actif";DateDernierLogin="2024-08-24 9:00:00"}
        )

        $users | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Encoding UTF8
        Write-Host "✓ CSV file created successfully!" -ForegroundColor Green
    }
}

# ============================================================================
# FUNCTION: Validate-Password
# ============================================================================
function Validate-Password {
    param ([string]$password)
    return (
        $password.Length -ge 8 -and
        $password -cmatch "[a-z]" -and
        $password -cmatch "[A-Z]" -and
        $password -match "[!|»/$%?&*()\-_+<>

\[\]

^{}]"
    )
}

# ============================================================================
# FUNCTION: Show-Menu
# ============================================================================
function Show-Menu {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    USER MANAGEMENT SYSTEM - MENU" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  1. Lister les comptes utilisateurs"
    Write-Host "  2. Ajouter un nouveau compte"
    Write-Host "  3. Se connecter à un compte"
    Write-Host "  4. Exporter vers Active Directory"
    Write-Host "  5. Sortir du script"
    Write-Host "============================================" -ForegroundColor Cyan
}

# ============================================================================
# FUNCTION: Option1-ListUsers
# ============================================================================
function Option1-ListUsers {
    $users = Import-Csv -Path $csvPath -Delimiter ";"
    $activeUsers = $users | Where-Object { $_.Statut -eq "Actif" }

    if ($activeUsers.Count -eq 0) {
        Write-Host "Aucun utilisateur actif trouvé." -ForegroundColor Yellow
        return
    }

    $i = 1
    foreach ($user in $activeUsers) {
        Write-Host "Utilisateur no : $i" -ForegroundColor Green
        Write-Host "Nom : $($user.Prénom), $($user.Nom)"
        Write-Host "Poste : $($user.Poste)"
        Write-Host "Dernière date de login : $($user.DateDernierLogin)"
        Write-Host "---"
        $i++
    }

    Write-Host "Total d'utilisateurs actifs : $($activeUsers.Count)" -ForegroundColor Cyan
}

# ============================================================================
# FUNCTION: Option2-AddNewUser
# ============================================================================
function Option2-AddNewUser {
    $nom = Read-Host "Entrez le nom de famille"
    if ([string]::IsNullOrWhiteSpace($nom)) { Write-Host "✗ Le nom est obligatoire!" -ForegroundColor Red; return }

    $prenom = Read-Host "Entrez le prénom"
    if ([string]::IsNullOrWhiteSpace($prenom)) { Write-Host "✗ Le prénom est obligatoire!" -ForegroundColor Red; return }

    Write-Host "Choisissez le poste:"
    Write-Host "  1. TTP"
    Write-Host "  2. Secrétaire"
    Write-Host "  3. Admin"
    $posteChoice = Read-Host "Entrez le numéro (1-3)"
    $poste = switch ($posteChoice) {
        "1" { "TTP" }
        "2" { "Secrétaire" }
        "3" { "admin" }
        default { Write-Host "✗ Choix invalide!" -ForegroundColor Red; return }
    }

    $userName = ($prenom[0] + $nom).ToLower() -replace '\s', ''
    $existingUsers = Import-Csv -Path $csvPath -Delimiter ";"
    $userExists = $existingUsers | Where-Object { $_.UserName -eq $userName }

    if ($userExists) {
        $counter = 1
        do {
            $userName = ($prenom[0] + $nom + $counter).ToLower() -replace '\s', ''
            $userExists = $existingUsers | Where-Object { $_.UserName -eq $userName }
            $counter++
        } while ($userExists)
        Write-Host "→ Nouveau nom d'utilisateur généré: $userName" -ForegroundColor Yellow
    }

    do {
        $password = Read-Host "Entrez le mot de passe"
        $isValid = Validate-Password -password $password
        if (-not $isValid) { Write-Host "✗ Mot de passe faible! Réessayez." -ForegroundColor Red }
    } while (-not $isValid)

    Write-Host "✓ Mot de passe fort accepté!" -ForegroundColor Green
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $newUser = [PSCustomObject]@{
        Nom = $nom
        Prénom = $prenom
        Poste = $poste
        UserName = $userName
        Password = $password
        Statut = "Actif"
        DateDernierLogin = $currentDateTime
    }

    $newUser | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Append -Encoding UTF8

    Write-Host "✓ UTILISATEUR CRÉÉ AVEC SUCCÈS!" -ForegroundColor Green
    Write-Host "Nom complet : $prenom $nom"
    Write-Host "Nom d'utilisateur : $userName"
    Write-Host "Poste : $poste"
    Write-Host "Statut : Actif"
    Write-Host "Date de création : $currentDateTime"
}

# ============================================================================
# FUNCTION: Option3-ConnectToAccount
# ============================================================================
function Option3-ConnectToAccount {
    $inputUserName = Read-Host "Nom d'utilisateur"
    $inputPassword = Read-Host "Mot de passe"
    $users = Import-Csv -Path $csvPath -Delimiter ";"
    $user = $users | Where-Object { $_.UserName -eq $inputUserName }

    if (-not $user) { Write-Host "✗ LOGIN ÉCHOUÉ - utilisateur introuvable" -ForegroundColor Red; return }
    if ($user.Statut -eq "Verrouillé") { Write-Host "✗ LOGIN ÉCHOUÉ - compte verrouillé" -ForegroundColor Red; return }
    if ($user.Statut -eq "Inactif") { Write-Host "✗ LOGIN ÉCHOUÉ - compte inactif" -ForegroundColor Red; return }
    if ($user.Password -ne $inputPassword) { Write-Host "✗ LOGIN ÉCHOUÉ - mot de passe incorrect" -ForegroundColor Red; return }

    $user.DateDernierLogin = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $users | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Encoding UTF8

    Write-Host "✓ LOGIN RÉUSSI" -ForegroundColor Green
    Write-Host
