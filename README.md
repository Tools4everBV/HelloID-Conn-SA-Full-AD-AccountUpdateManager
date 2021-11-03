<!-- Description -->
## Description
This HelloID Service Automation Delegated Form provides AD user account update manager functionality. The following options are available:
 1. Search and select the target AD user account
 2. Show basic AD user account attributes of selected target user
 3. Select a new manager. The current manager is default selected
 5. AD user account attribute manager is updated with new value


## Versioning
| Version | Description | Date |
| - | - | - |
| 1.0.1   | Added version number and updated all-in-one script | 2021/11/03  |
| 1.0.0   | Initial release | 2020/09/01  |

<!-- TABLE OF CONTENTS -->
## Table of Contents
* [Description](#description)
* [All-in-one PowerShell setup script](#all-in-one-powershell-setup-script)
  * [Getting started](#getting-started)
* [Post-setup configuration](#post-setup-configuration)
* [Manual resources](#manual-resources)
* [Getting help](#getting-help)


## All-in-one PowerShell setup script
The PowerShell script "createform.ps1" contains a complete PowerShell script using the HelloID API to create the complete Form including user defined variables, tasks and data sources.

 _Please note that this script asumes none of the required resources do exists within HelloID. The script does not contain versioning or source control_


### Getting started
Please follow the documentation steps on [HelloID Docs](https://docs.helloid.com/hc/en-us/articles/360017556559-Service-automation-GitHub-resources) in order to setup and run the All-in one Powershell Script in your own environment.

 
## Post-setup configuration
After the all-in-one PowerShell script has run and created all the required resources. The following items need to be configured according to your own environment
 1. Update the following [user defined variables](https://docs.helloid.com/hc/en-us/articles/360014169933-How-to-Create-and-Manage-User-Defined-Variables)
<table>
  <tr><td><strong>Variable name</strong></td><td><strong>Example value</strong></td><td><strong>Description</strong></td></tr>
  <tr><td>ADusersSearchOU</td><td>[{ "OU": "OU=Disabled Users,OU=HelloID Training,DC=veeken,DC=local"},{ "OU": "OU=Users,OU=HelloID Training,DC=veeken,DC=local"},{"OU": "OU=External,OU=HelloID Training,DC=veeken,DC=local"}]</td><td>Array of Active Directory OUs for scoping AD user accounts in the search result of this form</td></tr>
  <tr><td>ADmanagerGroups</td><td>[{"name": "All Managers"},{"name": "manager_group2"}]</td><td>Array of Active Directory groups to specify manager AD user accounts</td></tr>
</table>

## Manual resources
This Delegated Form uses the following resources in order to run

### Powershell data source 'AD-user-generate-table-wildcard-update-manager'
This Powershell data source runs an Active Directory query to search for matching AD user accounts. It uses an array of Active Directory OU's specified as HelloID user defined variable named _"ADusersSearchOU"_ to specify the search scope.

### Powershell data source 'AD-user-generate-table-attributes-basic-update-manager'
This Powershell data source runs an Active Directory query to select a basic list of user attributes of the selected AD user account.  

### Powershell data source 'AD-user-generate-table-managers-update-manager'
This Powershell data source runs an Active Directory query to select all members of specified AD groups. It uses an array of Active Directory groups specified as HelloID user defined variable named _"ADmanagerGroups"_ to specify the search scope.

### Delegated form task 'AD-user-update-manager'
This delegated form task will update the account attribute manager with the selected manager. 

## Getting help
_If you need help, feel free to ask questions on our [forum](https://forum.helloid.com/forum/helloid-connectors/service-automation/509-helloid-sa-active-directory-ad-account-update-manager)_

## HelloID Docs
The official HelloID documentation can be found at: https://docs.helloid.com/