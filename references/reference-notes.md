# AWS VPC Peering Reference Notes & Live State Mapping

## 1. Live Environment vs Workbook Mapping

| Parameter | Workbook Template | Current Live AWS Environment |
|---|---|---|
| **AWS Region** | `ap-south-1` (Mumbai) | `ap-south-1` (Mumbai) |
| **AWS Account ID** | — | `330468767674` |
| **VPC A** | `10.10.0.0/16` | `vpc-01f0e8c88b298c306` (`10.10.0.0/16`) |
| **VPC A Public Subnet** | `10.10.1.0/24` | `subnet-079ecdc7496f1439f` (`10.10.1.0/24`) in `ap-south-1a` |
| **VPC A Private Subnet** | `10.10.2.0/24` | `subnet-04cc52b263dd06181` (`10.10.2.0/24`) in `ap-south-1a` |
| **Internet Gateway** | `ewb-igw-a` | `igw-04f707b260424ff3f` |
| **VPC B** | `10.20.0.0/16` | `vpc-0dadd7fa7f4a9bb7d` (`10.20.0.0/16`) |
| **VPC B Private Subnet** | `10.20.1.0/24` | `subnet-096079b93661389dd` (`10.20.1.0/24`) in `ap-south-1a` |
| **VPC Peering Connection** | `ewb-a-b-peer` | `pcx-0ba60ebd3e4804132` (Active) |
| **Route Table: VPC A Public** | `ewb-rt-a-public` | `rtb-082ac9b3f915c55eb` |
| **Route Table: VPC A Private**| `ewb-rt-a-private` | `rtb-0364f1ca024c992ba` |
| **Route Table: VPC B Private**| `ewb-rt-b-private` | `rtb-0838b83693a33104f` |
| **Bastion Host** | `ewb-bastion` | `i-0efe401fe253ff969` (Private: `10.10.1.205`, Public: `3.108.184.138`) |
| **App-A Host** | `ewb-app-a` | `i-0c9986a2db068e68b` (Private: `10.10.2.186`, No Public IP) |
| **App-B Host** | `ewb-app-b` | Target: `subnet-096079b93661389dd`, AMI: `ami-088fb12f8e8397f06` |
| **Key Pair** | `ewb-lab` | `ewb-lab` |
| **Operator Public IP** | `/32` | `103.211.17.137/32` |

---

## 2. Critical Routing Logic Explained

### Why does Bastion's public route table need a route to VPC B?
When you run:
```bash
ssh ewb-app-b
```
OpenSSH on your laptop initiates an SSH connection to `ewb-bastion` on public IP `3.108.184.138:22`.  
Bastion acts as a proxy via `ProxyJump` and opens a new connection from its private IP `10.10.1.205` to App-B's private IP (`10.20.1.x`).  
If the subnet route table for `ewb-bastion` (`ewb-rt-a-public`) does not have an explicit route for `10.20.0.0/16` pointing to the peering connection `pcx-0ba60ebd3e4804132`, the packet matches the default route `0.0.0.0/0` &rarr; `ewb-igw-a` and gets dropped, failing the SSH proxy connection.
