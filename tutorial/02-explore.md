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

Look for `country`, `site` and `type`.

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
| `A\|B` | in A **or** in B |
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

Expected result (the `TYPE` column tells container or dataset):

```
mdmc-open:climate                              CONTAINER
mdmc-open:climate/station-trieste-2025         CONTAINER
mdmc-open:climate/station-trieste-2025/        DATASET
...
```

> In this instance, a folder on the storage becomes a container. The deepest folder also becomes a dataset with the same name plus a trailing `/`.

Look at the hierarchy, from the top:

```bash
rucio did content list mdmc-open:climate
rucio did content list mdmc-open:climate/station-trieste-2025/
```

The second command lists the files of the dataset.

## 2.4 Details and metadata

```bash
rucio did show mdmc-open:climate/station-trieste-2025/
rucio did metadata list mdmc-open:climate/station-trieste-2025/
```

Look for: the owner `account`, `is_open` (a closed dataset cannot change), `bytes`, `length` (number of files), and `datatype` in the metadata.

**Exercise 2.2.** How many files are in `mdmc-open:instrument/raw-run-001/`, and what is their total size?

## 2.5 Where are the copies?

Replicas of a dataset, per RSE:

```bash
rucio replica list dataset mdmc-open:climate/station-trieste-2025/
```

Expected result: the dataset is complete on `TRIESTE_DISK` **and** on `GENEVA_ARCHIVE`.

The replicas of one file, with their physical addresses (PFNs):

```bash
rucio replica list file mdmc-open:climate/station-trieste-2025/trieste-2025-01.csv --pfns
```

## 2.6 Why are the copies there?

Each replica exists because a rule needs it:

```bash
rucio rule list --did mdmc-open:climate/station-trieste-2025/ --traverse
```

`--traverse` also looks at the parents of the DID.
Expected result: two rules of the account `root`:
- one on the dataset, for `TRIESTE_DISK` (the original copy);
- one on the parent container `mdmc-open:climate`, for `GENEVA_ARCHIVE` (the "preservation copy"). A rule on a container covers all the datasets in it.

**Exercise 2.3.** Which RSEs have a copy of `mdmc-open:imaging/microscopy-batch-01/`? Which rule keeps it there?

Next: [3. Manage data with datasets and rules](03-manage.md)
