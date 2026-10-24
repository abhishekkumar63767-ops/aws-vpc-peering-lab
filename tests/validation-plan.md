# Validation & Testing Plan — AWS VPC Peering Lab

This plan defines the acceptance criteria and step-by-step procedures to validate private connectivity, route tables, and security groups in accordance with the EWB Workbook (Pages 11-12).

---

## 1. Test Matrix & Acceptance Criteria

| Test ID | Objective | Execution Location | Exact Command | Expected Result | Pass / Fail |
|---|---|---|---|---|---|
| **TEST-01** | **Isolation Verification** | Local Terminal | `aws ec2 describe-instances --instance-ids <app-a-id> <app-b-id>` | Public IPv4 is null/empty for both App-A and App-B | [ ] |
| **TEST-02** | **Bastion SSH** | Local Terminal | `ssh ewb-bastion` | Successful shell on Bastion | [ ] |
| **TEST-03** | **App-A SSH via ProxyJump** | Local Terminal | `ssh ewb-app-a` | Successful shell on App-A without public IP | [ ] |
| **TEST-04** | **Baseline Ping Failure** | App-A Shell | `ping -c 4 10.20.1.10` *(before peer route)* | 0 replies, 100% packet loss | [ ] |
| **TEST-05** | **App-B SSH via ProxyJump** | Local Terminal | `ssh ewb-app-b` | Successful shell on App-B via Bastion | [ ] |
| **TEST-06** | **Forward Ping Reachability** | App-A Shell | `ping -c 4 10.20.1.10` | 4 replies, 0% packet loss | [ ] |
| **TEST-07** | **Reverse Ping Reachability** | App-B Shell | `ping -c 4 10.10.2.186` | 4 replies, 0% packet loss | [ ] |
| **TEST-08** | **Controlled Failure** | Local + App-A Shell | Remove ICMP rule from App-B SG & run `ping -c 4 10.20.1.10` | Packet loss / timeout | [ ] |
| **TEST-09** | **Recovery Verification** | Local + App-A Shell | Restore ICMP rule & re-run `ping -c 4 10.20.1.10` | 4 replies, 0% packet loss | [ ] |

---

## 2. Troubleshooting Guide (Workbook Page 12)

### A. Bastion SSH Times Out
* Check that your current public IP matches the `/32` CIDR in `ewb-sg-bastion`.
* Check that `ewb-rt-a-public` has route `0.0.0.0/0` &rarr; `ewb-igw-a`.
* Verify the Bastion has a public IPv4 assigned.

### B. App-A SSH Fails
* Verify `ewb-sg-app-a` allows inbound TCP 22 from Bastion private IP `10.10.1.205/32`.
* Verify you are using the correct `.pem` key file and username `ec2-user`.

### C. App-B SSH Fails
* **Crucial:** Verify `ewb-rt-a-public` has route `10.20.0.0/16` &rarr; `pcx-0ba60ebd3e4804132`.
* Verify `ewb-rt-b-private` has return route `10.10.0.0/16` &rarr; `pcx-0ba60ebd3e4804132`.
* Verify `ewb-sg-app-b` allows TCP 22 from Bastion private IP `10.10.1.205/32`.

### D. Ping Fails Between App-A and App-B
* A failed ping alone does **not** prove peering is broken: security groups block ICMP by default.
* Ensure Inbound ICMP Echo Request (Type 8, Code 0) is permitted from the peer's private IP on both instances' security groups.
* Verify both private route tables have active peering routes for the opposing VPC CIDR.
