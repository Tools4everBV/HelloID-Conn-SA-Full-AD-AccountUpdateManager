#HelloID variables
$script:PortalBaseUrl = "https://CUSTOMER.helloid.com"
$apiKey = "API_KEY"
$apiSecret = "API_SECRET"
$delegatedFormAccessGroupNames = @("Users", "HID_administrators")
$delegatedFormCategories = @("Active Directory", "User Management")

# Create authorization headers with HelloID API key
$pair = "$apiKey" + ":" + "$apiSecret"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$key = "Basic $base64"
$script:headers = @{"authorization" = $Key}
# Define specific endpoint URI
$script:PortalBaseUrl = $script:PortalBaseUrl.trim("/") + "/"
 
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }

    $host.UI.RawUI.ForegroundColor = $fc
}

function Invoke-HelloIDGlobalVariable {
    param(
        [parameter(Mandatory)][String]$Name,
        [parameter(Mandatory)][String][AllowEmptyString()]$Value,
        [parameter(Mandatory)][String]$Secret
    )

    try {
        $uri = ($script:PortalBaseUrl + "api/v1/automation/variables/named/$Name")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
    
        if ([string]::IsNullOrEmpty($response.automationVariableGuid)) {
            #Create Variable
            $body = @{
                name     = $Name;
                value    = $Value;
                secret   = $Secret;
                ItemType = 0;
            }    
            $body = ConvertTo-Json -InputObject $body
    
            $uri = ($script:PortalBaseUrl + "api/v1/automation/variable")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
            $variableGuid = $response.automationVariableGuid

            Write-ColorOutput Green "Variable '$Name' created: $variableGuid"
        } else {
            $variableGuid = $response.automationVariableGuid
            Write-ColorOutput Yellow "Variable '$Name' already exists: $variableGuid"
        }
    } catch {
        Write-ColorOutput Red "Variable '$Name', message: $_"
    }
}

function Invoke-HelloIDAutomationTask {
    param(
        [parameter(Mandatory)][String]$TaskName,
        [parameter(Mandatory)][String]$UseTemplate,
        [parameter(Mandatory)][String]$AutomationContainer,
        [parameter(Mandatory)][String][AllowEmptyString()]$Variables,
        [parameter(Mandatory)][String]$PowershellScript,
        [parameter()][String][AllowEmptyString()]$ObjectGuid,
        [parameter()][String][AllowEmptyString()]$ForceCreateTask,
        [parameter(Mandatory)][Ref]$returnObject
    )
    
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/automationtasks?search=$TaskName&container=$AutomationContainer")
        $responseRaw = (Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false) 
        $response = $responseRaw | Where-Object -filter {$_.name -eq $TaskName}
    
        if([string]::IsNullOrEmpty($response.automationTaskGuid) -or $ForceCreateTask -eq $true) {
            #Create Task

            $body = @{
                name                = $TaskName;
                useTemplate         = $UseTemplate;
                powerShellScript    = $PowershellScript;
                automationContainer = $AutomationContainer;
                objectGuid          = $ObjectGuid;
                variables           = [Object[]]($Variables | ConvertFrom-Json);
            }
            $body = ConvertTo-Json -InputObject $body
    
            $uri = ($script:PortalBaseUrl +"api/v1/automationtasks/powershell")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
            $taskGuid = $response.automationTaskGuid

            Write-ColorOutput Green "Powershell task '$TaskName' created: $taskGuid"  
        } else {
            #Get TaskGUID
            $taskGuid = $response.automationTaskGuid
            Write-ColorOutput Yellow "Powershell task '$TaskName' already exists: $taskGuid"
        }
    } catch {
        Write-ColorOutput Red "Powershell task '$TaskName', message: $_"
    }

    $returnObject.Value = $taskGuid
}

