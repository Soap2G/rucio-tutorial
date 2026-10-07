# 3. Manage data with datasets and rules (25 min)

In this chapter and the next, `$ME` is your Rucio account. You set it on the [home page](index.md) (`setup.sh` in SWAN, `export ME=…` in Docker). Check it:

```bash
echo $ME
```

## 3.1 Download data

```bash
cd $TUTORIAL_HOME/downloads
rucio download mdmc-open:climate/station-trieste-2025/
```

Rucio finds a replica, downloads each file and checks its checksum.

```bash
ls mdmc-open/climate/station-trieste-2025/
head -5 mdmc-open/climate/station-trieste-2025/trieste-2025-01.csv
```

Some useful options:

```bash
# take the copy from a specific RSE
rucio download mdmc-open:climate/station-geneva-2025/ --rses GENEVA_ARCHIVE
# only 2 random files of a dataset
rucio download mdmc-open:imaging/microscopy-batch-01/ --nrandom 2
```

Now try `--rses GENEVA_ARCHIVE` with `mdmc-open:humanities/archive-catalogue/`. It fails, because no replica of that dataset is on `GENEVA_ARCHIVE` (look again at 2.5).

=== "Docker image"

    If `rucio download` stops with an error about a certificate (`issuer is not trusted`), do step 2 of the [home page](index.md) again.

=== "CERN VRE (SWAN)"

    If `rucio download` stops with an error about `gfal2`, tell the instructor. It is a problem of the SWAN environment, not of your command.

**Exercise 3.1.** Download one image of the microscopy batch and open it in the JupyterLab file browser.

## 3.2 Make your own dataset

You want to collect the summer months of both stations in one dataset. The files stay where they are: a dataset only **refers** to them.

```bash
rucio did add --type dataset $ME:summer-2025
rucio did content add --to-did $ME:summer-2025 \
  mdmc-open:climate/station-trieste-2025/trieste-2025-07.csv \
  mdmc-open:climate/station-trieste-2025/trieste-2025-08.csv \
  mdmc-open:climate/station-geneva-2025/geneva-2025-07.csv \
  mdmc-open:climate/station-geneva-2025/geneva-2025-08.csv
rucio did content list $ME:summer-2025
```

Add metadata, so that other people can understand the dataset:

```bash
rucio did metadata set $ME:summer-2025 --key datatype --value csv
rucio did metadata list $ME:summer-2025
```

You can create datasets only in a scope that you **own**: your own scope. The scope `mdmc-open` belongs to another account.

!!! warning "Do not try it"
    If you create a DID in a scope that is not yours, Rucio refuses it. In this Rucio version, the client then shows a new
    login link, as if your login had expired. If this happens, press `Ctrl+C`. Do not log in again.

## 3.3 Make a copy with a rule

Ask for one copy of your dataset in Switzerland, on disk, for one day (86400 seconds):

```bash
rucio rule add $ME:summer-2025 --copies 1 --rses 'country=CH&type=DISK' --lifetime 86400
```

The command shows the **rule ID**. Keep it:

```bash
RULE=<the rule id>
rucio rule show $RULE
```

Look at `State`. It is `REPLICATING` while FTS copies the files, then `OK`. Run `rucio rule show $RULE` again after some seconds.

```bash
rucio replica list dataset $ME:summer-2025
```

Expected result: your dataset is now complete on `GENEVA_DISK` (and also on `TRIESTE_DISK`, because of the original rule).

> **Always give a lifetime** to your rules. When the lifetime ends, Rucio removes the rule, and the storage space becomes free again.

## 3.4 Rucio reuses copies

Ask for **two** copies in Italy:

```bash
rucio rule add $ME:summer-2025 --copies 2 --rses 'country=IT' --lifetime 86400
```

There are only two RSEs in Italy. The files are already on `TRIESTE_DISK`, so Rucio copies them only to `BOLOGNA_DISK`.

Now ask for a large dataset (100 MB) on `BOLOGNA_DISK`:

```bash
rucio rule add mdmc-open:instrument/raw-run-001/ --copies 1 --rses BOLOGNA_DISK --lifetime 86400
```

All students make the same request. Rucio copies the data **only once**. Each rule then "locks" the same replicas.
The data stays on `BOLOGNA_DISK` while at least one rule needs it.

**Exercise 3.2.** Show all your rules with `rucio rule list --account $ME`. What is the state of each rule?

## 3.5 Your quota

Each rule uses space in your quota on the RSEs that it selects:

```bash
rucio account limit list $ME
```

Look at the used and remaining bytes per RSE. A rule that does not fit in your quota is refused.

## 3.6 Remove a rule

```bash
rucio rule remove $RULE
rucio rule list --account $ME
```

The replicas on `GENEVA_DISK` are not deleted at once. A Rucio daemon deletes them later, and only if no other rule needs them.

## 3.7 And upload?

`rucio upload` puts a new local file on an RSE and registers it in one step:

```bash
rucio upload --rse TRIESTE_DISK --scope <account> my-result.csv --lifetime 86400
```

In this tutorial, you do not have write access to the storage, so you **do not** run this command. The instructor shows it.
In many Rucio instances, users upload to a small "scratch" RSE only. Then rules copy the data to the other RSEs, with the service account.

Next: [4. Roles and access control](04-rbac.md)
