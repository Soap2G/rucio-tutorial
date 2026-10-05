# Admin plan: prepare the rbac-test instance for the tutorial

This folder is for the organisers. Students do not need it.

Instance: `https://rbac-test-server.rucioit.cern.ch` (Rucio 41.1.1, policy package `rbac_rucio_policy_package` from `hdemule/rucio@rbac`).

## What the plan makes

| Item | Value |
|---|---|
| RSEs | `TRIESTE_DISK`, `BOLOGNA_DISK`, `GENEVA_DISK`, `GENEVA_ARCHIVE` |
| Storage | `https://eospublic.cern.ch:8444//eos/workspace/r/rucioit/rbac-tutorial/<RSE>` (all on the same EOS; that is OK for a tutorial) |
| RSE attributes | `country` (IT, CH), `site`, `type` (DISK, ARCHIVE), `lfn2pfn_algorithm=identity`, `fts` |
| Scopes | `mdmc-open` (shared data), `mdmc-embargo` (restricted data), one personal scope per student |
| Roles | `mdmc-student`: assignable, `read` on `mdmc-open`, comes from IAM. `mdmc-embargo-reader`: not assignable, `read` on `mdmc-embargo`, granted by the instructor during the course |
| Data | 48 synthetic files, 106 MB, 5 open datasets and 1 embargoed dataset (see below) |
| Quotas | 2 GB per student on each RSE |

All values are in `tutorial.env`. Change them there only.

### Data

`generate_data.py` makes the data with a fixed seed. Each run gives the same files and checksums.
The path `<scope>/<topic>/<collection>/<file>` becomes, through `rucio-it-register`:
container `<topic>`, container `<topic>/<collection>`, dataset `<topic>/<collection>/`, and the files.

| DID (dataset) | Content |
|---|---|
| `mdmc-open:climate/station-trieste-2025/` | 12 CSV, hourly temperature and humidity |
| `mdmc-open:climate/station-geneva-2025/` | 12 CSV |
| `mdmc-open:imaging/microscopy-batch-01/` | 12 PNG, synthetic microscopy |
| `mdmc-open:humanities/archive-catalogue/` | 5 JSON, catalogue records |
| `mdmc-open:instrument/raw-run-001/` | 4 × 25 MB binary, so that transfers take visible time |
| `mdmc-embargo:survey/wave-2026/` | 3 CSV, pseudonymised survey answers |

## Prerequisites

1. **Storage.** The four RSE directories exist on EOS (done). The FTS service account can write and delete in them.
2. **Client.** A Rucio client with the RBAC commands (`rucio role ...`), configured as `root` (or an account with the `admin` attribute). The CVMFS stack `rucio/41.1.1-rbac` has this client. Use your own `root` configuration, not the student configuration.
3. **Registration tool.** `rucio-it-register` from `rucio-it-tools`:
   `pip install git+https://gitlab.cern.ch/rucio-it/rucio-tools.git`
4. **Host.** Step 3 needs the EOS FUSE mount and write access to `/eos/workspace/r/rucioit/rbac-tutorial` (for example lxplus).
5. **IAM.** Each student is in the IAM group `data-management` and in the subgroup `data-management/roles/mdmc-student`. The hourly IAM sync then makes the account, the identity and the `mdmc-student` role.
   - The personal scope (`<account>`) is made by step 5. If `iamSync.userScopes` is on, the sync makes it first and step 5 only checks it. The test student account must also be in `students.txt`.
   - Check that students are NOT in the IAM groups of other roles on rbac-test. For example, `moderator` gives `read` on `*` and would show them all scopes.
   - The IAM sync must NOT manage quotas (`iamSync.quotas` empty). If it does, it removes the limits from step 5 at the next run.

## Steps

Do the steps in this sequence. Each script is safe to run again.

To see what a step will do first, run it with `DRY_RUN=1`, for example `DRY_RUN=1 ./01_rses.sh`.
Read-only calls (`show`, `list`) still run; each write call is only printed. In step 3, `rsync` only lists the changes and the script stops after the `rucio-it-register --dry-run`.

| Step | Command | When | Result |
|---|---|---|---|
| 1 | `./01_rses.sh` | once | 4 RSEs, protocol, attributes, distances, unlimited quota for `root` |
| 2 | `./02_scopes_roles.sh` | once | 2 scopes, 2 locked roles |
| 3 | `./03_upload_register.sh` | once | Data generated, copied to `TRIESTE_DISK`, registered with one rule per dataset (owner `root`, no lifetime). Asks for confirmation after a dry run. |
| 4 | `./04_curate.sh` | once | Datasets closed, `datatype` metadata, rule that copies `mdmc-open:climate` to `GENEVA_ARCHIVE` |
| 5 | `./05_students.sh` | after the students are in IAM; again on the day before | Personal scope (if missing), quotas, role check per student. Needs `students.txt` (copy `students.txt.example`). |
| 6 | `./06_check.sh` | the day before and 1 hour before the course | Read-only readiness check. All lines must be `OK`. |

### Notes

- **Step 1** uses `FTS=https://fts3-pilot.cern.ch:8446`. Make sure this is the FTS of rbac-test. If not, change `FTS` in `tutorial.env`.
- **Step 3** (`rsync` to EOS) writes with your own EOS identity. Rucio never uploads in this step: it only registers the files that are already on the storage.
- **Step 4** starts a real FTS transfer (about 0.6 MB). `06_check.sh` fails until it is done.
- **Custom metadata** (`description`) works only if the server has a JSON metadata plugin. The tutorial uses only `datatype`.

## CTAO demonstrator (Rucio Workshop)

Chapter 6 of the website. It uses the same RSEs (step 1), and its own scopes, roles and data. Settings: `ctao.env`.

| Step | Command | Result |
|---|---|---|
| C1 | `./ctao_01_scopes_roles.sh` | Scopes `ctao-prop-a`, `ctao-prop-b`, `ctao-prop-c`, `ctao-catalogue`. Locked roles `ctao-prop-a/b/c` (read on their proposal). Role `ctao-public` (not locked), read on `ctao-catalogue` and `ctao-prop-c`. |
| C2 | `./ctao_02_data.sh` | 15 synthetic data products (12 MB, FITS and JSON), 5 observation datasets, registered on `TRIESTE_DISK`; the mixed dataset `ctao-catalogue:search-2026-10` |
| Live | `./ctao_embargo.sh end ctao-prop-b` | End of the proprietary period of B (chapter 6.7). `restore` puts it back for the next run. |

Participants need the IAM groups `data-management`, `data-management/roles/ctao-public` and `data-management/roles/ctao-prop-a`.
The presenter is a group manager of `ctao-prop-a` in IAM (the PI). Nobody is in `ctao-prop-b`.

## During the course

See `INSTRUCTOR.md` for the timeline, the upload demo and the live RBAC step (`./embargo_access.sh grant 15` / `end`).
## After the course

These commands remove data. Run them only when the course is finished.

```bash
source tutorial.env
# Student rules expire on their own (lifetime 1 day). To remove the role grants now:
while read -r a _; do [[ -z "$a" || "$a" == \#* ]] && continue
  rucio role account remove "$EMBARGO_ROLE" "$a" --force; done < students.txt
# To remove all tutorial data: remove the root rules; the reaper then deletes the replicas.
rucio rule list --account root | grep -E "mdmc-(open|embargo)"   # check first
```