function Invoke-HelloIDDatasource {
    param(
        [parameter(Mandatory)][String]$DatasourceName,
        [parameter(Mandatory)][String]$DatasourceType,
        [parameter(Mandatory)][String][AllowEmptyString()]$DatasourceModel,
        [parameter()][String][AllowEmptyString()]$DatasourceStaticValue,
        [parameter()][String][AllowEmptyString()]$DatasourcePsScript,        
        [parameter()][String][AllowEmptyString()]$DatasourceInput,
        [parameter()][String][AllowEmptyString()]$AutomationTaskGuid,
        [parameter(Mandatory)][Ref]$returnObject
    )

    $datasourceTypeName = switch($DatasourceType) { 
        "1" { "Native data source"; break} 
        "2" { "Static data source"; break} 
        "3" { "Task data source"; break} 
        "4" { "Powershell data source"; break}
    }
    
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/datasource/named/$DatasourceName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
      
        if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
            #Create DataSource
            $body = @{
                name               = $DatasourceName;
                type               = $DatasourceType;
                model              = [Object[]]($DatasourceModel | ConvertFrom-Json);
                automationTaskGUID = $AutomationTaskGuid;
                value              = [Object[]]($DatasourceStaticValue | ConvertFrom-Json);
                script             = $DatasourcePsScript;
                input              = [Object[]]($DatasourceInput | ConvertFrom-Json);
            }
            $body = ConvertTo-Json -InputObject $body
      
            $uri = ($script:PortalBaseUrl +"api/v1/datasource")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
              
            $datasourceGuid = $response.dataSourceGUID
            Write-ColorOutput Green "$datasourceTypeName '$DatasourceName' created: $datasourceGuid"
        } else {
            #Get DatasourceGUID
            $datasourceGuid = $response.dataSourceGUID
            Write-ColorOutput Yellow "$datasourceTypeName '$DatasourceName' already exists: $datasourceGuid"
        }
    } catch {
      Write-ColorOutput Red "$datasourceTypeName '$DatasourceName', message: $_"
    }

    $returnObject.Value = $datasourceGuid
}

function Invoke-HelloIDDynamicForm {
    param(
        [parameter(Mandatory)][String]$FormName,
        [parameter(Mandatory)][String]$FormSchema,
        [parameter(Mandatory)][Ref]$returnObject
    )
    
    try {
        try {
            $uri = ($script:PortalBaseUrl +"api/v1/forms/$FormName")
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        } catch {
            $response = $null
        }
    
        if(([string]::IsNullOrEmpty($response.dynamicFormGUID)) -or ($response.isUpdated -eq $true)) {
            #Create Dynamic form
            $body = @{
                Name       = $FormName;
                FormSchema = [Object[]]($FormSchema | ConvertFrom-Json)
            }
            $body = ConvertTo-Json -InputObject $body -Depth 100
    
            $uri = ($script:PortalBaseUrl +"api/v1/forms")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
    
            $formGuid = $response.dynamicFormGUID
            Write-ColorOutput Green "Dynamic form '$formName' created: $formGuid"
        } else {
            $formGuid = $response.dynamicFormGUID
            Write-ColorOutput Yellow "Dynamic form '$FormName' already exists: $formGuid"
        }
    } catch {
        Write-ColorOutput Red "Dynamic form '$FormName', message: $_"
    }

    $returnObject.Value = $formGuid
}


function Invoke-HelloIDDelegatedForm {
    param(
        [parameter(Mandatory)][String]$DelegatedFormName,
        [parameter(Mandatory)][String]$DynamicFormGuid,
        [parameter()][String][AllowEmptyString()]$AccessGroups,
        [parameter()][String][AllowEmptyString()]$Categories,
        [parameter(Mandatory)][String]$UseFaIcon,
        [parameter()][String][AllowEmptyString()]$FaIcon,
        [parameter(Mandatory)][Ref]$returnObject
    )
    $delegatedFormCreated = $false
    
    try {
        try {
            $uri = ($script:PortalBaseUrl +"api/v1/delegatedforms/$DelegatedFormName")
            $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        } catch {
            $response = $null
        }
    
        if([string]::IsNullOrEmpty($response.delegatedFormGUID)) {
            #Create DelegatedForm
            $body = @{
                name            = $DelegatedFormName;
                dynamicFormGUID = $DynamicFormGuid;
                isEnabled       = "True";
                accessGroups    = [Object[]]($AccessGroups | ConvertFrom-Json);
                useFaIcon       = $UseFaIcon;
                faIcon          = $FaIcon;
            }    
            $body = ConvertTo-Json -InputObject $body
    
            $uri = ($script:PortalBaseUrl +"api/v1/delegatedforms")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
    
            $delegatedFormGuid = $response.delegatedFormGUID
            Write-ColorOutput Green "Delegated form '$DelegatedFormName' created: $delegatedFormGuid"
            $delegatedFormCreated = $true

            $bodyCategories = $Categories
            $uri = ($script:PortalBaseUrl +"api/v1/delegatedforms/$delegatedFormGuid/categories")
            $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $bodyCategories
            Write-ColorOutput Green "Delegated form '$DelegatedFormName' updated with categories"
        } else {
            #Get delegatedFormGUID
            $delegatedFormGuid = $response.delegatedFormGUID
            Write-ColorOutput Yellow "Delegated form '$DelegatedFormName' already exists: $delegatedFormGuid"
        }
    } catch {
        Write-ColorOutput Red "Delegated form '$DelegatedFormName', message: $_"
    }

    $returnObject.value.guid = $delegatedFormGuid
    $returnObject.value.created = $delegatedFormCreated
}
<# Begin: HelloID Global Variables #>
$tmpValue = @'
[{"name": "All Managers"},{"name": "manager_group2"}]
'@ 
$tmpName = @'
ADmanagerGroups
'@ 
Invoke-HelloIDGlobalVariable -Name $tmpName -Value $tmpValue -Secret "False" 
$tmpValue = @'
[{ "OU": "OU=Disabled Users,OU=HelloID Training,DC=veeken,DC=local"},{ "OU": "OU=Users,OU=HelloID Training,DC=veeken,DC=local"},{"OU": "OU=External,OU=HelloID Training,DC=veeken,DC=local"}]
'@ 
$tmpName = @'
ADusersSearchOU
'@ 
Invoke-HelloIDGlobalVariable -Name $tmpName -Value $tmpValue -Secret "False" 
<# End: HelloID Global Variables #>


