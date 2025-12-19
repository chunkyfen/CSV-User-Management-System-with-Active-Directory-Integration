## **PEDAGOGICAL DOCUMENTATION**

### **SECTION 1: Script Header and Initialization**

```powershell
Import-Module ActiveDirectory

$csvPath = "utilisateurs.csv"
$domain = "script.local"
```

**Educational Explanation:**

This section sets up the fundamental components needed for the entire script. The `Import-Module ActiveDirectory` command loads the Active Directory PowerShell module, which provides cmdlets like `New-ADUser`, `Get-ADUser`, and `Add-ADGroupMember`. Without this module, we wouldn't be able to interact with Active Directory.

The two variables define critical configuration:
- `$csvPath`: The filename of our CSV database. Since it's just a filename (not a full path like "C:\Users\..."), the file will be created/read from the same folder where the script runs.
- `$domain`: Your Active Directory domain name. This is used when creating user principal names (UPNs) like "jdupont@script.local".

**Why use variables for these?** If you ever need to change the domain or CSV filename, you only change it once at the top instead of searching through hundreds of lines of code. This is the "single source of truth" principle.

---

### **SECTION 2: CSV Initialization Function**

```powershell
function Initialize-CSVFile {
    if (-not (Test-Path $csvPath)) {
        # Create sample data...
    }
}
```

**Educational Explanation:**

