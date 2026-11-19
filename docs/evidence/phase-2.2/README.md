## Phase 2.2 - Network & Flow-Log Verification
This directory contains implementation evidence for the network controls established during Phase 2.2 of the Secure AWS Landing Zone.

The objective is to verify per-account VPCs built from a single module, a default-deny network interior, NAT egress controlled by a per-environment flag that rests off, and VPC flow logs delivered to a central bucket outside the workload accounts' control.

## Verification summary

| Control | Observed result |
| ------- | --------------- |
| VPC scope |  VPCs live in Dev (`10.0.0.0/16`) and Prod (`10.1.0.0/16`) only; Management, Log Archive, and Audit have none |
| Flow-log delivery | Log files present in the central Log Archive bucket under both workload-account prefixes |
| Authorized access test | SSH from the operator's home address to the public test instance recorded as ACCEPT |
| NACL deny test | RDP (3389) from the same source recorded as REJECT at the public-tier NACL |
| Tier isolation test | Public-to-private SSH recorded as ACCEPT on the source ENI and REJECT on the private instance's ENI |
| NAT egress, flag on (Prod) | A private instance's HTTPS request was answered with a NAT gateway's Elastic IP; ACCEPT records on both the instance ENI and the NAT gateway ENI |
| NAT negative control, flag off (Prod) | The same request timed out (`curl` exit 28;) private route tables hold no default route |
| Private-instances access | Login via EC2 Instance Connect Endpoint succeeded with client-IP preservation disabled; the endpoint was removed after the test |
| Resting state | `enable_nat_gateway = false` in both environments; test instances, endpoint, and test security groups removed |

## Evidence Index

### 1. Centralized flow-log delivery

| Evidence | Verification |
| -------- | ------------ |
| [Flow logs in the central bucket](./flow-logs-in-central-bucket.png) | Delivered `.log.gz` objects in the Log Archive account's bucket under Dev account prefix (`AWSLogs/102199089014/vpcflowlogs/ca-central-1/...`), written by the delivery service, not by the workload account |

Both VPCs log all traffic (ACCEPT and REJECT) at a 60-second aggregation interval to this bucket. The workload accounts hold no rights over the bucket, its policy, or its lifecycle configuration.

### 2. Dev gate tests

The three tests below were run against hand-built test instances in the Dev VPC. The instances were terminated after the tests; they were never part of the Terraform configuration.

| Evidence | Verification |
| -------- | ------------ |
| [Test 1 - home SSH accepted](./flow-log-test1-home-ssh-accept.txt) | Flow-log ACCEPT records for SSH (port 22) from the operator's home address to the public test instance(`10.0.0.230`) |
| [Test 2 - RDP rejected at the NACL](./flow-log-test2-rdp-nacl-reject.txt) | Flow-log REJECT records for port 3389 from the same address; the public NACL denies 3389 at rule 50, ahead of the ephemeral-range allow. Other sources in the raw logs are ambient internet scanning and are not part of the test |
| [Test 3 - client view](./flow-log-test3-public-to-private-ssh.txt) | The SSH client timing out: the private instance's security group dropped the SYN silently, so the client saw a timeout rather than a refusal |

**Test 3 attribution:** the private test instance had no purpose-built security group, so the console attached the VPC **default security group** - which the VPC module empties (no ingress, no egress). The REJECT is therefore credited to the module's default-deny control itself, not to a test-specific rule. This is recorded deliberately: an instance that does not choose a security group in this landing zone passes no traffic.

**Redaction:** the operator's home IP address is replaced with `<home-ip>` in the committed extracts (tests 1 and 2). The same placeholder is used in both files, so the same-source relationship between the accepted and rejected tests remains verifiable. Test 3 contains only private addresses and is unredacted.

### 3. Prod NAT proof

Prod received the same module and was additionally used for the functional NAT proof, because the Dev private test instance could not originate traffic (see the test 3 attribution above).

| Evidence | Verification |
| -------- | ------------ |
| [NAT gateways, flag on](./prod-nat-gateways-on.txt) | Three NAT gateways `available` in Prod with their Elastic IPs while `enable_nat_gateway = true` |
| [Egress answered by a NAT address](./prod-private-instance-nat-egress.png) | From the private instance (`10.1.11.189`): `checkip.amazonaws.com` answered with one of the NAT Elastic IPs above, and `example.com` returned HTTP 200 - the internet saw the NAT gateway, not the instance. |
| [Flow-log egress records](./prod-flow-log-egress-accept.txt) | ACCEPT records for the instance's port-443 egress on its own ENI (destination: the public server) and on the NAT gateway's ENI (destination shown as the NAT gateways's private address, `10.1.1.80` - the private-side leg terminates at the NAT), joinable by source port |
| [Negative control, flag off](./prod-curl-nat-off.png) | After the flag was returned to `false`, the same request timed out (`curl: (28)`, exit 28): DNS still resolved via the in-VPC resolver, but no default route existed for the connection itself |

No flow-log record exists for the negative control, and none is expected: a packet with no route is dropped before security-group or NACL evaluation, and flow-log verdicts are only produced by those layers. The terminal capture is the evidence for the off state.

### 4. Private-instance access prototype

| Evidence | Verification |
| -------- | ------------ |
| [Instance Connect Endpoint configuration](./prod-instance-connect-endpoint.txt) | The endpoint in the Prod VPC with its security group attached and `PreserveClientIp: false` |
| [Login to the private instance](./prod-eice-login-flow-log.txt) | ACCEPT records on the private instance's ENI for port 22, sourced from the endpoint ENI's private address, the fabric's witness of the `aws ec2-instance-connect ssh --connection-type eice` session. With  Client-IP preservation disabled, no public client address appears in the records. |

The endpoint was a test rig for validating bastionless private access (IAM-gated, no public IP, no dependence on NAT) and was deleted after the test. Adopting a standing access pattern is deferred to the first-workload phase; see ADR-0004.

## Security Decisions
* **Workload accounts only:** VPCs exist where workloads run; the security and management accounts have no network footprint.
* **Default-deny interior:** the default security group is emptied under module management, the main route table stays local-only, and each tier carries an explicit stateless NACL.
* **Egress is an enablement, not a default:** NAT gateways, Elastic IPs, and private default routes exist only while the per-environment flag is on; it rests off in both environments.
* **Logs live elsewhere:** flow logs are delivered to a bucket in the Log Archive account, which the generating accounts cannot modify or delete; writes are fenced by `aws:SourceAccount`.
* **Evidence hygiene:** the operator's home address is redacted in committed extracts; the Prod evidence set contains no public client address because the endpoint was used with client-IP preservation disabled.

The rationale for these decisions is documented in [ADR-0004](../../adr/0004-network-architecture.md)

**Result:** Phase 2.2 evidence demonstrates two module-built VPCs with a default-deny interior, flow logs delivered to and retained in a separate account, the phase gate's ACCEPT/REJECT records present in those delivered logs, and NAT egress proven functionally in both the on and off states.
