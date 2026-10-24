# EWB AWS VPC Peering Lab — Reference Summary

**Source Document:** [`references/EWB-Courses-AWS-VPC-Peering-Student-Project.pdf`](file:///c:/Users/abhis/OneDrive/Desktop/aws-vpc-peering-lab/references/EWB-Courses-AWS-VPC-Peering-Student-Project.pdf)  
**Edition:** Student Project Workbook (AWS Architect Associate — Project 01 / Oct 2026)  
**Document Length:** 14 Pages

---

## 1. Project Goal & Core Requirements

The objective is to establish private network connectivity between two isolated Virtual Private Clouds (**VPC A** and **VPC B**) using AWS VPC Peering, verifying that:
1. Workloads in private subnets across different VPCs can communicate directly using private IPv4 addresses.
2. No internet connectivity or NAT Gateways exist in VPC B.
3. The only internet-facing entry point is a single Bastion host in VPC A's public subnet.
4. Administrative access to private instances is performed strictly via SSH `ProxyJump` through the Bastion.
5. All security group rules follow least-privilege principles (/32 host-level scoping).

---

## 2. Architecture & Specification Matrix

| Component | Workbook Specification | User Environment / Actual | Workbook Source |
|---|---|---|---|
| **AWS Region** | Mumbai (`ap-south-1`) | `ap-south-1` | Page 2 |
| **VPC A Name & CIDR** | `ewb-vpc-a` (`10.10.0.0/16`) | `vpc-01f0e8c88b298c306` (`10.10.0.0/16`) | Page 4, 5 |
| **VPC A Public Subnet** | `ewb-a-public` (`10.10.1.0/24`) | `subnet-079ecdc7496f1439f` (`10.10.1.0/24`) | Page 4, 5 |
| **VPC A Private Subnet**| `ewb-a-private` (`10.10.2.0/24`) | `subnet-04cc52b263dd06181` (`10.10.2.0/24`) | Page 4, 5 |
| **VPC B Name & CIDR** | `ewb-vpc-b` (`10.20.0.0/16`) | `vpc-0dadd7fa7f4a9bb7d` (`10.20.0.0/16`) | Page 4, 6 |
| **VPC B Private Subnet**| `ewb-b-private` (`10.20.1.0/24`) | `subnet-096079b93661389dd` (`10.20.1.0/24`) | Page 4, 6 |
| **Internet Gateway** | `ewb-igw-a` attached to VPC A | Attached to VPC A | Page 4, 5 |
| **VPC Peering Connection** | `ewb-a-b-peer` (Active) | `pcx-0ba60ebd3e4804132` (Active) | Page 4, 9 |
| **Bastion Host** | `ewb-bastion` in `ewb-a-public` (Auto-assign Public IP) | `i-0efe401fe253ff969` (Private: `10.10.1.205`, Public: `3.108.184.138`) | Page 4, 7 |
| **App-A Host** | `ewb-app-a` in `ewb-a-private` (No Public IP) | `i-0c9986a2db068e68b` (Private: `10.10.2.186`) | Page 4, 7 |
| **App-B Host** | `ewb-app-b` in `ewb-b-private` (No Public IP) | Missing / To be verified & deployed | Page 4, 7 |
| **EC2 AMI & Family** | Amazon Linux 2023 (AL2023), `t3.micro` | AL2023, `t3.micro` | Page 7 |
| **Key Pair** | `ewb-lab` (RSA .pem, stored locally) | `ewb-lab` | Page 4, 7 |

> **Note on Private IPs:** The workbook suggests `10.10.1.10`, `10.10.2.10`, and `10.20.1.10` as static defaults, but explicitly clarifies on Page 4: *"If you choose AWS-assigned addresses instead, replace every instance IP and /32 security rule in this workbook with your actual values."*

---

## 3. Routing Table Specifications

### VPC A Public Route Table (`ewb-rt-a-public`)
- **Association:** `ewb-a-public`
- `10.10.0.0/16` -> `local` (VPC A internal communication)
- `0.0.0.0/0` -> `ewb-igw-a` (Internet access for Bastion)
- `10.20.0.0/16` -> `pcx-ID` (*Critical:* Allows Bastion to forward SSH connections to App-B in VPC B via `ProxyJump`)

### VPC A Private Route Table (`ewb-rt-a-private`)
- **Association:** `ewb-a-private`
- `10.10.0.0/16` -> `local`
- `10.20.0.0/16` -> `pcx-ID` (App-A traffic destined for VPC B)

### VPC B Private Route Table (`ewb-rt-b-private`)
- **Association:** `ewb-b-private`
- `10.20.0.0/16` -> `local`
- `10.10.0.0/16` -> `pcx-ID` (Return path back to VPC A for App-A and Bastion)

---

## 4. Security Group Specifications (Least Privilege)

| Security Group | Attached To | Inbound Rule | Protocol / Port | Source |
|---|---|---|---|---|
| `ewb-sg-bastion` | `ewb-bastion` | SSH | TCP 22 | Administrator Public IP (`/32`) |
| `ewb-sg-app-a` | `ewb-app-a` | SSH | TCP 22 | Bastion Private IP (`10.10.1.205/32`) |
| | | Echo Request | ICMP (Type 8, Code 0) | App-B Private IP (`/32`) |
| `ewb-sg-app-b` | `ewb-app-b` | SSH | TCP 22 | Bastion Private IP (`10.10.1.205/32`) |
| | | Echo Request | ICMP (Type 8, Code 0) | App-A Private IP (`10.10.2.186/32`) |

*Outbound:* All security groups retain the default stateful outbound allow-all rule.

---

## 5. Testing & Validation Workflow

1. **Baseline Failure (Page 8 & 11):**
   - Connect from laptop to `ewb-app-a` via Bastion `ProxyJump`.
   - Ping App-B (`ping -c 4 <App-B-IP>`). Expected: No replies / 100% loss (proves lack of reachability before peering routes).
2. **Forward Reachability (Page 11):**
   - After peering routes and App-B are online: `ping -c 4 <App-B-IP>`. Expected: 4 replies, 0% packet loss.
3. **Reverse Reachability (Page 11):**
   - Connect to `ewb-app-b` via `ssh ewb-app-b` (using Bastion `ProxyJump`).
   - Run `ping -c 4 <App-A-IP>`. Expected: 4 replies, 0% packet loss.
4. **Controlled Failure (Page 11):**
   - Temporarily remove the ICMP Echo Request inbound rule from App-B's security group.
   - Run `ping -c 4 <App-B-IP>` from App-A. Expected: Packet loss / timeout.
   - Restore the security group rule and re-test. Expected: 0% loss restored.
5. **Isolation Check (Page 11):**
   - Verify that neither `ewb-app-a` nor `ewb-app-b` has an allocated public IPv4 address.

---

## 6. Resource Tags & Cleanup Requirements

- **Mandatory Tags (Page 4):**
  - `Project = EWB-VPC-Peering`
  - `Student = <Your Name>`
- **Cleanup Sequence (Page 14):**
  1. Terminate EC2 instances (`ewb-bastion`, `ewb-app-a`, `ewb-app-b`) and delete attached EBS volumes.
  2. Delete peering routes and peering connection (`ewb-a-b-peer`).
  3. Delete security groups once ENIs detach.
  4. Disassociate and delete custom route tables and subnets.
  5. Detach and delete `ewb-igw-a`.
  6. Delete VPCs.
