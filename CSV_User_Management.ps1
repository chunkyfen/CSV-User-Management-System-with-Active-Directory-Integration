# ============================================================================
# EXERCISE 3: CSV USER MANAGEMENT SYSTEM WITH ACTIVE DIRECTORY INTEGRATION
# ============================================================================
# Domain: script.local
# ============================================================================

Import-Module ActiveDirectory

$csvPath = "C:\Users\Administrator\Downloads\utilisateurs.csv"
$domain  = "script.local"

# ============================================================================
# FUNCTION: Validate-Password
# ============================================================================
function Validate-Password {
    param ([string]$password)
    return (
        $password.Length -ge 8 -and
        $password -cmatch "[a-z]" -and
        $password -cmatch "[A-Z]" -and
        $password -match "[!/$%?&*()\-_+<>[\]^{}]"
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
    Write-Host "Bienvenue, $($user.Prénom) $($user.Nom)!"
    Write-Host "Poste : $($user.Poste)"
    Write-Host "Dernière connexion : $($user.DateDernierLogin)"
    Write-Host ""
}

# ============================================================================
# FUNCTION: Option4-ExportToAD
# ============================================================================
function Option4-ExportToAD {
    $users = Import-Csv -Path $csvPath -Delimiter ";"

    $ouMapping = @{
        "TTP"        = "OU=TTP,OU=Exercice3,DC=script,DC=local"
        "Secrétaire" = "OU=Secrétaire,OU=Exercice3,DC=script,DC=local"
        "admin"      = "OU=admin,OU=Exercice3,DC=script,DC=local"
    }

    $groupMapping = @{
        "TTP"        = "CN=TTP,OU=Exercice3,DC=script,DC=local"
        "Secrétaire" = "CN=Secretaire,OU=Exercice3,DC=script,DC=local"
        "admin"      = "CN=Administrators,CN=Builtin,DC=script,DC=local"
    }

    foreach ($user in $users) {
        try {
            $existing = Get-ADUser -Filter "SamAccountName -eq '$($user.UserName)'" -ErrorAction SilentlyContinue
            if ($existing) { Write-Host "→ $($user.UserName) existe déjà, ignoré"; continue }

            $ouPath = $ouMapping[$user.Poste]
            if (-not $ouPath) { Write-Host "✗ OU non trouvé pour $($user.Poste)"; continue }

            $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force

            New-ADUser -Name "$($user.Prénom) $($user.Nom)" `
                       -GivenName $user.Prénom `
                       -Surname $user.Nom `
                       -SamAccountName $user.UserName `
                       -UserPrincipalName "$($user.UserName)@$domain" `
                       -AccountPassword $securePassword `
                       -Enabled ($user.Statut -eq "Actif") `
                       -Path $ouPath `
                       -ChangePasswordAtLogon $true

            # Add to group if mapping exists
            $groupDN = $groupMapping[$user.Poste]
            if ($groupDN) {
                Add-ADGroupMember -Identity $groupDN -Members $user.UserName
                Write-Host "  ✓ Créé et ajouté au groupe $($user.Poste)" -ForegroundColor Green
            } else {
                Write-Host "  ! Aucun groupe mappé pour le poste $($user.Poste)" -ForegroundColor Yellow
            }

        } catch {
            Write-Host "  ✗ Erreur: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   RÉSUMÉ DE L'EXPORTATION" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total utilisateurs traités : $($users.Count)" -ForegroundColor White
    Write-Host ""
}

# ============================================================================
# MAIN PROGRAM EXECUTION
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SYSTÈME DE GESTION DES UTILISATEURS" -ForegroundColor Cyan
Write-Host "  Domaine: script.local" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

do {
    Show-Menu
    $choice = Read-Host "Choisissez une option (1-5)"

    switch ($choice) {
        "1" { Option1-ListUsers }
        "2" { Option2-AddNewUser }
        "3" { Option3-ConnectToAccount }
        "4" { Option4-ExportToAD }
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

    if ($choice -ne "5") {
        Write-Host ""
        Write-Host "Appuyez sur Entrée pour continuer..." -ForegroundColor Gray
        Read-Host
    }
} while ($choice -ne "5")
