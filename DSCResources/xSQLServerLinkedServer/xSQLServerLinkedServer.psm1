$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Verbose -Message "CurrentPath: $currentPath"

# Load Common Code
Import-Module $currentPath\..\..\xSQLServerHelper.psm1 -Verbose:$false -ErrorAction Stop

# DSC resource to manage SQL database roles

# NOTE: This resource requires WMF5 and PsDscRunAsCredential

Function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $ServerName,
              
        [parameter(Mandatory = $true)]
        [System.String]
        $RemoteServer,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $LinkedServerName,

        [parameter(Mandatory = $false)]
        [System.String]
        $LinkedServerCatalog,

		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

	
	$serverCollection = $ServerName.split('\')
   # checking for connectivity is built in to this  
   $SQL =  Connect-SQL -SQLServer $serverCollection[0] -SQLInstanceName $serverCollection[1]
   
   $linkedServers = $SQL.LinkedServers

   $linkedServers

   #todo: is this the best way to handle this 
   $SQL.ConnectionContext.Disconnect()
}

Function Set-TargetResource
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $ServerName,
       
        [parameter(Mandatory = $true)]
        [System.String]
        $RemoteServer,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $LinkedServerName,

        [parameter(Mandatory = $false)]
        [System.String]
        $LinkedServerCatalog,

		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

   # this is only necessary in this function so we can use the linked server thingy
   $null = [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')

   $serverCollection = $ServerName.split('\')
   
   $SQL =  Connect-SQL -SQLServer $serverCollection[0] -SQLInstanceName $serverCollection[1]
   
   if( $SQL.linkedServers.Contains("$LinkedServerName") )
   {
        if($ensure)
        {
            # nothing to do
        }
        else
        {
            # delete the linked server 
            $serverToDelete = @($SQL.LinkedServers | Where-Object {$_.name -eq $LinkedServerName }) | select -First 1
            $serverToDelete.drop($true)
        }
   }
   else
   {
        if($ensure)
        {
            $newLinkedServer = New-Object Microsoft.SqlServer.Management.Smo.LinkedServer
            $newLinkedServer.Parent = $SQL
            $newLinkedServer.Name = $RemoteServerFullname
            $newLinkedServer.DataSource = $RemoteServerFullname
            $newLinkedServer.Create()
        }
        else
        {
            # nothing to do 
        }
   }

   $SQL.ConnectionContext.Disconnect()

   $result

    
}

Function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [parameter(Mandatory = $true)]
        [System.String]
        $ServerName,
       
        [parameter(Mandatory = $true)]
        [System.String]
        $RemoteServer,
        
        [parameter(Mandatory = $true)]
        [System.String]
        $LinkedServerName,

        [parameter(Mandatory = $false)]
        [System.String]
        $LinkedServerCatalog,

		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

   $serverCollection = $ServerName.split('\')
   
   $SQL =  Connect-SQL -SQLServer $serverCollection[0] -SQLInstanceName $serverCollection[1]
   
   $linkedServers = $SQL.LinkedServers

   if( $linkedServers.Contains("$LinkedServerName") )
   {
        if($Ensure -eq 'present')
        {
            $result = $true
        }
        else
        {
            $result = $false
        }
   }
   else
   {
        if($Ensure -eq 'present')
        {
            $result = $false
        }
        else
        {

            $result = $true
        }
   }

   $SQL.ConnectionContext.Disconnect()

   $result
}


Export-ModuleMember -Function *-TargetResource