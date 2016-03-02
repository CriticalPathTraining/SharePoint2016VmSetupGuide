# specify domain name for SSL certificate
$domain = "*.wingtip.com"

# create output directory to create SSL certificate file
$outputDirectory = "c:\Setup\"
New-Item $outputDirectory -ItemType Directory -Force -Confirm:$false | Out-Null

# create file name for SSL certificate file
$certFileName  =  $outputDirectory + "wildcard.wingtip.cer"

Write-Host 
Write-Host "Creating SSL certificate file..."

$makecert = $PSScriptRoot + "\makecert.exe"
& $makecert -r -pe -n "CN=$domain" -b 01/01/2016 -e 01/01/2026 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 $certFileName

$certificate = Import-Certificate -FilePath $certFileName -CertStoreLocation 'Cert:\LocalMachine\Root'
$certificate.FriendlyName = "Wingtip Wildcard SSL Certificate"

# Create SSL Binding on IIS Web site for Primary Web Application
$iis = new-object Microsoft.Web.Administration.ServerManager 
$site = $iis.Sites | where { $_.Name -eq 'Wingtip Primary Web Application'}
New-WebBinding -Name "Wingtip Primary Web Application" -Protocol "https" -Port 443 -IPAddress *
$iis.CommitChanges()

$iis = new-object Microsoft.Web.Administration.ServerManager 
$site = $iis.Sites | where { $_.Name -eq 'Wingtip Primary Web Application'}
$SslBinding = $site.Bindings[1]
$SslBinding.SetAttributeValue("CertificateHash", $certificate.Thumbprint)
$SslBinding.SetAttributeValue("CertificateStoreName", "My")
$iis.CommitChanges()

$certificateThumbprint = $certificate.Thumbprint 
New-Item -Path "IIS:\SslBindings\*!443!" -Thumbprint $certificateThumbprint 
