# 0. Concepts (10 min)

## The problem

A research project produces many files. They are in many places: a laptop, a university server, a computing centre, an archive.
After some time, nobody knows which copy is the correct one, where the copies are, or who can read them.

Rucio solves this problem. You tell Rucio **what** you want ("keep two copies of this dataset in Italy for one month").
Rucio decides **how**: it copies, checks and deletes the files for you.

Rucio started at CERN for the ATLAS experiment (more than 1 exabyte of data). Today many sciences use it: astronomy, climate, life sciences, and others.

## The data model

```
 account ──owns──▶ scope
                     │
                     ▼
      container ──▶ dataset ──▶ file  ─── replica on an RSE
       (folder      (set of     (the data)    (a physical copy)
        of sets)     files)
                     ▲
          rule ──────┘  "keep N copies of this DID on these RSEs"
```

| Concept | Meaning | Example |
|---|---|---|
| **Account** | Who you are in Rucio. Each action is done by an account. | `jdoe` |
| **Scope** | A namespace for names. Each scope has an owner account. | `mdmc-open`, `jdoe` |
| **DID** (Data IDentifier) | The name of a file, dataset or container: `scope:name`. A DID is unique and never reused. | `mdmc-open:climate/station-trieste-2025/` |
| **File** | The smallest unit. Rucio knows its size and checksum. | `mdmc-open:climate/station-trieste-2025/trieste-2025-01.csv` |
| **Dataset** | A set of files. Rules and transfers usually work on datasets. | `mdmc-open:climate/station-trieste-2025/` |
| **Container** | A set of datasets or other containers. | `mdmc-open:climate` |
| **RSE** (Rucio Storage Element) | A storage place. RSEs have attributes, for example `country=IT`. | `TRIESTE_DISK` |
| **Replica** | A physical copy of a file on an RSE. | |
| **Rule** | A request: "keep N copies of this DID on RSEs that match this expression". Rucio makes the copies and keeps them while the rule exists. | `2 copies on country=IT` |
| **Quota** | The maximum space that your rules can use on an RSE. | 2 GB |

> **Important:** you never copy or delete files by hand. You make and remove **rules**. A file stays on an RSE while at least one rule needs it.

## Who does the storage operations?

In this tutorial you do not have write access to the storage. This is intentional.
You ask Rucio with a rule. A Rucio **service account** then does the copy with the File Transfer Service (FTS).
So users control *what* happens, and only the service touches the storage. This makes the storage safer and easier to audit.

## Access control

Rucio must also decide **who can see what**. In this instance:

- You can always read and change the DIDs in your **own scope**.
- **Roles** give you access to other scopes. For example, the role `mdmc-student` lets you read `mdmc-open`.
- A role can have an **expiry date**. After that date, the access stops automatically.

Chapter 4 shows this in practice.

## The tutorial infrastructure

| RSE | Country | Type |
|---|---|---|
| `TRIESTE_DISK` | IT | DISK |
| `BOLOGNA_DISK` | IT | DISK |
| `GENEVA_DISK` | CH | DISK |
| `GENEVA_ARCHIVE` | CH | ARCHIVE |

| Scope | Content | Who can read |
|---|---|---|
| `mdmc-open` | Climate, imaging, humanities and instrument data (synthetic) | role `mdmc-student` |
| `mdmc-embargo` | Pseudonymised survey answers (synthetic) | role `mdmc-embargo-reader` |
| `<account>` | Your own data | you |

Next: [1. Log in](01-login.md)
