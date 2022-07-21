#
# Variables
#
$AdminGroupNames = @(
    "Account Operators",
    "Administrators",
    "Backup Operators",
    "Certificate Operators",
    "Certificate Publishers",
    "Dns Admins",
    "Domain Administrators",
    "Enterprise Administrators",
    "Enterprise Key Administrators",
    "Key Administrators",
    "Print Operators",
    "Replicator",
    "Schema Administrators",
    "Server Operators"
)

[array]$AdminGroups = @()
$AdminMembers = @()
$AdminUsers = @()

#
# Main
#
# Get DNs of admin groups
foreach ( $Group in $AdminGroupNames )
{
    [array]$AdminGroups += Get-ADGroup -Filter { Name -eq $Group } `
        -Properties DistinguishedName
}

# Get Admin Users

while ( $AdminGroups.Count -gt 0 )
{
    foreach ( $Group in $AdminGroups )
    {
        [array]$AdminGroups = $AdminGroups | `
            Where-Object { $_.ObjectGuid -ne $Group.ObjectGUID }

        $AdminMembers += Get-ADGroupMember -Identity $Group.ObjectGUID | `
            Where-Object objectClass -EQ "user"

        [array]$AdminGroups += Get-ADGroupMember -Identity $Group.ObjectGUID | `
            Where-Object objectClass -EQ "group" | `
            Where-Object objectGUID -NE $Group.objectGUID
    }
}

$AdminMembers = $AdminMembers | `
    Select-Object -Unique

foreach ( $Admin in $AdminMembers )
{
    $AdminUsers += Get-ADUser -Properties AccountNotDelegated, ServicePrincipalName `
        -Filter { ObjectGUID -eq $Admin.ObjectGUID }
}

# Get AdminUsers with SPN
$AdminUsersWithSpn = $AdminUsers | `
    Where-Object ServicePrincipalName -NE $null

# Get AdminUsers WITHOUT SPN
$AdminUsersWithoutSpn = $AdminUsers | `
    Where-Object { $AdminUsersWithSpn -NotContains $_ }

# Accounts to set flag for
$AdminUsersToEdit = $AdminUsersWithoutSpn | `
    Where-Object AccountNotDelegated -EQ $false

# Set flag
foreach ( $User in $AdminUsersToEdit )
{
    Set-ADUser -Identity $User.ObjectGUID `
        -AccountNotDelegated $true
}

# Output
if ( $AdminUsersToEdit )
{
    Write-Output "Set the flag This Account is sensitive and cannot be delegated for following users:"
    $AdminUsersToEdit | `
        Select-Object DistinguishedName, Name, ObjectGUID, SamAccountName, UserPrincipalName
}

if ( $AdminUsersWithSpn )
{
    Write-Output "These Admin Accounts have SPNs. Please review if these admin permissions are necessary."
    $AdminUsersWithSpn | `
        Select-Object DistinguishedName, Enabled, Name, ObjectGUID, SamAccountName, ServicePrincipalName, UserPrincipalName 
}
