# 6. Demonstrator: observation proposals with a proprietary period

!!! info "Rucio Workshop"
    This chapter is a demonstrator for the Rucio Workshop. It is not part of the 90-minute course.
    You need chapters 1 and 4 first: the login and the role model.

The use case comes from the Cherenkov Telescope Array Observatory (CTAO).

- A **proposal** comes from a **proposal group**: a Principal Investigator (PI), a co-PI, and co-Investigators (co-Is).
  The PI and co-PI manage the group: they add and remove members.
- An accepted proposal gives a set of **observations**. Each observation gives **data products** (files).
- All data products of a proposal are **embargoed** for one year (the proprietary period). During this period, only the proposal group can read them. After it, they are public.
- The **Data Management Team (DMT)** manages all data: transfer, replication, deletion.

The access decision is per data product: *does the product belong to proposal X, and is the user a member of the group of X?*

## 6.1 The mapping to Rucio

| CTAO | Rucio |
|---|---|
| Proposal | A scope: `ctao-prop-a`, `ctao-prop-b`, `ctao-prop-c` |
| Observation | A dataset in that scope: `observations/obs-0101/` |
| Data product | A file of the dataset (`.fits`, `.json`) |
| Proposal group | A role with `read` on the proposal scope, for example `ctao-prop-a` |
| PI and co-PI manage the group | They are the **group managers** of the IAM group `data-management/roles/ctao-prop-a`. The hourly sync applies their changes in Rucio. |
| End of the proprietary period | The role `ctao-public` gets `read` on the proposal scope |
| Scientist with an account | Has the role `ctao-public` |
| DMT | Rucio administrators (`admin` attribute). They own the proposal scopes. |

In this demonstrator, **you are a co-I of proposal A**. You are not in proposal B. Proposal C is from 2025, and its proprietary period is over.

| Proposal | Target | Observations | Status at the start |
|---|---|---|---|
| A, `2026A-001` | Crab Nebula | `obs-0101`, `obs-0102` | embargoed, you are a member |
| B, `2026A-002` | PKS 2155-304 | `obs-0201`, `obs-0202` | embargoed, you are not a member |
| C, `2025A-017` | Mrk 421 | `obs-0301` | public |

## 6.2 Your roles

```bash
rucio role account list --me --detail
```

Expected result: `ctao-prop-a` (read on `ctao-prop-a`) and `ctao-public` (read on `ctao-catalogue` and `ctao-prop-c`).

```bash
rucio scope list
```

Expected result: `ctao-catalogue`, `ctao-prop-a`, `ctao-prop-c`, and your own scope. **`ctao-prop-b` is not there.**

## 6.3 Case 1: embargoed data of your proposal

```bash
rucio did list 'ctao-prop-a:*'
rucio did content list ctao-prop-a:observations/obs-0101/
rucio did metadata list ctao-prop-a:observations/obs-0101/
```

Access is granted: the data is embargoed, and you are in the proposal group.

## 6.4 Case 2: embargoed data of another proposal

```bash
rucio did list 'ctao-prop-b:*'
rucio did content list ctao-prop-b:observations/obs-0201/
```

Access is denied. Rucio does not even confirm that proposal B has data.

## 6.5 Case 3: public data

```bash
rucio did content list ctao-prop-c:observations/obs-0301/
cd $TUTORIAL_HOME/downloads
rucio download ctao-prop-c:observations/obs-0301/
```

Access is granted to everybody who has the role `ctao-public`.

## 6.6 Case 4: a search result that mixes proposals

A data search gives a collection. It can contain data from several proposals. Here, `ctao-catalogue:search-2026-10` contains:

- all data of proposal A (embargoed, you are a member),
- the data of `obs-0201` of proposal B (embargoed, you are not a member),
- all data of proposal C (public).

```bash
rucio did show ctao-catalogue:search-2026-10
rucio did content list ctao-catalogue:search-2026-10
rucio replica list dataset ctao-catalogue:search-2026-10
```

Expected result: you see the files of `obs-0101`, `obs-0102` and `obs-0301`. The files of `obs-0201` are not in the list.
The decision is made **for each file**, from the scope (the proposal) of the file. The collection itself does not give access.

```bash
rucio download ctao-catalogue:search-2026-10
```

You get all the files that you are allowed to read, and only those.

!!! warning "Stop"
    Wait for the presenter.

## 6.7 The proprietary period of proposal B ends

The DMT runs one command:

```bash
rucio role permission add ctao-public read ctao-prop-b
```

Nobody's roles change. The **data** of proposal B changes status: from now on, everybody with `ctao-public` can read it.

Run the case 2 and case 4 commands again:

```bash
rucio scope list
rucio did content list ctao-prop-b:observations/obs-0201/
rucio did content list ctao-catalogue:search-2026-10
```

Expected result: `ctao-prop-b` is in your scope list, and the search result now shows the files of `obs-0201` too.

## 6.8 What the demonstrator shows, and its limits

| Requirement | Status in this RBAC version |
|---|---|
| Access per proposal group | Yes: one role per proposal, read on the proposal scope |
| PI and co-PI manage the group | Yes, in IAM (group managers); the sync applies it |
| Decision per data product (case 4) | Yes: listings and replicas are filtered by the scope of each file |
| End of the proprietary period | Yes: one permission on the public role, per proposal. It can also be undone. |
| Embargo dates kept by Rucio | No: the DMT runs the command when the period ends (for example from a scheduled job) |
| Anonymous access to public data | Not through Rucio: the Rucio API needs an account. Anonymous access is at the storage level or through a portal. |
| DMT rights through a role | No: this version checks only `read`. The DMT uses the `admin` attribute. |
| Embargo at the storage level | The storage of this demonstrator allows anonymous read. Real embargoed data needs storage with token authentication, so that a file address alone does not give access. |