<# Begin: HelloID Data sources #>
<# Begin: DataSource "AD-user-generate-table-attributes-basic" #>
$tmpPsScript = @'
try {
    $userPrincipalName = $dataSource.selectedUser.UserPrincipalName
    Write-Information "Searching AD user [$userPrincipalName]"
     
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties * | Select-Object displayname, samaccountname, userPrincipalName, mail, employeeID, Enabled
    Write-Information -Message "Finished searching AD user [$userPrincipalName]"
     
    foreach($tmp in $adUser.psObject.properties)
    {
        $returnObject = @{name=$tmp.Name; value=$tmp.value}
        Write-Output $returnObject
    }
     
    Write-Information "Finished retrieving AD user [$userPrincipalName] basic attributes"
} catch {
    Write-Error "Error retrieving AD user [$userPrincipalName] basic attributes. Error: $($_.Exception.Message)"
}
'@ 
$tmpModel = @'
[{"key":"value","type":0},{"key":"name","type":0}]
'@ 
$tmpInput = @'
[{"description":null,"translateDescription":false,"inputFieldType":1,"key":"selectedUser","type":0,"options":1}]
'@ 
$dataSourceGuid_1 = [PSCustomObject]@{} 
$dataSourceGuid_1_Name = @'
AD-user-generate-table-attributes-basic
'@ 
Invoke-HelloIDDatasource -DatasourceName $dataSourceGuid_1_Name -DatasourceType "4" -DatasourceInput $tmpInput -DatasourcePsScript $tmpPsScript -DatasourceModel $tmpModel -returnObject ([Ref]$dataSourceGuid_1) 
<# End: DataSource "AD-user-generate-table-attributes-basic" #>

<# Begin: DataSource "AD-user-generate-table-managers" #>
$tmpPsScript = @'
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
'@ 
$tmpModel = @'
[{"key":"SamAccountName","type":0},{"key":"Title","type":0},{"key":"Description","type":0},{"key":"Department","type":0},{"key":"displayName","type":0},{"key":"UserPrincipalName","type":0},{"key":"selected","type":0}]
'@ 
$tmpInput = @'
[{"description":null,"translateDescription":false,"inputFieldType":1,"key":"selectedUser","type":0,"options":1}]
'@ 
$dataSourceGuid_2 = [PSCustomObject]@{} 
$dataSourceGuid_2_Name = @'
AD-user-generate-table-managers
'@ 
Invoke-HelloIDDatasource -DatasourceName $dataSourceGuid_2_Name -DatasourceType "4" -DatasourceInput $tmpInput -DatasourcePsScript $tmpPsScript -DatasourceModel $tmpModel -returnObject ([Ref]$dataSourceGuid_2) 
<# End: DataSource "AD-user-generate-table-managers" #>

