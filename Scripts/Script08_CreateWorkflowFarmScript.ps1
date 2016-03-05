$wfinstallpath = (Get-ItemProperty "HKLM:\Software\Microsoft\Workflow Manager\1.0" INSTALLDIR).INSTALLDIR
$wfinstallpath = $wfinstallpath.TrimEnd('\')

if ($SetDirectory){    
  Set-Location $wfinstallpath 
}

[Environment]::SetEnvironmentVariable("PSModulePath", [Environment]::GetEnvironmentVariable("PSModulePath","Machine"))
Import-Module WorkflowManager

# Create new SB Farm
Write-Host "Creating new service bus farm..."
$SBCertificateAutoGenerationKey = ConvertTo-SecureString -AsPlainText  -Force  -String 'Password1' -Verbose
New-SBFarm `
    -SBFarmDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ServiceBus_ManagementDB;Integrated Security=True;Encrypt=False' `
    -InternalPortRangeStart 9000 `
    -TcpPort 9354 `
    -MessageBrokerPort 9356 `
    -RunAsAccount 'WINGTIP\SP_Workflow' `
    -AdminGroup 'BUILTIN\Administrators' `
    -GatewayDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ServiceBus_GatewayDatabase;Integrated Security=True;Encrypt=False' `
    -CertificateAutoGenerationKey $SBCertificateAutoGenerationKey `
    -MessageContainerDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ServiceBus_MessageContainer;Integrated Security=True;Encrypt=False' | Out-Null

# Create new WF Farm
Write-Host "Creating new workflow manager farm..."
$WFCertAutoGenerationKey = ConvertTo-SecureString -AsPlainText  -Force  -String 'Password1' -Verbose
New-WFFarm `
    -WFFarmDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ManagementDB;Integrated Security=True;Encrypt=False' `
    -RunAsAccount 'WINGTIP\SP_Workflow' `
    -AdminGroup 'BUILTIN\Administrators' `
    -HttpsPort 12290 `
    -HttpPort 12291 `
    -InstanceDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_InstanceManagementDB;Integrated Security=True;Encrypt=False' `
    -ResourceDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ResourceManagementDB;Integrated Security=True;Encrypt=False' `
    -CertificateAutoGenerationKey $WFCertAutoGenerationKey

# Add SB Host
Write-Host "Creating new service bus host..."
$SBRunAsPassword = ConvertTo-SecureString -AsPlainText  -Force  -String 'Password1' -Verbose
Add-SBHost `
    -SBFarmDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ServiceBus_ManagementDB;Integrated Security=True;Encrypt=False' `
    -RunAsPassword $SBRunAsPassword `
    -EnableFirewallRules $true `
    -CertificateAutoGenerationKey $SBCertificateAutoGenerationKey    

try {
    # Create new SB Namespace
    New-SBNamespace `
        -Name 'WorkflowDefaultNamespace' `
        -AddressingScheme 'Path' `
        -ManageUsers 'WINGTIP\SP_Workflow','WINGTIP\Administrator'

    Start-Sleep -s 90
} catch [system.InvalidOperationException] { }

# Get SB Client Configuration
$SBClientConfiguration = Get-SBClientConfiguration -Namespaces 'WorkflowDefaultNamespace' -Verbose

# Add WF Host
Write-Host "Creating new workflow manager host..."
$WFRunAsPassword = ConvertTo-SecureString -AsPlainText  -Force  -String 'Password1' -Verbose;
Add-WFHost `
    -WFFarmDBConnectionString 'Data Source=WingtipServer\SharePoint;Initial Catalog=WF_ManagementDB;Integrated Security=True;Encrypt=False' `
    -RunAsPassword $WFRunAsPassword `
    -EnableFirewallRules $true `
    -SBClientConfiguration $SBClientConfiguration `
    -EnableHttpPort  `
    -CertificateAutoGenerationKey $WFCertAutoGenerationKey

Write-Host "Workflow manager setup complete"
Write-Host

Write-Host 
Write-Host "This script will end and this window will close in 10 seconds" -ForegroundColor Yellow
Write-Host 

Start-Sleep -Seconds 10