# Security Controls



## Opt-In Change Model



All mutation families are disabled by default. Changes require approval, a verified backup, recovery access, a maintenance window, complete membership and an approved fencing design.



## Repository Protection



The repository excludes private inventories, credentials, keys, certificates, PCS tokens, Corosync authentication keys, fence secrets, backups, logs and runtime artifacts.



Review every staged file:



```bash

git status --short --untracked-files=all

git diff --cached --check



Never assume .gitignore can remove a secret already committed.

Administrative Access

Use named accounts, SSH keys, host-key verification, least privilege, explicit privilege escalation and independent console access. Use RSA keys where FIPS constraints require them.

Authentication and Fencing

The hacluster password and fence credentials must come from an approved secret-management process. Sensitive tasks use no_log.

Production operation requires STONITH through an independent supported control path. Live fencing requires separate approval, verified node mapping, console access and a recovery procedure.

Quorum and Change Safety

The three-node design uses no-quorum-policy=stop. Quorum does not replace fencing.

Package installation is throttled to one node at a time. Cluster-wide PCS operations execute once from the bootstrap node. Deployment stops on the first failure.

Backup and Rollback

PCS backups are stored under /var/backups/rhel-ha-cluster/ with restrictive ownership and permissions.

Rollback requires an exact approved backup. A pre-rollback backup is created before restoration. CIB backups must never be committed.

CI Supply Chain

GitHub Actions uses read-only permissions, a fixed runner and Python version, full commit-SHA action pins, pinned Python dependencies and a pinned Ansible collection.

CI performs static validation only and never connects to managed hosts.

Validation Boundaries

Validation checks services, cluster state, quorum, STONITH policy, failure indicators, fence definitions, resources and constraints.

Passing CI does not prove live RHEL compatibility, correct fencing, successful failover, SELinux behavior, firewalld policy or production readiness.

External Requirements

Production adoption still requires environment-specific network security, SELinux, firewalld, secret management, monitoring, storage protection, application testing, backup and disaster-recovery controls.



Save, then repair only the known copy artifacts:



```powershell
