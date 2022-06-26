function Add-ContrainedDelegation
{

}

function Add-UnconstrainedDelegation
{

}

function Add-KerberosPreAuthentication
{
    param (
        $sam_account_name
    )
    
    Get-ADUser -Identity $sam_account_name | Set-ADAccountControl -DoesNotRequirePreAuth:$true
}

function Add-KerberosPreAuthenticationToRandomUser
{
    $filter = "name -notlike 'Administrator' -and name -notlike 'krbtgt' -and name -notlike 'Guest'"
    $users_list = Get-Aduser -Filter $filter
    
    $user = Get-Random -InputObject $users_list
    Add-KerberosPreAuthentication $user.SamAccountName
}

function Add-KerberosPreAuthenticationToSpecificUser
{
    param (
        [Parameter(Mandatory = $true)]
        $SamAccountName
    )
    
    $user = Get-ADUser -Identity $SamAccountName
    Add-KerberosPreAuthentication $user.SamAccountName
}

Add-UserSPN
{
    param (
        [Parameter(Mandatory = $true)]
        $User
        [Parameter(Mandatory = $true)]
        $SPN
    )

    Set-ADUser -Identity $User -ServicePrincipalNames @{Add=$SPN}
}


