# 2. Explore the data (15 min)

## 2.1 Storage elements (RSEs)

```bash
rucio rse list
```

Expected result: `BOLOGNA_DISK`, `GENEVA_ARCHIVE`, `GENEVA_DISK`, `TRIESTE_DISK`.

Each RSE has **attributes**:

```bash
rucio rse attribute list TRIESTE_DISK
```

Expected result:

```
TRIESTE_DISK: True
country: IT
fts: https://fts3-pilot.cern.ch:8446
lfn2pfn_algorithm: identity
site: trieste
type: DISK
```

The first line is the name of the RSE. Look for `country`, `site` and `type`: the expressions below use them.

### RSE expressions

You select RSEs with an **expression** on their attributes. Rules use the same expressions.

```bash
rucio rse list --rses 'country=IT'
rucio rse list --rses 'type=DISK&country=CH'
rucio rse list --rses 'country=IT\TRIESTE_DISK'
rucio rse list --rses 'TRIESTE_DISK|GENEVA_ARCHIVE'
```

| Operator | Meaning |
|---|---|
| `A&B` | in A **and** in B |
| <code>A&#124;B</code> | in A **or** in B |
| `A\B` | in A **but not** in B |

**Exercise 2.1.** Write an expression that selects all DISK RSEs that are not in Italy. Check it with `rucio rse list --rses`.

## 2.2 Scopes

```bash
rucio scope list
```

Expected result: `mdmc-open` and your own scope `<account>`.
Other scopes exist on this instance, but you do not see them. Chapter 4 explains why.

## 2.3 Datasets and containers

List the collections (datasets and containers) in `mdmc-open`:

```bash
rucio did list 'mdmc-open:*'
```

Expected result (the column `[DID TYPE]` tells container or dataset; the list is longer):

```
+-----------------------------------------+--------------+
| SCOPE:NAME                              | [DID TYPE]   |
|-----------------------------------------+--------------|
| mdmc-open:climate                       | CONTAINER    |
| mdmc-open:climate/station-trieste-2025  | CONTAINER    |
| mdmc-open:climate/station-trieste-2025/ | DATASET      |
| mdmc-open:climate/station-geneva-2025   | CONTAINER    |
...
```

> In this instance, a folder on the storage becomes a container. The deepest folder also becomes a dataset with the same name plus a trailing `/`.

Look at the hierarchy, from the top. A container holds containers or datasets. A dataset holds files.

```bash
rucio did content list mdmc-open:climate                        # two containers: one for each station
rucio did content list mdmc-open:climate/station-trieste-2025   # one dataset (the name ends with /)
rucio did content list mdmc-open:climate/station-trieste-2025/  # the 12 files of the dataset
```

The `/` at the end is part of the name of the dataset.

## 2.4 Details and metadata

```bash
rucio did show mdmc-open:climate/station-trieste-2025/
rucio did metadata list mdmc-open:climate/station-trieste-2025/
```

Expected result of `did show`:

```
account:     <the account of the organisers>
bytes:       280940
expired_at:  None
length:      12
monotonic:   False
name:        climate/station-trieste-2025/
open:        False
scope:       mdmc-open
type:        DATASET
```

Look for: the owner `account`, `open` (`False` means that the dataset is closed: its content cannot change), `bytes`, and `length` (number of files).
`metadata list` shows the same information (the field is called `is_open` there), and more keys. Look for `datatype`: the organisers set it to `csv`.

**Exercise 2.2.** How many files are in `mdmc-open:instrument/raw-run-001/`, and what is their total size?

## 2.5 Where are the copies?

Replicas of a dataset, per RSE:

```bash
rucio replica list dataset mdmc-open:climate/station-trieste-2025/
```

Expected result: the dataset is complete on `TRIESTE_DISK` **and** on `GENEVA_ARCHIVE`:

```
DATASET: mdmc-open:climate/station-trieste-2025/
+----------------+---------+---------+
| RSE            |   FOUND |   TOTAL |
|----------------+---------+---------|
| GENEVA_ARCHIVE |      12 |      12 |
| TRIESTE_DISK   |      12 |      12 |
+----------------+---------+---------+
```

`FOUND` is the number of files of the dataset that the RSE has. `TOTAL` is the number of files of the dataset. The dataset is complete when they are equal.
A background process updates these numbers, so a copy that is very new can show a small delay.

The replicas of one file, with their physical addresses (PFNs):

```bash
rucio replica list file mdmc-open:climate/station-trieste-2025/trieste-2025-01.csv --pfns
```

Expected result: one address for each RSE that has a copy (the order can be different). The path ends with `<scope>/<name>` of the file:

```
https://eospilot.cern.ch:8444//eos/pilot/eulake/eosc/rbac-tutorial/GENEVA_ARCHIVE/mdmc-open/climate/station-trieste-2025/trieste-2025-01.csv
https://eospublic.cern.ch:8444//eos/workspace/r/rucioit/rbac-tutorial/TRIESTE_DISK/mdmc-open/climate/station-trieste-2025/trieste-2025-01.csv
```

## 2.6 Why are the copies there?

Each replica exists because a rule needs it. List the rules of the dataset, and then the rules of its parent container:

```bash
rucio rule list --did mdmc-open:climate/station-trieste-2025/
rucio rule list --did mdmc-open:climate
```

Expected result: one rule for each command, both of an administrator account (the tutorial organisers):
- on the dataset: for `TRIESTE_DISK` (the original copy). The state is `OK[12/0/0]`: 12 files are `OK`, none is replicating, none is stuck. The size is `280.940 kB`.
- on the parent container `mdmc-open:climate`: for `GENEVA_ARCHIVE` (the "preservation copy"). The state is `OK[24/0/0]`. A rule on a container covers all the datasets in it. Its size is shown as `N/A`.

!!! note "Do not use `--traverse`"
    The option `rucio rule list --did <did> --traverse` is meant to show the rules of a DID and of its parents in one command.
    In this Rucio version, it stops with `KeyError: 'bytes'`. Use the two commands above.

**Exercise 2.3.** Which RSEs have a copy of `mdmc-open:imaging/microscopy-batch-01/`? Which rule keeps it there?

Next: [3. Manage data with datasets and rules](03-manage.md)
