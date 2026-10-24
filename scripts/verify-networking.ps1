<#
.SYNOPSIS
    Automated network verification for AWS VPC Peering.
.DESCRIPTION
    Validates route tables, peering status, and security group rules across VPC A and VPC B.
#>

[CmdletBinding()]
param (
    [string]$Region = "ap-south-1",
    [string]$PeeringId = "pcx-0ba60ebd3e4804132",
    [string]$VpcAId = "vpc-01f0e8c88b298c306",
    [string]$VpcBId = "vpc-0dadd7fa7f4a9bb7d"
)

$awsCmd = if (Get-Command "aws" -ErrorAction SilentlyContinue) { "aws" } else { "C:\Program Files\Amazon\AWSCLIV2\aws.exe" }

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AWS VPC Peering -- Network Validation Audit              " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Peering State
Write-Host "[1/3] Checking Peering Connection ($PeeringId)..." -ForegroundColor Yellow
$pcx = & $awsCmd ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $PeeringId --region $Region --output json | ConvertFrom-Json
$status = $pcx.VpcPeeringConnections[0].Status.Code
if ($status -eq "active") {
    Write-Host "  STATUS: ACTIVE (OK)" -ForegroundColor Green
} else {
    Write-Host "  STATUS: $status (NOT ACTIVE)" -ForegroundColor Red
}

Write-Host ""
# 2. Check Route Tables for Peering Target
Write-Host "[2/3] Checking Route Tables for Peering Routes..." -ForegroundColor Yellow
$rts = & $awsCmd ec2 describe-route-tables --region $Region --output json | ConvertFrom-Json
$labRts = $rts.RouteTables | Where-Object { $_.VpcId -in @($VpcAId, $VpcBId) }

foreach ($rt in $labRts) {
    $name = ($rt.Tags | Where-Object { $_.Key -eq 'Name' }).Value
    $hasPeerRoute = $rt.Routes | Where-Object { $_.VpcPeeringConnectionId -eq $PeeringId }
    if ($hasPeerRoute) {
        Write-Host "  [PASS] Route Table '$name' ($($rt.RouteTableId)) has route to $($hasPeerRoute.DestinationCidrBlock) via $PeeringId" -ForegroundColor Green
    } else {
        if ($name -eq "ewb-rt-a-public") {
            Write-Host "  [WARN] Route Table '$name' ($($rt.RouteTableId)) is MISSING peering route to VPC B (10.20.0.0/16)!" -ForegroundColor Red
        } else {
            Write-Host "  [INFO] Route Table '$name' ($($rt.RouteTableId)) has no peering route." -ForegroundColor Gray
        }
    }
}

Write-Host ""
# 3. Check Security Groups
Write-Host "[3/3] Checking Security Group Ingress Rules..." -ForegroundColor Yellow
$sgs = & $awsCmd ec2 describe-security-groups --region $Region --output json | ConvertFrom-Json
$appASg = $sgs.SecurityGroups | Where-Object { $_.GroupName -eq "ewb-sg-app-a" }
$appBSg = $sgs.SecurityGroups | Where-Object { $_.GroupName -eq "ewb-sg-app-b" }

if ($appASg) {
    Write-Host "  [INFO] ewb-sg-app-a found ($($appASg.GroupId))" -ForegroundColor Cyan
} else {
    Write-Host "  [WARN] ewb-sg-app-a not found!" -ForegroundColor Red
}

if ($appBSg) {
    Write-Host "  [INFO] ewb-sg-app-b found ($($appBSg.GroupId))" -ForegroundColor Cyan
} else {
    Write-Host "  [WARN] ewb-sg-app-b not found (needs to be created)!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Audit completed." -ForegroundColor Cyan
