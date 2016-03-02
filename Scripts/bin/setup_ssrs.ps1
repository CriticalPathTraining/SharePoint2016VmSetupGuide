Add-PSSnapin Microsoft.SharePoint.PowerShell

Install-SPRSService

Install-SPRSServiceProxy

get-spserviceinstance -all | where {$_.TypeName -like "SQL Server Reporting*"} | Start-SPServiceInstance