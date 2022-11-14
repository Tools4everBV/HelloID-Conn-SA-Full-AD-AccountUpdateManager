$userPrincipalName = $form.gridUsers.UserPrincipalName
$userPrincipalNameManager = $form.managerSelected.UserPrincipalName

try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName }
    Write-Information "Found AD user [$userPrincipalName]"
    $adUserSID = $([string]$adUser.SID)
}
catch {
    Write-Error "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)"
}

try {
    $adManager = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalNameManager }
    Write-Information "Found AD Manager user [$userPrincipalNameManager]"
}
catch {
    Write-Error "Could not find AD Manager user [$userPrincipalNameManager]. Error: $($_.Exception.Message)"
}

try {
    if ([String]::IsNullOrEmpty($userPrincipalNameManager) -eq $true) {
        Set-ADUser -Identity $adUser -manager $null
    }
    else {
        Set-ADUser -Identity $adUser -manager $adManager
    }
     
    Write-Information "Finished update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]"
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "ActiveDirectory" # optional (free format text) 
        Message           = "Finished update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $userPrincipalName # optional (free format text) 
        TargetIdentifier  = $adUserSID # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}
catch {
    Write-Error -Message "Could not update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]. Error: $($_.Exception.Message)"
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "ActiveDirectory" # optional (free format text) 
        Message           = "Could not update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]. Error: $($_.Exception.Message)" # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $userPrincipalName # optional (free format text) 
        TargetIdentifier  = $adUserSID # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log
}
