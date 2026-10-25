# RHEL High-Availability Cluster Design Notes

## Purpose

These sanitized notes record the reasoning and safeguards behind the reference Pacemaker and Corosync cluster. They do not represent production deployment evidence.

## Core Design Decisions

- Use three voting nodes to retain majority quorum after one node failure.
- Set `no-quorum-policy=stop` to prevent a minority partition from running workloads.
- Require STONITH for production use.
- Keep fence credentials and `hacluster` credentials outside Git.
- Install packages one node at a time with `throttle: 1`.
- Run cluster-wide PCS commands once from the designated bootstrap node.
- Back up PCS configuration before cluster changes.
- Require complete cluster membership for deployment and rollback.

## Component Responsibilities

- Corosync provides communication, membership and quorum information.
- Pacemaker manages resources, recovery, placement and constraints.
- PCS provides the administrative interface.
- Fence agents isolate unsafe nodes through an independent control path.

Quorum and fencing solve different problems. Quorum determines which partition may continue. Fencing ensures an unsafe node cannot continue accessing protected resources.

## Resource Design

The reference workload contains:

- `vip`, using `ocf:heartbeat:IPaddr2`
- `httpd-service`, using `systemd:httpd`

The default design uses explicit ordering and colocation constraints. An optional Pacemaker group can provide implicit ordering and colocation instead. Both models should not be applied to the same resources without review.

## Fencing Safety

The automation can define approved fence devices, but it does not run destructive fence tests automatically.

Live fencing tests require:

- An approved maintenance window
- Independent console access
- Application-owner coordination
- A documented recovery procedure
- Verification that each node is mapped to the correct fence target

## Validation

Static and live validation should cover:

- Cluster service state
- Quorum
- STONITH policy
- Fence-device definitions
- Failed or unclean nodes
- Resource definitions
- Constraint configuration
- Virtual-IP access
- HTTP response
- Resource relocation
- Standby and return
- Controlled service and node failure
- Logs and monitoring

## Rollback

Rollback requires approval, recovery access, a maintenance window, an exact protected backup and complete cluster membership.

PCS rollback does not automatically reverse package, application-data, DNS, network, storage or external fencing changes.

## Read-Only Commands

```bash
pcs status --full
pcs quorum status
pcs stonith status
pcs resource config
pcs constraint config --full
corosync-quorumtool -s

Stop Conditions
Stop if membership is incomplete, recovery access is unavailable, quorum is unhealthy, fencing is missing or untested, a node is unclean, resources are already failed, or the installed PCS syntax differs from the reviewed commands.
Testing Status
Designed and statically validated; live cluster compatibility testing remains required.
Passing CI is not proof of production deployment, successful fencing or end-to-end availability.