This function ensures that the CSV file exists before the program tries to read from it. `Test-Path` checks if a file or folder exists, returning `$true` or `$false`. The `-not` operator flips the result (if file doesn't exist, proceed).

Inside the function, we create an array of `[PSCustomObject]` objects. In PowerShell, `[PSCustomObject]` is the modern way to create structured data objects with properties. Each object represents one user with all their information.

The `@(...)` creates an array (list) that can hold multiple objects. We then use `Export-Csv` to write this array to a file with semicolon delimiters (`;`) as specified in the requirements.

**Why use PSCustomObject instead of hashtables?** PSCustomObjects work better with `Export-Csv` and maintain property order, making the output predictable and readable.

---

### **SECTION 3: Password Validation Function**

```powershell
function Validate-Password {
    param ([string]$password)
    
    $hasMinLength = $password.Length -ge 8
    $hasLowercase = $password -cmatch "[a-z]"
    $hasUppercase = $password -cmatch "[A-Z]"
    $hasSpecialChar = $password -match "[!|»/$%?&*()\-_+<>\[\]^{}]"
    
    return ($hasMinLength -and $hasLowercase -and $hasUppercase -and $hasSpecialChar)
}
```

**Educational Explanation:**

This function is reused from Exercise 1, demonstrating code reusability - a core programming principle. The `param` block defines function parameters (inputs). The `[string]` is a type constraint that ensures only text can be passed to this parameter.

The function performs all four validation checks and returns a single Boolean value using the `-and` operator. This makes the function simple to use: call it with a password, get back true/false.

**Function benefits:** Instead of copying the validation logic multiple times throughout the script, we define it once as a function and call it whenever needed. If password requirements change, we update one place, not ten.

---

### **SECTION 4: Menu Display Function**

```powershell
function Show-Menu {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    USER MANAGEMENT SYSTEM - MENU" -ForegroundColor Cyan
    # ... menu options ...
}
```

**Educational Explanation:**

Functions don't always need parameters or return values. This function has one job: display the menu consistently every time it's called. Using a function for the menu ensures it looks identical every loop iteration.

The color-coded display (`-ForegroundColor Cyan` for headers, `White` for options) creates visual hierarchy. Users' eyes are naturally drawn to the colored sections first, making the interface easier to navigate.

**Design principle:** Separating display logic into its own function follows the "separation of concerns" principle - each function has one clear responsibility.

---

### **SECTION 5: Option 1 - List Users Function**

```powershell
function Option1-ListUsers {
    $users = Import-Csv -Path $csvPath -Delimiter ";"
    $activeUsers = $users | Where-Object { $_.Statut -eq "Actif" }
    
    if ($activeUsers.Count -eq 0) {
        Write-Host "Aucun utilisateur actif trouvé." -ForegroundColor Yellow
        return
    }
    
    $userNumber = 1
    foreach ($user in $activeUsers) {
        Write-Host "Utilisateur no : $userNumber" -ForegroundColor Green
        Write-Host "Nom : $($user.Prénom), $($user.Nom)" -ForegroundColor White
        # ... display other fields ...
        $userNumber++
    }
}
```

**Educational Explanation:**

This function demonstrates PowerShell's pipeline power. `Import-Csv` reads the CSV file and automatically creates objects with properties matching the column headers. Each row becomes an object.

The pipeline operator (`|`) passes data from one command to the next. `Where-Object` filters the data, keeping only objects where the `Statut` property equals "Actif". The `$_` variable represents the current object in the pipeline.

The `foreach` loop iterates through each active user, displaying their information in the specified format. The `$userNumber++` increments the counter after each iteration, creating the numbered list (1, 2, 3...).

**Why filter for active users?** The requirements specifically say to list only active accounts. Locked or inactive accounts shouldn't appear in this list, maintaining security by not exposing disabled accounts.

---

### **SECTION 6: Option 2 - Add New User Function (Part 1: Input Collection)**

```powershell
$nom = Read-Host "Entrez le nom de famille"
if ([string]::IsNullOrWhiteSpace($nom)) {
    Write-Host "✗ Le nom est obligatoire!" -ForegroundColor Red
    return
}
```

**Educational Explanation:**

Input validation is critical in any application. The `[string]::IsNullOrWhiteSpace()` method is more robust than simple empty checks. It returns `$true` if the string is:
- Null (doesn't exist)
- Empty ("")
- Contains only whitespace ("   ")

This prevents users from pressing Enter without typing anything, or entering just spaces. The `return` statement exits the function immediately if validation fails, preventing further execution with invalid data.

**Security note:** Always validate user input. Never trust that users will enter correct data - they might make mistakes, or in worst cases, try to break your system.

---

### **SECTION 7: Option 2 - Add New User Function (Part 2: Position Selection)**

```powershell
Write-Host "Choisissez le poste:" -ForegroundColor Yellow
Write-Host "  1. TTP" -ForegroundColor White
Write-Host "  2. Secrétaire" -ForegroundColor White
Write-Host "  3. Admin" -ForegroundColor White
$posteChoice = Read-Host "Entrez le numéro (1-3)"

$poste = switch ($posteChoice) {
    "1" { "TTP" }
    "2" { "Secrétaire" }
    "3" { "admin" }
    default {
        Write-Host "✗ Choix invalide!" -ForegroundColor Red
        return
    }
}
```

**Educational Explanation:**

The `switch` statement is PowerShell's version of a multi-way conditional. It's cleaner than writing multiple `if-elseif-else` blocks. It compares `$posteChoice` against each case ("1", "2", "3") and executes the matching code block.

The `default` case catches any input that doesn't match the defined cases. If someone enters "5" or "abc", the default block executes, displays an error, and exits the function.

**UX improvement:** Instead of making users type "Secrétaire" exactly (risking typos or accent errors), we give them numbered choices. This is called a "constrained input" pattern - reducing error possibilities by limiting valid choices.

---

### **SECTION 8: Option 2 - Add New User Function (Part 3: Username Generation)**

```powershell
$userName = ($prenom[0].ToString() + $nom).ToLower() -replace '\s', ''

$existingUsers = Import-Csv -Path $csvPath -Delimiter ";"
$userExists
= $existingUsers | Where-Object { $_.UserName -eq $userName }

if ($userExists) {
    Write-Host "✗ Un utilisateur avec le nom '$userName' existe déjà!" -ForegroundColor Red
    
    $counter = 1
    do {
        $userName = ($prenom[0].ToString() + $nom + $counter).ToLower() -replace '\s', ''
        $userExists = $existingUsers | Where-Object { $_.UserName -eq $userName }
        $counter++
    } while ($userExists)
    
    Write-Host "→ Nouveau nom d'utilisateur généré: $userName" -ForegroundColor Yellow
}
```

**Educational Explanation:**

This section implements the username generation logic specified in the requirements: first letter of first name + full last name.

Breaking down the generation:
- `$prenom[0]` gets the first character (index 0) of the first name
- `.ToString()` converts it to a string (necessary for concatenation)
- `+ $nom` appends the last name
- `.ToLower()` converts everything to lowercase
- `-replace '\s', ''` removes all whitespace characters (spaces, tabs)

**Duplicate handling:** The script checks if the username already exists. If it does, it enters a `do-while` loop that appends numbers (1, 2, 3...) until a unique username is found. This prevents errors when creating users with common names.

**Example:** If "Antoine Tremblay" exists as "atremblay", the second Antoine Tremblay becomes "atremblay1", the third becomes "atremblay2", etc.

---

### **SECTION 9: Option 2 - Add New User Function (Part 4: Password Validation Loop)**

```powershell
do {
    $password = Read-Host "Entrez le mot de passe"
    $isValid = Validate-Password -password $password
    
    if (-not $isValid) {
        Write-Host "✗ Mot de passe faible! Réessayez." -ForegroundColor Red
    }
} while (-not $isValid)

Write-Host "✓ Mot de passe fort accepté!" -ForegroundColor Green
```

**Educational Explanation:**

This is a validation loop - it keeps asking for input until valid input is received. The `do-while` loop structure ensures the code inside runs at least once before checking the condition.

The loop continues (`while (-not $isValid)`) as long as the password is invalid. Once a valid password is entered, `$isValid` becomes `$true`, `-not $isValid` becomes `$false`, and the loop exits.

**User experience:** Instead of rejecting the password and forcing users to restart the entire process, this loop lets them correct just the password. It's frustrating to fill out a long form only to have it rejected at the end - this pattern avoids that.

---

### **SECTION 10: Option 2 - Add New User Function (Part 5: Creating and Saving)**

```powershell
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
```

**Educational Explanation:**

`Get-Date` retrieves the current system date and time. The `-Format` parameter specifies how to format it. The format string "yyyy-MM-dd HH:mm:ss" creates output like "2024-12-19 14:30:45".

The new user object is created with all required properties matching the CSV structure. The `@{...}` syntax after `[PSCustomObject]` creates an ordered hashtable that becomes the object's properties.

**The `-Append` parameter is crucial** - without it, `Export-Csv` would overwrite the entire file with just the new user, deleting all existing users! With `-Append`, it adds the new user to the end of the existing file.

`-NoTypeInformation` prevents PowerShell from adding a "#TYPE" header line that would corrupt our CSV format. `-Encoding UTF8` ensures special characters (accents, etc.) are saved correctly.

---

### **SECTION 11: Option 3 - Connect to Account (Part 1: Credential Verification)**

```powershell
$inputUserName = Read-Host "Nom d'utilisateur"
$inputPassword = Read-Host "Mot de passe"

$users = Import-Csv -Path $csvPath -Delimiter ";"
$user = $users | Where-Object { $_.UserName -eq $inputUserName }

if (-not $user) {
    Write-Host "✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
    Write-Host "Raison : Nom d'utilisateur introuvable" -ForegroundColor Red
    return
}
```

**Educational Explanation:**

This implements authentication - verifying that users are who they claim to be. The script imports all users and searches for one matching the entered username.

The `Where-Object` filter returns `$null` if no match is found. The `-not` operator converts `$null` to `$true`, triggering the error message. This is a common pattern in PowerShell: check if something exists, and handle the negative case first.

**Security consideration:** Notice we don't say "user doesn't exist" vs. "password wrong" until after checking the password. Telling attackers "this username exists" gives them half the information they need. However, in this educational context, we provide specific error reasons for better UX.

---

### **SECTION 12: Option 3 - Connect to Account (Part 2: Status Validation)**

```powershell
if ($user.Statut -eq "Verrouillé") {
    Write-Host "✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
    Write-Host "Raison : Compte verrouillé" -ForegroundColor Red
    Write-Host "Contactez l'administrateur système." -ForegroundColor Yellow
    return
}

if ($user.Statut -eq "Inactif") {
    Write-Host "✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
    Write-Host "Raison : Compte inactif" -ForegroundColor Red
    return
}
```

**Educational Explanation:**

These checks implement account status validation as specified in the requirements: only active accounts can log in. Even if someone knows the correct username and password, they cannot access a locked or inactive account.

This is essential for security: when an employee leaves the company, their account is set to "Inactif", preventing access even though the account still exists (preserved for records). "Verrouillé" might be used for accounts suspected of compromise or policy violations.

**Real-world parallel:** This is like how your bank might freeze your account even though you have the correct PIN - your credentials work, but account status prevents access.

---

### **SECTION 13: Option 3 - Connect to Account (Part 3: Password Check and Success)**

```powershell
if ($user.Password -ne $inputPassword) {
    Write-Host "✗ LOGIN ÉCHOUÉ" -ForegroundColor Red
    Write-Host "Raison : Mot de passe incorrect" -ForegroundColor Red
    return
}

$user.DateDernierLogin = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$users | Export-Csv -Path $csvPath -Delimiter ";" -NoTypeInformation -Encoding UTF8

Write-Host "✓ LOGIN RÉUSSI" -ForegroundColor Green
Write-Host "Bienvenue, $($user.Prénom) $($user.Nom)!" -ForegroundColor Green
```

**Educational Explanation:**

The `-ne` operator means "not equal". If the stored password doesn't match the entered password, login fails.

**Critical detail:** Notice we update `$user.DateDernierLogin` but then export the entire `$users` collection. Why? Because `$user` is a reference to one object in the `$users` array. Modifying `$user` modifies that object in the array. When we export `$users`, it includes our updated object.

**Important:** We use `Export-Csv` without `-Append` here because we're replacing the entire file with the updated version. If we used `-Append`, we'd add duplicate records instead of updating existing ones.

The personalized welcome message (`"Bienvenue, $($user.Prénom) $($user.Nom)!"`) creates a better user experience than a generic "login successful" message.

---

### **SECTION 14: Option 4 - Export to AD (Part 1: Group Mapping)**

```powershell
$groupMapping = @{
    "TTP" = "CN=TTP,CN=Users,DC=script,DC=local"
    "Secrétaire" = "CN=Secretaire,CN=Users,DC=script,DC=local"
    "admin" = "CN=Administrators,CN=Builtin,DC=script,DC=local"
}
```

**Educational Explanation:**

This hashtable maps position names to their corresponding Active Directory group Distinguished Names (DNs). A DN is the full path to an object in Active Directory's hierarchical structure.

Breaking down a DN: `"CN=TTP,CN=Users,DC=script,DC=local"`
- `CN=TTP` - Common Name: the group's name
- `CN=Users` - Container: where the group is located
- `DC=script,DC=local` - Domain Components: the domain name split into parts

**Why use a hashtable?** It creates a clear mapping between simple position names ("TTP") and complex AD paths. This makes the code maintainable - if group locations change, update the hashtable once instead of searching through code.

---

### **SECTION 15: Option 4 - Export to AD (Part 2: User Creation Loop)**

```powershell
foreach ($user in $users) {
    try {
        $adUser = Get-ADUser -Filter "SamAccountName -eq '$($user.UserName)'" -ErrorAction SilentlyContinue
        
        if ($adUser) {
            Write-Host "  → Utilisateur existe déjà, ignoré" -ForegroundColor Yellow
            $skipCount++
            continue
        }
        
        $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force
        # ... create user ...
        
    } catch {
        Write-Host "  ✗ Erreur: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
}
```

**Educational Explanation:**

The `try-catch` block implements error handling - essential when interacting with external systems like Active Directory. If any command inside `try` fails, execution jumps to the `catch` block instead of crashing the entire script.

`Get-ADUser` checks if a user already exists. The `-ErrorAction SilentlyContinue` parameter prevents error messages if the user isn't found - we handle that case ourselves. If the user exists, `continue` skips to the next iteration without creating a duplicate.

`ConvertTo-SecureString` converts the plain-text password to an encrypted SecureString object required by `New-ADUser`. The `-AsPlainText` flag indicates the input is plain text, and `-Force` bypasses a warning about using plain text (necessary in automated scripts).

**Security note:** In production, passwords should never be stored as plain text in CSV files. This is acceptable for educational purposes but would be a severe security vulnerability in real systems.

---

### **SECTION 16: Option 4 - Export to AD (Part 3: Creating AD User)**

```powershell
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
Add-ADGroupMember -Identity $groupDN -Members $user.UserName
```

**Educational Explanation:**

The `@adParams` hashtable uses **splatting** - a PowerShell technique for passing multiple parameters to a command cleanly. Instead of writing one enormous command line with 10 parameters, we define them in a hashtable and "splat" them using `@adParams`.

Key parameters explained:
- `Name`: Full display name
- `GivenName` / `Surname`: First and last names separately
- `SamAccountName`: Login username (legacy Windows name)
- `UserPrincipalName`: Modern login format (email-style)
- `Enabled`: Boolean expression - only true if status is "Actif"
- `ChangePasswordAtLogon`: Forces password change on first login (security best practice)

`Add-ADGroupMember` adds the newly created user to the appropriate group based on their position, giving them the correct permissions.

---

### **SECTION 17: Main Program Loop**

```powershell
do {
    Show-Menu
    $choice = Read-Host "Choisissez une option (1-5)"
    
    switch ($choice) {
        "1" { Option1-ListUsers }
        "2" { Option2-AddNewUser }
        "3" { Option3-ConnectToAccount }
        "4" { Option4-ExportToAD }
        "5" { 
            Write-Host "Au revoir!" -ForegroundColor Cyan
            break 
        }
        default {
            Write-Host "✗ Option invalide!" -ForegroundColor Red
        }
    }
    
    if ($choice -ne "5") {
        Write-Host "Appuyez sur Entrée pour continuer..." -ForegroundColor Gray
        Read-Host
    }
    
} while ($choice -ne "5")
```

**Educational Explanation:**

This is the program's main loop - the core that keeps the menu running until the user chooses to exit. The `do-while` structure ensures the menu displays at least once.

The `switch` statement routes user input to the appropriate function. Each function is called simply by name, keeping the main loop clean and readable. This is the **menu-driven architecture** pattern - common in console applications.

The `break` statement in option 5 exits the `switch` but not the loop. The loop condition `while ($choice -ne "5")` handles actual exit - when choice is 5, the condition becomes false, and the loop ends.

**The pause mechanism** (`Read-Host` after each option except 5) prevents the menu from immediately reappearing before users can read the output. This improves UX by giving users control over when to proceed.

**Error handling:** The `default` case catches invalid inputs gracefully instead of crashing, following the principle of **defensive programming** - assume users will make mistakes and handle them gracefully.

---

## **TESTING SCENARIOS**

### **Test 1: List Users**
- Run option 1
- Verify only active users appear (Pierre, Tremblay, Lafrancois)
- Verify Nicholas (Verrouillé) and Joseph (Inactif) don't appear

### **Test 2: Add User**
- Run option 2
- Enter: Nom=Dupont, Prénom=Jean, Poste=TTP
- Try weak password: "hello" → should reject
- Try strong password: "Dupont2000!" → should accept
- Verify username is "jdupont"

### **Test 3: Login Tests**
- Test wrong username → should fail
- Test correct username but wrong password → should fail
- Test locked account (Nicholas) → should fail with "Compte verrouillé"
- Test inactive account (Joseph) → should fail with "Compte inactif"
- Test valid login (tAntoine/tA12345!) → should succeed

### **Test 4: Export to AD**
- Ensure AD groups exist first
- Run option 4
- Verify users created in AD
- Verify group memberships correct
- Test duplicate run → should skip existing users

---

## **KEY LEARNING OUTCOMES**

1. **CSV File Operations**: Reading, writing, appending data
2. **Function Design**: Creating reusable, single-purpose functions
3. **Error Handling**: Try-catch blocks and validation
4. **User Authentication**: Credential verification and status checking
5. **Active Directory Integration**: Creating users and managing groups
6. **Menu-Driven Architecture**: Building interactive console applications
7. **Data Validation**: Ensuring data integrity at every input point
8. **Security Best Practices**: Password validation, account status, secure strings
9. **Code Organization**: Using functions for modularity and maintainability
10. **User Experience**: Clear feedback, colored output, helpful error messages
