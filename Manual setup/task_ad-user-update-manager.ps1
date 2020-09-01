try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName }
    HID-Write-Status -Message "Found AD user [$userPrincipalName]" -Event Information
    HID-Write-Summary -Message "Found AD user [$userPrincipalName]" -Event Information
} catch {
    HID-Write-Status -Message "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to find AD user [$userPrincipalName]" -Event Failed
}
 
try {
    $adManager = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalNameManager }
    HID-Write-Status -Message "Found AD Manager user [$userPrincipalNameManager]" -Event Information
    HID-Write-Summary -Message "Found AD Manager user [$userPrincipalNameManager]" -Event Information
} catch {
    HID-Write-Status -Message "Could not find AD Manager user [$userPrincipalNameManager]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to find AD Manager user [$userPrincipalNameManager]" -Event Failed
}
 
try {
    if([String]::IsNullOrEmpty($userPrincipalNameManager) -eq $true) {
        Set-ADUser -Identity $adUser -manager $null
    } else {
        Set-ADUser -Identity $adUser -manager $adManager
    }
     
    HID-Write-Status -Message "Finished update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]" -Event Success
    HID-Write-Summary -Message "Successfully updated attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]" -Event Success
} catch {
    HID-Write-Status -Message "Could not update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to update attribute [manager] of AD user [$userPrincipalName] to [$userPrincipalNameManager]" -Event Failed
}