try {
    $userUPN = $datasource.selectedUser.UserPrincipalName
    
    $currentManager = ""
    if([String]::IsNullOrEmpty($userUPN) -eq $false){
        $selectedUser = Get-ADuser -Filter { UserPrincipalName -eq $userUPN } -Properties manager
        $currentManager = $selectedUser.Manager
    }
    
    $groups = $ADmanagerGroups | ConvertFrom-Json
    Write-information "Getting managers from AD groups $ADmanagerGroups"
    
    $allUsers = foreach($group in $groups) {
        Get-ADGroupMember -identity $group.name | Where objectClass -eq "user"
    }

    $allUsersCount = @($allUsers).Count
    $allUsers = $allUsers | Sort-Object -Property name    
    Write-information "Result count: $allUsersCount"
     
    if($allUsersCount -gt 0){
        foreach($user in $allUsers){
            $adUser = Get-ADUser $user -properties SamAccountName, displayName, UserPrincipalName, Description, Department, Title, DistinguishedName
            
            $returnObject = @{
                SamAccountName = $adUser.SamAccountName;
                displayName = $adUser.displayName;
                UserPrincipalName = $adUser.UserPrincipalName;
                Description  =$adUser.Description;
                Department = $adUser.Department;
                Title = $adUser.Title;
                selected = ($adUser.DistinguishedName -eq $currentManager)
            }
            
            Write-output $returnObject
        }
    } else {
        return
    }
} catch {
    Write-error "Error getting members for AD group [$groupName]. Error: $($_.Exception.Message)"    
    return
}
