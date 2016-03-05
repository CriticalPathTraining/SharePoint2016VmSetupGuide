$snapin = Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue -PassThru

# register workflow farm with SharePoint farm
Write-Host "Registering new workflow farm with SharePoint farm to support SharePoint 2016 workflows"
Register-SPWorkflowService –SPSite "http://wingtipserver" –WorkflowHostUri "http://wingtipserver:12291" –AllowOAuthHttp


Write-Host 
Read-Host -Prompt "Press ENTER to continue"