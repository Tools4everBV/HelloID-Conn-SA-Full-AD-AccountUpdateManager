try {
    $userUPN = $formInput.selectedUser.UserPrincipalName
     
    if([String]::IsNullOrEmpty($userUPN) -eq $false){
        $selectedUser = Get-ADuser -Filter { UserPrincipalName -eq $userUPN } -Properties manager
        $currentManager = $selectedUser.Manager
    }
     
    $groups = $managerGroups | ConvertFrom-Json
    HID-Write-Status -Message "Getting managers from AD groups [$managerGroups]" -Event Information
     
     
    $allUsers = foreach($group in $groups) {
        Get-ADGroupMember -identity $group.name | Where-Object objectClass -eq "user"
    }
 
    $allUsersCount = @($allUsers).Count
    $allUsers = $allUsers | Sort-Object -Property name
     
    Hid-Write-Status -Message "Result count: $allUsersCount" -Event Information
    HID-Write-Summary -Message "Result count: $allUsersCount" -Event Information
      
    if($allUsersCount -gt 0){
        foreach($user in $allUsers){
            $adUser = Get-ADUser $user -properties SamAccountName,displayName,UserPrincipalName,Description,Department,Title,DistinguishedName
             
            $returnObject = @{
                SamAccountName = $adUser.SamAccountName;
                displayName = $adUser.displayName;
                UserPrincipalName = $adUser.UserPrincipalName;
                Description  =$adUser.Description;
                Department = $adUser.Department;
                Title = $adUser.Title;
                selected = ($adUser.DistinguishedName -eq $currentManager)
            }
             
            Hid-Add-TaskResult -ResultValue $returnObject
        }
    } else {
        Hid-Add-TaskResult -ResultValue []
    }
} catch {
    HID-Write-Status -Message "Error getting members for AD group [$groupName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error getting members for AD group [$groupName]." -Event Failed
     
    Hid-Add-TaskResult -ResultValue []
}
