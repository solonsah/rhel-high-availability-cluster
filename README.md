# RHEL High-Availability Cluster

[![RHEL HA Cluster Validation](https://github.com/solonsah/rhel-high-availability-cluster/actions/workflows/ha-cluster-validation.yml/badge.svg)](https://github.com/solonsah/rhel-high-availability-cluster/actions/workflows/ha-cluster-validation.yml)

A safety-oriented automation framework for building, auditing, validating and recovering a three-node RHEL cluster with Pacemaker, Corosync, PCS and STONITH fencing.

## Project Purpose

This project demonstrates:

\- Three-node majority quorum

\- Pacemaker and Corosync configuration

\- PCS-based cluster administration

\- Mandatory production fencing design

\- Floating virtual-IP management

\- Clustered Apache HTTPD service

\- Resource monitoring

\- Ordering and colocation constraints

\- Optional Pacemaker resource grouping

\- Read-only discovery

\- Approval and recovery gates

\- Configuration backup and rollback

\- Static GitHub Actions validation

The repository contains sanitized examples only. It does not claim a live production deployment.

## Reference Architecture

| Layer | Reference design |

|---|---|

| Cluster membership | Three RHEL voting nodes |

| Communication | Corosync |

| Resource manager | Pacemaker |

| Administration | PCS |

| Fencing | Approved STONITH agents |

| Client endpoint | Floating virtual IP |

| Workload | systemd-managed Apache HTTPD |

| Recovery | Pacemaker resource migration |

| Validation | Ansible, yamllint, ansible-lint and ShellCheck |

See [Architecture](docs/architecture.md) and [Cluster Design Notes](docs/cluster-design-notes.md).

## Safety Model

All mutation families are disabled by default:

```yaml

rhel_ha_manage_packages: false

rhel_ha_manage_pcsd: false

rhel_ha_manage_cluster: false

rhel_ha_manage_fencing: false

rhel_ha_manage_resources: false

rhel_ha_manage_constraints: false

```

Changes require confirmation of:

\- Change approval

\- Current backups

\- Independent recovery access

\- Approved maintenance window

\- Complete cluster membership

\- Approved fencing design

Package changes use `throttle: 1`. Cluster-wide PCS commands execute once from the designated bootstrap node.

## Repository Structure

```text

.

├── .github/workflows/

│   └── ha-cluster-validation.yml

├── ansible/

│   ├── playbooks/

│   │   ├── audit.yml

│   │   ├── deploy.yml

│   │   └── rollback.yml

│   └── roles/rhel_ha_cluster/

│       ├── defaults/

│       ├── handlers/

│       └── tasks/

├── docs/

│   ├── architecture.md

│   ├── cluster-design-notes.md

│   ├── operations-runbook.md

│   └── security-controls.md

├── inventory/

│   └── example.ini

├── sample-output/

│   └── README.md

├── scripts/

│   └── validate.sh

├── .ansible-lint

├── .gitignore

├── .yamllint

├── ansible.cfg

├── requirements-dev.txt

└── requirements.yml

```

## Read-Only Audit

Use an ignored private inventory:

```bash

ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/audit.yml \
  --limit ha_cluster

```

The audit collects package facts, service facts, cluster status, quorum, fencing information and resource configuration without remediation.

## Controlled Deployment

Create an ignored private variables file. Enable only the approved change families.

```bash

ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/deploy.yml \
  --limit ha_cluster \
  --extra-vars "@inventory/private/change.yml"

```

Deployment requires the complete expected voting membership and stops on the first failure.

## Fencing

Production use requires STONITH.

Fence definitions belong in an ignored private variables file:

```yaml

rhel_ha_fence_devices:

  - name: fence-node-01

    agent: fence_ipmilan

    options:

      - pcmk_host_list=ha-node-01

      - ipaddr=192.0.2.201

      - login=private-user

      - passwd=private-secret

```

The values above are illustrative. Never commit actual management addresses or credentials.

The automation defines approved fence devices but does not automatically execute destructive fence tests.

## Resources and Constraints

The example workload uses:

\- `vip` through `ocf:heartbeat:IPaddr2`

\- `httpd-service` through `systemd:httpd`

The default model creates explicit colocation and ordering constraints. An optional resource-group model is also supported.

Do not apply both models to the same resources without review.

## Controlled Rollback

Rollback requires an exact protected PCS backup:

```bash

ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/rollback.yml \
  --limit ha_cluster \
  --extra-vars "@inventory/private/rollback.yml"

```

A pre-rollback backup is created before restoration.

PCS rollback does not automatically reverse package, application-data, network, DNS, storage or external fencing changes.

## Local Validation

Install pinned dependencies:

```bash

python -m pip install --requirement requirements-dev.txt

ansible-galaxy collection install \
  --requirements-file requirements.yml \
  --collections-path collections

```

Run:

```bash

bash scripts/validate.sh

```

Validation includes:

\- YAML linting

\- ShellCheck

\- Ansible collection verification

\- Ansible linting

\- Syntax checks for all playbooks

## CI Security

GitHub Actions uses:

\- Read-only repository permissions

\- Ubuntu 24.04

\- Python 3.13

\- Full commit-SHA action pins

\- Pinned Python dependencies

\- A pinned Ansible collection

CI performs static validation only and never connects to managed hosts.

## Supported Design Targets

| Platform | Status |

|---|---|

| RHEL 8 | Designed target; live testing required |

| RHEL 9 | Designed target; live testing required |

| RHEL 10 | Future compatibility review |

| Ubuntu 24.04 | CI runner only |

## Important Limitations

Passing CI does not prove:

\- Live PCS compatibility

\- Correct Corosync networking

\- Successful fencing

\- Resource failover

\- Application availability

\- Correct SELinux or firewalld behavior

\- Production readiness

\- Security compliance

Live testing must use approved disposable or non-production RHEL systems.

See the [Operations Runbook](docs/operations-runbook.md) and [Security Controls](docs/security-controls.md) before adapting this framework.

## License

This project is licensed under the [MIT License](LICENSE).
