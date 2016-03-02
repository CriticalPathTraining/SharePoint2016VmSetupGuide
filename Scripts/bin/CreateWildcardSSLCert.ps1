

# specify domain name for SSL certificate
$domain = "*.wingtip.com"

# create output directory to create SSL certificate file
$outputDirectory = "c:\Certs\"
New-Item $outputDirectory -ItemType Directory -Force -Confirm:$false | Out-Null

# create file name for SSL certificate file
$certFileName  =  $outputDirectory + "wildcard.wingtip.cer"

$cert = New-SelfSignedCertificate -DnsName "*.wingtip.com", "*.wingtip.com" -CertStoreLocation "cert:\LocalMachine\My"

