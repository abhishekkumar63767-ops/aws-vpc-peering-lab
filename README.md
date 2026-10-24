# AWS VPC Peering Lab — Production Architecture & Implementation

An enterprise-grade, reference-based implementation of private VPC Peering between two isolated Amazon Web Services Virtual Private Clouds in `ap-south-1` (Mumbai).

---

## 1. Architecture Overview

```
[ Operator Laptop ]
       │
       ▼ (SSH port 22 via Public IPv4)
[ ewb-bastion (VPC A Public Subnet) ]
       │
       ├─► (ProxyJump port 22) ──► [ ewb-app-a (VPC A Private Subnet) ]
       │                                  ▲
       │                                  │ (VPC Peering: pcx-0ba60ebd3e4804132)
       │                                  │ (Private ICMP / Workload Traffic)
       │                                  ▼
       └─► (ProxyJump port 22) ──► [ ewb-app-b (VPC B Private Subnet) ]
```

### Core Architecture Components:
- **VPC A (`10.10.0.0/16`)**:
  - `ewb-a-public` (`10.10.1.0/24`): Bastion host (`10.10.1.205`, Public: `3.108.184.138`) with IGW route `0.0.0.0/0`.
  - `ewb-a-private` (`10.10.2.0/24`): Application Server A (`10.10.2.186`), strictly isolated with no public IP.
- **VPC B (`10.20.0.0/16`)**:
  - `ewb-b-private` (`10.20.1.0/24`): Application Server B (`10.20.1.10`), strictly isolated with no public IP, no IGW, and no NAT gateway.
- **VPC Peering Connection (`pcx-0ba60ebd3e4804132`)**:
  - Connects VPC A &harr; VPC B with bidirectional private routes.

---

## 2. Directory Structure

```
aws-vpc-peering-lab/
├── references/
│   ├── README.md                          # References index
│   ├── EWB-Courses-AWS-VPC-Peering-*.pdf  # 14-page course workbook
│   ├── reference-summary.md               # Detailed specification extraction
│   └── reference-notes.md                 # Live AWS state mapping
├── terraform/
│   ├── versions.tf                        # Provider requirements
│   ├── providers.tf                       # AWS provider configuration & tags
│   ├── variables.tf                       # Input variables with live defaults
│   ├── data.tf                            # Data sources for existing AWS resources
│   ├── main.tf                            # Locals and common tags
│   ├── networking.tf                      # Missing peering routes
│   ├── security-groups.tf                 # App-B SG & App-A reverse ICMP rule
│   ├── compute.tf                         # App-B EC2 deployment
│   ├── outputs.tf                         # Private IPs and connection strings
│   └── terraform.tfvars.example           # Example variable definitions
├── scripts/
│   ├── verify-aws.ps1                     # Read-only AWS environment discovery
│   ├── verify-networking.ps1              # Network and route auditor
│   └── connectivity-test.ps1              # Interactive testing & SSH config generator
├── iam/
│   └── vpc-lab-user-policy.json           # Least-privilege IAM policy for vpc-lab-user
├── diagrams/
│   └── architecture.mmd                   # Mermaid architecture diagram
├── tests/
│   └── validation-plan.md                 # Acceptance test matrix & troubleshooting
├── .gitignore                             # Git ignore rules for state & keys
└── README.md                              # This file
```

---

## 3. Cost Implications & Warnings

- **EC2 Instances:** Three `t3.micro` instances. Free tier eligible (750 hours/month). If beyond free tier, ~$0.0104/hr in Mumbai. (Total for 2 hours: ~$0.06).
- **Public IPv4 Address:** One public IPv4 address on `ewb-bastion` ($0.005/hr &rarr; ~$0.01 for 2 hours).
- **NAT Gateways:** **$0.00** (This lab deliberately avoids NAT Gateways, saving $0.054/hr + data fees).
- **VPC Peering Data Transfer:** Traffic within the same AZ (`ap-south-1a`) is free. Inter-AZ traffic is $0.01/GB. Total lab traffic cost is less than $0.001.
- **Estimated Total Lab Cost:** Under **$0.05 USD**.

---

## 4. Execution Workflow

### Step 1: Read-Only Discovery
```powershell
powershell -ExecutionPolicy Bypass -File scripts\verify-aws.ps1
```

### Step 2: Configure SSH ProxyJump
Add the snippet from `scripts/connectivity-test.ps1` into `~/.ssh/config`. Ensure your private key `ewb-lab.pem` is protected:
```bash
chmod 400 ~/.ssh/ewb-lab.pem
```

### Step 3: Terraform Planning
```bash
cd terraform
terraform init
terraform plan
```

### Step 4: Verification Testing
Follow the test steps in [`tests/validation-plan.md`](./tests/validation-plan.md).

---

## 5. Safe Cleanup Instructions (Workbook Page 14)

When finished with the lab:
1. **Terminate EC2 Instances:**
   ```bash
   aws ec2 terminate-instances --instance-ids <app-b-id> <app-a-id> <bastion-id> --region ap-south-1
   ```
2. **Remove Peering & Route Dependencies:**
   - Delete routes pointing to `pcx-0ba60ebd3e4804132`.
   - Delete peering connection `pcx-0ba60ebd3e4804132`.
   - Delete security groups `ewb-sg-app-b`, `ewb-sg-app-a`, and `ewb-sg-bastion`.
3. **Remove Subnets & VPCs:**
   - Disassociate and delete custom route tables.
   - Delete subnets and detach `ewb-igw-a`.
   - Delete VPC A and VPC B.
