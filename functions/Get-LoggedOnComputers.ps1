 Function Get-LoggedOnComputers
{
#
# Parameters
#
Param(
    # Username
    [Parameter(
        Mandatory = $true,
        Position = 0
    )]
    [string]
    $Username,

    # Search Base
    [Parameter(
        Mandatory = $false,
        Position = 1
    )]
    [string]
    $SearchBase = (Get-ADDomain | ForEach-Object DistinguishedName)
)


#
# Variables
#
$ErrorActionPreference = "SilentlyContinue"
$LoggedOnComputers = @()


#
# Main
#
# Get all domain computers
$DomainComputers = Get-ADComputer -Filter { Enabled -eq $true } -SearchBase $SearchBase

# Query all computers if user is logged on
foreach ( $Computer in $DomainComputers )
{
    $Result = query user /server:$($Computer.Name)

    if ( $Result -like "*$Username*" )
    {
        $LoggedOnComputers += $Computer.Name
        Write-Output "Found $($Computer.Name)"
    }
}

# Output the result
$LoggedOnComputers
} 
