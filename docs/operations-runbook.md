# RHEL High-Availability Cluster Operations Runbook

## Scope

This runbook covers audit, approved deployment, validation, maintenance, failover testing and PCS configuration rollback for the reference cluster.

Treat every target as production unless its environment is explicitly confirmed otherwise.

## 1. Sanitize Evidence

Before sharing command output, remove or replace:

\- Company and customer names

\- Real hostnames, domains and IP addresses

\- Usernames and email addresses

\- Credentials, tokens and keys

\- Fence-device parameters

\- Internal application names

\- Sensitive paths and infrastructure identifiers

Never share CIB backups or PCS authentication output publicly.

## 2. Confirm Change Readiness

Before mutation, confirm:

\- Approved change record

\- Exact environment and cluster membership

\- Application-owner approval

\- Maintenance window

\- Current configuration backup

\- Independent console or recovery access

\- Healthy quorum

\- No failed or unclean nodes

\- Approved and tested fencing design

\- Rollback source and decision point

Stop if any item is uncertain.

## 3. Run the Read-Only Audit

Use a private ignored inventory:

```bash

ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/audit.yml \
  --limit ha_cluster

```

Review:

\- RHEL version

\- Installed HA packages

\- Cluster service state

\- Corosync configuration

\- CIB presence

\- PCS status

\- Quorum

\- Fencing configuration

\- Resource definitions

Audit mode does not authorize remediation.

## 4. Prepare Private Variables

Create an ignored variables file containing only approved environment-specific values.

At minimum, review:

```yaml

\---

rhel_ha_change_approved: true

rhel_ha_backup_confirmed: true

rhel_ha_recovery_access_confirmed: true

rhel_ha_maintenance_window_confirmed: true

rhel_ha_fencing_design_approved: true

rhel_ha_manage_packages: false

rhel_ha_manage_pcsd: false

rhel_ha_manage_cluster: false

rhel_ha_manage_fencing: false

rhel_ha_manage_resources: false

rhel_ha_manage_constraints: false

```

Enable only the change families included in the approved scope.

Never commit the private file.

## 5. Deploy in a Non-Production Environment

Run:

```bash

ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/deploy.yml \
  --limit ha_cluster \
  --extra-vars "@inventory/private/change.yml"

```

Package installation is throttled to one node at a time. Cluster-wide PCS operations run once from the designated bootstrap node.

Stop immediately if membership, quorum, fencing, resources or application behavior differs from the approved design.

## 6. Validate Cluster Health

From the approved administrative node, review:

```bash

pcs status --full

pcs quorum status

pcs stonith status

pcs resource config

pcs constraint config --full

corosync-quorumtool -s

```

Confirm:

\- All expected nodes are online

\- The cluster is quorate

\- No node is unclean

\- No resource is failed

\- STONITH is enabled

\- Fence devices map to the correct nodes

\- The virtual IP and HTTPD resource are correctly placed

\- Ordering and colocation are correct

\- Client traffic reaches the virtual IP

\- HTTP responses meet acceptance criteria

\- Logs contain no new critical errors

Do not declare success from `systemctl` output alone.

## 7. Controlled Maintenance

Before maintaining one node:

```bash

pcs node standby <node>

pcs status --full

```

Confirm all resources moved successfully before working on the node.

After maintenance and validation:

```bash

pcs node unstandby <node>

pcs status --full

```

Do not return a node to service if Pacemaker, Corosync, fencing or application health remains uncertain.

## 8. Controlled Failover Testing

Failover testing requires separate approval.

Test in increasing order of risk:

1\. Application process failure

2\. Resource relocation

3\. Node standby

4\. Corosync communication failure

5\. Node failure

6\. Live fencing

For every test, record:

\- Initial state

\- Expected result

\- Actual result

\- Recovery duration

\- Resource placement

\- Fence result

\- Application response

\- Log and monitoring behavior

\- Rollback decision

Never perform live fencing without verified console access and node-to-device mapping.

## 9. Controlled Rollback

Create an ignored rollback file:

```yaml

\---

rhel_ha_change_approved: true

rhel_ha_backup_confirmed: true

rhel_ha_recovery_access_confirmed: true

rhel_ha_maintenance_window_confirmed: true

rhel_ha_rollback_approved: true

rhel_ha_rollback_source: /var/backups/rhel-ha-cluster/exact-backup-file

```

Run:

```bash

ansible-playbook \
  -i inventory/private/hosts.ini \
  ansible/playbooks/rollback.yml \
  --limit ha_cluster \
  --extra-vars "@inventory/private/rollback.yml"

```

The role creates a pre-rollback backup before restoring the selected PCS configuration.

Rollback does not automatically reverse RPM, application-data, storage, DNS, network or external fencing changes.

## 10. Post-Rollback Validation

Verify:

\- Complete membership

\- Majority quorum

\- No failed or unclean nodes

\- Correct cluster properties

\- Fence-device definitions

\- Resource definitions

\- Constraints

\- Virtual-IP reachability

\- HTTP response

\- Logs and monitoring

\- Original change symptom

## Emergency Stop Conditions

Stop immediately if:

\- The environment is uncertain

\- A target node is missing

\- Recovery access is unavailable

\- Backup validation fails

\- Quorum is unhealthy

\- A node is unclean

\- A resource is already failed

\- Fencing is absent, incorrect or untested

\- Resource movement is unexpected

\- Application behavior changes unexpectedly

\- PCS syntax differs from the reviewed RHEL version