<# Begin: DataSource "AD-user-generate-table-wildcard" #>
$tmpPsScript = @'
try {
    $searchValue = $dataSource.searchUser
    $searchQuery = "*$searchValue*"
    $searchOUs = $ADusersSearchOU
     
     
    if([String]::IsNullOrEmpty($searchValue) -eq $true){
        return
    }else{
        Write-Information "SearchQuery: $searchQuery"
        Write-Information "SearchBase: $searchOUs"
         
        $ous = $searchOUs | ConvertFrom-Json
        $users = foreach($item in $ous) {
            Get-ADUser -Filter {Name -like $searchQuery -or DisplayName -like $searchQuery -or userPrincipalName -like $searchQuery -or mail -like $searchQuery} -SearchBase $item.ou -properties SamAccountName, displayName, UserPrincipalName, Description, company, Department, Title
        }
         
        $users = $users | Sort-Object -Property DisplayName
        $resultCount = @($users).Count
        Write-Information "Result count: $resultCount"
         
        if($resultCount -gt 0){
            foreach($user in $users){
                $returnObject = @{SamAccountName=$user.SamAccountName; displayName=$user.displayName; UserPrincipalName=$user.UserPrincipalName; Description=$user.Description; Company=$user.company; Department=$user.Department; Title=$user.Title;}
                Write-Output $returnObject
            }
        }
    }
} catch {
    $msg = "Error searching AD user [$searchValue]. Error: $($_.Exception.Message)"
    Write-Error $msg
}
'@ 
$tmpModel = @'
[{"key":"Description","type":0},{"key":"SamAccountName","type":0},{"key":"Title","type":0},{"key":"Company","type":0},{"key":"Department","type":0},{"key":"displayName","type":0},{"key":"UserPrincipalName","type":0}]
'@ 
$tmpInput = @'
[{"description":null,"translateDescription":false,"inputFieldType":1,"key":"searchUser","type":0,"options":1}]
'@ 
$dataSourceGuid_0 = [PSCustomObject]@{} 
$dataSourceGuid_0_Name = @'
AD-user-generate-table-wildcard
'@ 
Invoke-HelloIDDatasource -DatasourceName $dataSourceGuid_0_Name -DatasourceType "4" -DatasourceInput $tmpInput -DatasourcePsScript $tmpPsScript -DatasourceModel $tmpModel -returnObject ([Ref]$dataSourceGuid_0) 
<# End: DataSource "AD-user-generate-table-wildcard" #>
<# End: HelloID Data sources #>

<# Begin: Dynamic Form "AD Account - Update manager" #>
$tmpSchema = @"
[{"label":"Select user account","fields":[{"key":"searchfield","templateOptions":{"label":"Search","placeholder":"Username or email address"},"type":"input","summaryVisibility":"Hide element","requiresTemplateOptions":true},{"key":"gridUsers","templateOptions":{"label":"Select user account","required":true,"grid":{"columns":[{"headerName":"DisplayName","field":"displayName"},{"headerName":"UserPrincipalName","field":"UserPrincipalName"},{"headerName":"Department","field":"Department"},{"headerName":"Title","field":"Title"},{"headerName":"Description","field":"Description"}],"height":300,"rowSelection":"single"},"dataSourceConfig":{"dataSourceGuid":"$dataSourceGuid_0","input":{"propertyInputs":[{"propertyName":"searchUser","otherFieldValue":{"otherFieldKey":"searchfield"}}]}},"useFilter":false},"type":"grid","summaryVisibility":"Show","requiresTemplateOptions":true}]},{"label":"Update manager","fields":[{"key":"gridDetails","templateOptions":{"label":"Basic attributes","required":false,"grid":{"columns":[{"headerName":"Name","field":"name"},{"headerName":"Value","field":"value"}],"height":350,"rowSelection":"single"},"dataSourceConfig":{"dataSourceGuid":"$dataSourceGuid_1","input":{"propertyInputs":[{"propertyName":"selectedUser","otherFieldValue":{"otherFieldKey":"gridUsers"}}]}},"useFilter":false},"type":"grid","summaryVisibility":"Hide element","requiresTemplateOptions":true},{"key":"managerSelected","templateOptions":{"label":"Select new manager","required":true,"grid":{"columns":[{"headerName":"DisplayName","field":"displayName"},{"headerName":"UserPrincipalName","field":"UserPrincipalName"},{"headerName":"Department","field":"Department"},{"headerName":"Title","field":"Title"},{"headerName":"Description","field":"Description"}],"height":300,"rowSelection":"single"},"dataSourceConfig":{"dataSourceGuid":"$dataSourceGuid_2","input":{"propertyInputs":[{"propertyName":"selectedUser","otherFieldValue":{"otherFieldKey":"gridUsers"}}]}},"useFilter":true,"useDefault":true,"defaultSelectorProperty":"selected"},"type":"grid","summaryVisibility":"Show","requiresTemplateOptions":true}]}]
"@ 

