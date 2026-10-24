<#
.SYNOPSIS
    Read-only inspection script for AWS VPC Peering Lab in ap-south-1 (Mumbai).
.DESCRIPTION
    Safely queries AWS identity, VPCs, subnets, route tables, peering connections,
    security groups, and EC2 instances. Does NOT create, modify, or delete any resources.
#>

[CmdletBinding()]
param (
    [string]$Region = "ap-south-1"
)

# 1. Resolve AWS CLI executable
$awsExe = Get-Command "aws" -ErrorAction SilentlyContinue
if (-not $awsExe) {
    $defaultPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    if (Test-Path $defaultPath) {
        $awsCmd = $defaultPath
    } else {
        Write-Error "AWS CLI not found in PATH or at '$defaultPath'. Please install or add to PATH."
        exit 1
    }
} else {
    $awsCmd = $awsExe.Source
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AWS VPC Peering Lab -- Read-Only Environment Inspection    " -ForegroundColor Cyan
Write-Host "   Target Region: $Region                                   " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 2. Check Caller Identity
Write-Host "[1/7] Checking AWS Caller Identity (sts:GetCallerIdentity)..." -ForegroundColor Yellow
$identityJson = & $awsCmd sts get-caller-identity --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Authentication check failed: $identityJson"
    exit 1
}
$identity = $identityJson | ConvertFrom-Json
Write-Host "Authenticated as:" -ForegroundColor Green
Write-Host "  Account: $($identity.Account)"
Write-Host "  Arn:     $($identity.Arn)"
Write-Host "  UserId:  $($identity.UserId)"

Write-Host ""
# 3. Check VPCs
Write-Host "[2/7] Inspecting VPCs in $Region..." -ForegroundColor Yellow
$vpcsRaw = & $awsCmd ec2 describe-vpcs --region $Region --output json | ConvertFrom-Json
$vpcs = foreach ($vpc in $vpcsRaw.Vpcs) {
    $nameTag = ($vpc.Tags | Where-Object { $_.Key -eq 'Name' }).Value
    [PSCustomObject]@{
        VpcId     = $vpc.VpcId
        CidrBlock = $vpc.CidrBlock
        Name      = $nameTag
        IsDefault = $vpc.IsDefault
        State     = $vpc.State
    }
}
$vpcs | Format-Table -AutoSize

Write-Host ""
# 4. Check Subnets
Write-Host "[3/7] Inspecting Subnets in $Region..." -ForegroundColor Yellow
$subnetsRaw = & $awsCmd ec2 describe-subnets --region $Region --output json | ConvertFrom-Json
$subnets = foreach ($sub in $subnetsRaw.Subnets) {
    $nameTag = ($sub.Tags | Where-Object { $_.Key -eq 'Name' }).Value
    [PSCustomObject]@{
        SubnetId         = $sub.SubnetId
        VpcId            = $sub.VpcId
        CidrBlock        = $sub.CidrBlock
        AZ               = $sub.AvailabilityZone
        AutoAssignPublic = $sub.MapPublicIpOnLaunch
        Name             = $nameTag
    }
}
$subnets | Sort-Object VpcId, CidrBlock | Format-Table -AutoSize

Write-Host ""
# 5. Check Internet Gateways
Write-Host "[4/7] Inspecting Internet Gateways in $Region..." -ForegroundColor Yellow
$igwsRaw = & $awsCmd ec2 describe-internet-gateways --region $Region --output json | ConvertFrom-Json
$igws = foreach ($igw in $igwsRaw.InternetGateways) {
    $nameTag = ($igw.Tags | Where-Object { $_.Key -eq 'Name' }).Value
    $attachedVpc = ($igw.Attachments | ForEach-Object { $_.VpcId }) -join ", "
    [PSCustomObject]@{
        InternetGatewayId = $igw.InternetGatewayId
        AttachedVpc       = $attachedVpc
        Name              = $nameTag
    }
}
$igws | Format-Table -AutoSize

Write-Host ""
# 6. Check VPC Peering Connections
Write-Host "[5/7] Inspecting VPC Peering Connections in $Region..." -ForegroundColor Yellow
$peeringsRaw = & $awsCmd ec2 describe-vpc-peering-connections --region $Region --output json | ConvertFrom-Json
$peerings = foreach ($pcx in $peeringsRaw.VpcPeeringConnections) {
    $nameTag = ($pcx.Tags | Where-Object { $_.Key -eq 'Name' }).Value
    [PSCustomObject]@{
        PeeringId     = $pcx.VpcPeeringConnectionId
        StatusCode    = $pcx.Status.Code
        StatusMessage = $pcx.Status.Message
        RequesterVpc  = $pcx.RequesterVpcInfo.VpcId
        RequesterCIDR = $pcx.RequesterVpcInfo.CidrBlock
        AccepterVpc   = $pcx.AccepterVpcInfo.VpcId
        AccepterCIDR  = $pcx.AccepterVpcInfo.CidrBlock
        Name          = $nameTag
    }
}
if ($peerings) {
    $peerings | Format-Table -AutoSize
} else {
    Write-Host "No VPC Peering Connections found." -ForegroundColor DarkYellow
}

