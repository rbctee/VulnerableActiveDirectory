function Get-KerberosPreAuthUsers
{
    $users = get-aduser -filter * -properties DoesNotRequirePreAuth
    $users | Where-Object
    {
        $_.DoesNotRequirePreAuth -eq "True" -and $_.Enabled -eq "True"
    }

    $users | select samaccountname, enabled, DoesNotRequirePreAuth
} 

function Get-KerberoastableUsers
{
    $users = Get-AdUser -Filter * -properties serviceprincipalnames
    $kerberoastable_users = $users | where {
        $_.serviceprincipalnames -ne $null
    }

    $kerberoastable_users | select samaccountname, enabled, serviceprincipalnames
}