$dynamicFormGuid = [PSCustomObject]@{} 
$dynamicFormName = @'
AD Account - Update manager
'@ 
Invoke-HelloIDDynamicForm -FormName $dynamicFormName -FormSchema $tmpSchema  -returnObject ([Ref]$dynamicFormGuid) 
<# END: Dynamic Form #>

<# Begin: Delegated Form Access Groups and Categories #>
$delegatedFormAccessGroupGuids = @()
foreach($group in $delegatedFormAccessGroupNames) {
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/groups/$group")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        $delegatedFormAccessGroupGuid = $response.groupGuid
        $delegatedFormAccessGroupGuids += $delegatedFormAccessGroupGuid
        
        Write-ColorOutput Green "HelloID (access)group '$group' successfully found: $delegatedFormAccessGroupGuid"
    } catch {
        Write-ColorOutput Red "HelloID (access)group '$group', message: $_"
    }
}
$delegatedFormAccessGroupGuids = (ConvertTo-Json -InputObject $delegatedFormAccessGroupGuids -Compress)

$delegatedFormCategoryGuids = @()
foreach($category in $delegatedFormCategories) {
    try {
        $uri = ($script:PortalBaseUrl +"api/v1/delegatedformcategories/$category")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false
        $tmpGuid = $response.delegatedFormCategoryGuid
        $delegatedFormCategoryGuids += $tmpGuid
        
        Write-ColorOutput Green "HelloID Delegated Form category '$category' successfully found: $tmpGuid"
    } catch {
        Write-ColorOutput Yellow "HelloID Delegated Form category '$category' not found"
        $body = @{
            name = @{"en" = $category};
        }
        $body = ConvertTo-Json -InputObject $body

        $uri = ($script:PortalBaseUrl +"api/v1/delegatedformcategories")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $script:headers -ContentType "application/json" -Verbose:$false -Body $body
        $tmpGuid = $response.delegatedFormCategoryGuid
        $delegatedFormCategoryGuids += $tmpGuid

        Write-ColorOutput Green "HelloID Delegated Form category '$category' successfully created: $tmpGuid"
    }
}
$delegatedFormCategoryGuids = (ConvertTo-Json -InputObject $delegatedFormCategoryGuids -Compress)
<# End: Delegated Form Access Groups and Categories #>

<# Begin: Delegated Form #>
$delegatedFormRef = [PSCustomObject]@{guid = $null; created = $null} 
$delegatedFormName = @'
AD Account - Update manager
'@
Invoke-HelloIDDelegatedForm -DelegatedFormName $delegatedFormName -DynamicFormGuid $dynamicFormGuid -AccessGroups $delegatedFormAccessGroupGuids -Categories $delegatedFormCategoryGuids -UseFaIcon "True" -FaIcon "fa fa-user-secret" -returnObject ([Ref]$delegatedFormRef) 
<# End: Delegated Form #>

<# Begin: Delegated Form Task #>
if($delegatedFormRef.created -eq $true) { 
	$tmpScript = @'
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
'@; 

	$tmpVariables = @'
[{"name":"userPrincipalName","value":"{{form.gridUsers.UserPrincipalName}}","secret":false,"typeConstraint":"string"},{"name":"userPrincipalNameManager","value":"{{form.managerSelected.UserPrincipalName}}","secret":false,"typeConstraint":"string"}]
'@ 

	$delegatedFormTaskGuid = [PSCustomObject]@{} 
$delegatedFormTaskName = @'
AD-user-update-manager
'@
	Invoke-HelloIDAutomationTask -TaskName $delegatedFormTaskName -UseTemplate "False" -AutomationContainer "8" -Variables $tmpVariables -PowershellScript $tmpScript -ObjectGuid $delegatedFormRef.guid -ForceCreateTask $true -returnObject ([Ref]$delegatedFormTaskGuid) 
} else {
	Write-ColorOutput Yellow "Delegated form '$delegatedFormName' already exists. Nothing to do with the Delegated Form task..." 
}
<# End: Delegated Form Task #>
