<#
.SYNOPSIS
    Interactive connectivity test helper and SSH configuration generator.
.DESCRIPTION
    Generates local SSH config block and provides step-by-step connectivity test instructions.
#>

param (
    [string]$BastionPublicIp = "3.108.184.138",
    [string]$BastionPrivateIp = "10.10.1.205",
    [string]$AppAPrivateIp    = "10.10.2.186",
    [string]$AppBPrivateIp    = "10.20.1.10",
    [string]$KeyPath          = "~/.ssh/ewb-lab.pem"
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AWS VPC Peering -- Connectivity & Validation Plan        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$sshConfigBlock = @"
# --- EWB VPC Peering Lab SSH Configuration ---
Host ewb-bastion
    HostName $BastionPublicIp
    User ec2-user
    IdentityFile $KeyPath
    IdentitiesOnly yes

Host ewb-app-a
    HostName $AppAPrivateIp
    User ec2-user
    IdentityFile $KeyPath
    IdentitiesOnly yes
    ProxyJump ewb-bastion

Host ewb-app-b
    HostName $AppBPrivateIp
    User ec2-user
    IdentityFile $KeyPath
    IdentitiesOnly yes
    ProxyJump ewb-bastion
# ---------------------------------------------
"@

Write-Host "Recommended SSH Configuration (add to $HOME\.ssh\config):" -ForegroundColor Yellow
Write-Host $sshConfigBlock -ForegroundColor Green
Write-Host ""

Write-Host "Step-by-Step Test Commands:" -ForegroundColor Yellow
Write-Host "1. Test Bastion SSH from your laptop:" -ForegroundColor White
Write-Host "   ssh ewb-bastion" -ForegroundColor Cyan
Write-Host "   exit" -ForegroundColor DarkGray
Write-Host ""
Write-Host "2. Test App-A SSH from your laptop (ProxyJump):" -ForegroundColor White
Write-Host "   ssh ewb-app-a" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Run Baseline Test inside App-A (Page 8 of workbook):" -ForegroundColor White
Write-Host "   ping -c 4 $AppBPrivateIp" -ForegroundColor Cyan
Write-Host "   (Expected before peering routes: 100% packet loss / No replies)" -ForegroundColor DarkGray
Write-Host "   exit" -ForegroundColor DarkGray
Write-Host ""
Write-Host "4. Test App-B SSH from your laptop (ProxyJump):" -ForegroundColor White
Write-Host "   ssh ewb-app-b" -ForegroundColor Cyan
Write-Host ""
Write-Host "5. Forward Path Test (inside App-A):" -ForegroundColor White
Write-Host "   ping -c 4 $AppBPrivateIp" -ForegroundColor Cyan
Write-Host "   (Expected after peering: 4 replies, 0% packet loss)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "6. Reverse Path Test (inside App-B):" -ForegroundColor White
Write-Host "   ping -c 4 $AppAPrivateIp" -ForegroundColor Cyan
Write-Host "   (Expected: 4 replies, 0% packet loss)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "7. Controlled Failure Test (Workbook Page 11):" -ForegroundColor White
Write-Host "   - Remove inbound ICMP rule on App-B" -ForegroundColor DarkYellow
Write-Host "   - In App-A: ping -c 4 $AppBPrivateIp (Expect packet loss)" -ForegroundColor DarkYellow
Write-Host "   - Restore inbound ICMP rule on App-B" -ForegroundColor DarkYellow
Write-Host "   - In App-A: ping -c 4 $AppBPrivateIp (Expect 0% packet loss restored)" -ForegroundColor DarkYellow
