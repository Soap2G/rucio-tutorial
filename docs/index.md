# Rucio tutorial: data management with roles

A hands-on introduction to [Rucio](https://rucio.cern.ch), the scientific data management system, from the command line.
It is for first-time users from any discipline. No physics knowledge is necessary.

Duration: 90 minutes.

## What you will learn

- The Rucio data model: accounts, scopes, files, datasets, containers, storage elements (RSEs) and rules.
- How to find data, read its metadata, and download it.
- How to organise data in your own datasets and keep copies of it with rules.
- How role-based access control (RBAC) decides which data you can see, and for how long.

## Before you start

- You have an account on the IAM of the CERN EOSC Node, and the organisers have added you to the tutorial group. Your **Rucio account** is your IAM username.
- You can open SWAN (JupyterLab).

## Start

1. Open SWAN. Open a **Terminal** (File → New → Terminal).
2. Get the tutorial files and set up the terminal:

    ```bash
    git clone https://gitlab.cern.ch/gguerrie/rucio-tutorial.git
    cd rucio-tutorial
    source setup.sh <your-rucio-account>
    ```

3. Keep this website open next to the SWAN terminal, and follow the chapters in sequence.

!!! tip "New terminal?"
    If you open a new terminal, go to `rucio-tutorial` and run `source setup.sh <your-rucio-account>` again.

## Chapters

| # | Chapter | Time |
|---|---|---|
| 0 | [Concepts](00-concepts.md) | 10 min |
| 1 | [Log in](01-login.md) | 5 min |
| 2 | [Explore the data](02-explore.md) | 15 min |
| 3 | [Manage data with datasets and rules](03-manage.md) | 25 min |
| 4 | [Roles and access control](04-rbac.md) | 25 min |
| 5 | [Wrap-up](05-wrap-up.md) | 10 min |

A one-page summary of all commands is in the [cheatsheet](cheatsheet.md).

## Conventions

- `<account>` means your Rucio account. Type it without the `< >`.
- Code blocks are commands for you to type (or copy, with the button on the right) in the terminal.
- "Expected result" shows what you see when the step is correct. The values can be a little different.

## For organisers

The preparation of the Rucio instance and the instructor guide are in the [`admin/` folder of the repository](https://gitlab.cern.ch/gguerrie/rucio-tutorial/-/tree/main/admin).
