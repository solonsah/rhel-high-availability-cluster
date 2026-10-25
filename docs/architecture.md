# RHEL High-Availability Cluster Architecture

## Purpose

This project demonstrates a safety-oriented three-node RHEL high-availability cluster using Pacemaker, Corosync, PCS and STONITH fencing.

The example workload consists of:

\- One floating virtual IP

\- One systemd-managed Apache HTTPD resource

\- Explicit ordering and colocation constraints

\- Optional Pacemaker resource grouping

\- Quorum-aware service placement

\- Mandatory production fencing

\- Audit, deployment, validation and rollback automation

The repository contains sanitized examples only. It does not represent a live production deployment.

## Logical Design

```text

Approved private client network

              |

              v

     Floating virtual IP

              |

              v

   Pacemaker-managed HTTPD

              |

      Active cluster node

       /       |       \\

ha-node-01 ha-node-02 ha-node-03

       \\       |       /

        Corosync membership

              |

       Quorum decisions

              |

     STONITH fence devices

              |

  Independent power management

```

## Cluster Nodes

The reference design uses three voting nodes:

| Node | Documentation address | Role |

|---|---:|---|

| `ha-node-01` | `192.0.2.11` | Voting cluster member |

| `ha-node-02` | `192.0.2.12` | Voting cluster member |

| `ha-node-03` | `192.0.2.13` | Voting cluster member |

An odd node count supports a clear majority decision without relying on two-node mode. Production designs must still review failure domains and whether a quorum device is required.

## Cluster Components

### Corosync

Corosync provides node communication, membership, failure detection and quorum information.

### Pacemaker

Pacemaker manages resource placement, monitoring, recovery, migration, constraints and integration with fencing.

### PCS

PCS provides the administrative interface used to configure and inspect the cluster. Cluster-wide automation runs from one designated bootstrap node.

### STONITH

STONITH isolates a failed or unresponsive node before protected resources are recovered elsewhere.

A production cluster must not depend on SSH shutdown as fencing. Fence devices should use an independent and tested control path such as supported out-of-band management, hypervisor fencing or cloud fencing.

This repository can define approved fence devices, but it never automatically performs a destructive fence test.

## Resource Model

The default model contains:

1\. `vip`, using `ocf:heartbeat:IPaddr2`

2\. `httpd-service`, using `systemd:httpd`

The explicit constraint model requires:

\- The virtual IP and HTTPD service to run together

\- The virtual IP to start before HTTPD

\- HTTPD to stop before the virtual IP

The optional group model places both resources in `web-service-group`, where ordering and colocation are implicit.

Do not enable both models for the same resources without a reviewed design.

## Quorum Policy

The default `no-quorum-policy` is `stop`.

If the remaining partition cannot establish quorum, workload resources stop. This reduces the risk that separate partitions operate the same protected workload simultaneously.

Quorum does not replace fencing. Quorum determines which partition may continue; fencing confirms that an unsafe node cannot continue accessing protected resources.

## Expected Failure Behavior

| Failure | Expected response |

|---|---|

| HTTPD process failure | Pacemaker attempts resource recovery |

| Active node failure | Fencing isolates the node before resource recovery |

| One node lost | Remaining two nodes retain majority quorum |

| Two nodes lost | Remaining node loses quorum and stops resources |

| Network partition | Quorum and fencing policies determine ownership |

| Fence-device failure | Recovery may be blocked to protect data integrity |

| Virtual-IP failure | Monitoring triggers recovery or migration |

## Availability Boundaries

This cluster does not automatically provide:

\- Redundant client networking or DNS

\- Redundant storage

\- Database replication

\- Application-data consistency

\- Session replication

\- Certificate lifecycle management

\- Application-data backup

\- Cross-site disaster recovery

\- Security compliance certification

The service is only as available as its remaining external dependencies.

## Network Requirements

Production planning must address:

\- Corosync communication paths

\- PCS daemon access

\- Application service ports

\- Virtual-IP subnet and interface

\- Fence-device management networks

\- Monitoring access

\- Firewalld policy

\- Routing and reverse-path behavior

\- DNS and client failover expectations

All example addresses use reserved documentation ranges and must be replaced during approved environment-specific implementation.

## Security Boundaries

The repository does not store:

\- `hacluster` passwords

\- Fence-device credentials

\- Private inventories

\- Real hostnames or IP addresses

\- SSH keys or certificates

\- CIB backups

\- Runtime logs

Secrets must come from an approved external secret-management process.

## Validation Boundaries

Static CI validates YAML, shell code, Ansible syntax and linting. It cannot prove:

\- PCS compatibility on every RHEL minor release

\- Correct fence-agent behavior

\- Quorum behavior during real network failure

\- Successful resource relocation

\- Correct SELinux or firewalld policy

\- Application readiness

\- Production safety

Live testing must use approved disposable or non-production RHEL systems before production adoption.

See \[Cluster Design Notes](cluster-design-notes.md) for implementation reasoning, operational observations and lessons learned.