Write-Host ""
# 7. Check Route Tables
Write-Host "[6/7] Inspecting Route Tables and Routes in $Region..." -ForegroundColor Yellow
$rtsRaw = & $awsCmd ec2 describe-route-tables --region $Region --output json | ConvertFrom-Json
foreach ($rt in $rtsRaw.RouteTables) {
    $nameTag = ($rt.Tags | Where-Object { $_.Key -eq 'Name' }).Value
    $assocSubnets = ($rt.Associations | Where-Object { $_.SubnetId } | ForEach-Object { $_.SubnetId }) -join ", "
    $isMain = ($rt.Associations | Where-Object { $_.Main -eq $true }) -ne $null
    Write-Host "Route Table: $($rt.RouteTableId) (Name: '$nameTag', VPC: $($rt.VpcId), Main: $isMain)" -ForegroundColor Cyan
    Write-Host "  Associated Subnets: $(if ($assocSubnets) { $assocSubnets } else { 'None (Main / Unassociated)' })"
    $routes = foreach ($r in $rt.Routes) {
        $target = if ($r.GatewayId) { $r.GatewayId } elseif ($r.VpcPeeringConnectionId) { $r.VpcPeeringConnectionId } elseif ($r.NatGatewayId) { $r.NatGatewayId } else { "Other" }
        [PSCustomObject]@{
            Destination = $r.DestinationCidrBlock
            Target      = $target
            State       = $r.State
        }
    }
    $routes | Format-Table -AutoSize | Out-String | Write-Host
}

Write-Host ""
# 8. Check Security Groups & Rules
Write-Host "[7/7] Inspecting Security Groups in $Region..." -ForegroundColor Yellow
$sgsRaw = & $awsCmd ec2 describe-security-groups --region $Region --output json | ConvertFrom-Json
foreach ($sg in $sgsRaw.SecurityGroups) {
    # Skip default VPC security groups unless relevant
    Write-Host "Security Group: $($sg.GroupId) ($($sg.GroupName)) - VPC: $($sg.VpcId)" -ForegroundColor Cyan
    Write-Host "  Description: $($sg.Description)"
    Write-Host "  Inbound Rules:"
    foreach ($rule in $sg.IpPermissions) {
        $protocol = $rule.IpProtocol
        $fromPort = $rule.FromPort
        $toPort = $rule.ToPort
        $ports = if ($protocol -eq "-1") { "ALL" } elseif ($fromPort -eq $toPort) { "$fromPort" } else { "$fromPort-$toPort" }
        $sources = ($rule.IpRanges | ForEach-Object { $_.CidrIp }) -join ", "
        if (-not $sources) {
            $sources = ($rule.UserIdGroupPairs | ForEach-Object { $_.GroupId }) -join ", "
        }
        Write-Host "    - Protocol: $protocol, Ports: $ports, Source: $sources"
    }
}

Write-Host ""
# 9. Check EC2 Instances
Write-Host "Inspecting EC2 Instances in $Region..." -ForegroundColor Yellow
$instRaw = & $awsCmd ec2 describe-instances --region $Region --output json | ConvertFrom-Json
$instances = foreach ($res in $instRaw.Reservations) {
    foreach ($ins in $res.Instances) {
        $nameTag = ($ins.Tags | Where-Object { $_.Key -eq 'Name' }).Value
        $secGroups = ($ins.SecurityGroups | ForEach-Object { "$($_.GroupName) ($($_.GroupId))" }) -join ", "
        [PSCustomObject]@{
            InstanceId = $ins.InstanceId
            Name       = $nameTag
            State      = $ins.State.Name
            PrivateIp  = $ins.PrivateIpAddress
            PublicIp   = $ins.PublicIpAddress
            VpcId      = $ins.VpcId
            SubnetId   = $ins.SubnetId
            KeyName    = $ins.KeyName
            SecGroups  = $secGroups
        }
    }
}
if ($instances) {
    $instances | Format-Table -AutoSize
} else {
    Write-Host "No EC2 instances found." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "=== End of Read-Only Inspection ===" -ForegroundColor Green
