#Remember to import Exchange Online module and connect.

#$Username = "MY_USERNAME"
#$Password = ConvertTo-SecureString -String "MY_PASSWORD" -AsPlainText -Force
#$UserCredential =New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $Username, $Password
#Connect-MsolService -credential $UserCredential

#Define $info array
#$info = @()

$clientId = <CLIENT ID>

# Calls the Active Directory Authentication Library (ADAL) to authenticate against AAD

function GetAuthToken
{
    $adal = "${env:ProgramFiles}\WindowsPowerShell\Modules\AzureRM.profile\5.3.2\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    
    $adalforms = "${env:ProgramFiles}\WindowsPowerShell\Modules\AzureRM.profile\5.3.2\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
 
    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null

    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $redirectUri = "https://oauth.powerbi.com/PBIAPIExplorer"

    $resourceAppIdURI = "https://analysis.windows.net/powerbi/api"

    $authority = "https://login.microsoftonline.com/common/oauth2/authorize";

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

    return $authResult
}

# Get the auth token from AAD
$token = GetAuthToken

# Building Rest API header with authorization token
$authHeader = @{
   'Content-Type'='application/json'
   'Authorization'=$token.CreateAuthorizationHeader()
}

#Lets get all Groups
$uri = "https://api.powerbi.com/v1.0/myorg/groups"
$groups = Invoke-RestMethod -Uri $uri -Headers $authHeader -Method GET -Verbose
#$groups.value

#Declare final Array
$PBIDatasets = @()

#Loop through Group info & add to new array

foreach($group in $groups.value)
{
    $groupID = $group.id
        
    $uri1 = "https://api.powerbi.com/v1.0/myorg/groups/$groupID/datasets"
    $datasets = Invoke-RestMethod -Uri $uri1 -Headers $authHeader -Method GET -Verbose

    foreach($dataset in $datasets.value)
    {
        $datasetID = $dataset.id
		
        $uri2 = "https://api.powerbi.com/v1.0/myorg/groups/$groupID/datasets/$datasetID/refreshes?$top=8"
        $refreshList = Invoke-RestMethod -Uri $uri2 -Headers $authHeader -Method GET -Verbose
			 
		   foreach($i in $refreshList.Value) 
		   {
           			  
		    $PBIDatasets += New-Object PsObject -Property @{
            GroupName=$group.name;
            GroupID=$group.id
            DatasetName=$dataset.name
            DatasetID=$dataset.id
	        RefreshID=$i.id
            DatasetOwner=$dataset.configuredBy
	        RefreshType=$i.refreshType
            RefreshStart=$i.startTime
            RefreshEnd=$i.endTime
            RefreshStatus=$i.status
            RefreshDetails=$i.serviceExceptionJson 
			
			}
		}
			
	    }
		 $datasets = $null
    }


$PBIDatasets 

$PBIDatasets | export-csv -Path  "\\\PowerShell_$((Get-Date).ToString('dd_MM_yyyy')).csv" -NoTypeInformation




