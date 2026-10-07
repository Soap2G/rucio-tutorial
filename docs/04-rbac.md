# 4. Roles and access control (25 min)

Research data is not always open. Examples: personal data, data under embargo before publication, data under a contract.
A data manager must be able to say: "this group can read these data, until this date".

This Rucio instance uses **role-based access control (RBAC)**:

```{ .text .diagram }
┌─────────┐  has   ┌──────┐  grants   ┌───────────────────────────┐
│ account │───────>│ role │──────────>│        permission         │
└─────────┘   │    └──────┘           │ operation + scope pattern │
              │                       └───────────────────────────┘
   (optional expiry date)
```

Examples of permissions:

| Operation | Scope pattern | Gives access to                           |
|-----------|---------------|-------------------------------------------|
| `read`    | `mdmc-open`   | only the scope `mdmc-open`                |
| `read`    | `mdmc-*`      | all scopes whose name starts with `mdmc-` |
|

Rucio checks the access to a scope in this sequence:

1. Is the account `root` or an administrator? Then yes.
2. Is the account the **owner** of the scope? Then yes.
3. Does the account have a role with a permission for this scope and this operation, which has not expired? Then yes.
4. Otherwise, no. Rucio hides the scope and its DIDs.

In the following examples, roles control **read** access: listing, details, metadata, replicas and download.
To create or change DIDs, you must be the owner of the scope (step 2), as in standard Rucio.

### How to read the operations in the CLI

The CLI shows the operations of a permission in a short form with three letters.
The letters are always in the same order: **r**ead, **w**rite, **d**elete.
A `-` means that the operation is not given.

| CLI shows | Meaning |
|---|---|
| `r--` | read |
| `rw-` | read, write |
| `rwd` | read, write, delete |

In theory, any combination is valid (e.g. `-w-`= _write_ only, `r-d`=_read_ and _delete_ etc.) which may be useful for some special cases. In the following examples, roles give only give read access, so you will see `r--`.

## 4.1 Your roles

```bash
rucio role account list --me --detail
```

Expected result: the role `mdmc-student`, with no expiry date. Under the role name, you see `r--  mdmc-open`: read on the scope `mdmc-open`.

You can see the permissions of a role that you are granted to:

```bash
rucio role permission list mdmc-student
```

Expected result: a read permission on scope `mdmc-open` (`r--` means read, not write, not delete):

```
Permissions associated with role 'mdmc-student':
+-----------------+----------------+
| SCOPE PATTERN   | OPERATION(S)   |
|-----------------+----------------|
| mdmc-open       | r--            |
+-----------------+----------------+
```

If a scope pattern has a `*` (for example `mdmc-*`), add `--detail` to see the scopes that it matches now.

But you cannot see all the roles:

```bash
rucio role list
```

Expected result: an _access denied_ error. Only administrators can see all roles.

## 4.2 Where does your role come from?

You did not ask for `mdmc-student`. It comes from your **identity provider** (IAM):

- You are in the IAM group `data-management/roles/mdmc-student`.
- Each hour, a synchronisation job gives the role to all members of that group, and removes it from people who are not in the group any more.

A role that the identity provider can manage like this is **assignable**.
So the group managers in IAM decide who is a "student". Rucio only applies the decision.

## 4.3 Try to read the embargoed data

```bash
rucio scope list
rucio did list 'mdmc-embargo:*'
rucio did content list mdmc-embargo:survey/wave-2026/
```

Expected result: `mdmc-embargo` is not in the scope list, and the other two commands give an error.
Look at the message: Rucio does not say "you cannot read it". It says that the DID does not exist **or** is outside your scopes.
So a user without access cannot even learn that the data exists.

> ⚠️ Stop here and wait for the instructor...

## 4.4 The instructor gives you access, for 15 minutes

The instructor runs, for each student:

```bash
rucio role account add mdmc-embargo-reader <account> --expires-at <now + 15 min> --force
```

`--force` is necessary because `mdmc-embargo-reader` is **not assignable**: the identity provider cannot give or remove it.
Only a Rucio administrator can. This is correct for sensitive data: one person approves each access, and the access has an end date.

Check your roles again:

```bash
rucio role account list --me --detail
```

Expected result: two roles. `mdmc-embargo-reader` has an expiry date.
Its permission is `r--` on `mdmc-embargo`: read only. You will test this in 4.5.

## 4.5 Read the embargoed data

```bash
rucio scope list
rucio did list 'mdmc-embargo:*'
rucio did show mdmc-embargo:survey/wave-2026/
cd $TUTORIAL_HOME/downloads
rucio download mdmc-embargo:survey/wave-2026/
head -3 mdmc-embargo/survey/wave-2026/responses-part1.csv
```

All of these work now.

But the role gives **read** access only. You still cannot create DIDs in `mdmc-embargo`: only the owner of a scope can.
(If you try, Rucio refuses it and the client shows a new login link; press `Ctrl+C`, see chapter 1.)

## 4.6 Put an embargoed file in your own dataset

You own your scope, so you can attach any file that you can see:

```bash
rucio did add --type dataset $ME:my-analysis
rucio did content add --to-did $ME:my-analysis \
  mdmc-open:climate/station-trieste-2025/trieste-2025-01.csv \
  mdmc-embargo:survey/wave-2026/responses-part1.csv
rucio did content list $ME:my-analysis
```

Expected result: two files.

**Question.** When your role expires, can you still read the survey file through **your** dataset?
Write down your answer, then go to 4.7.

## 4.7 After the expiry

Wait until the expiry time (or until the instructor ends it). Then:

```bash
rucio role account list --me --detail
rucio scope list
rucio did content list $ME:my-analysis
rucio replica list dataset $ME:my-analysis
```

Expected result:
- `mdmc-embargo-reader` is not active any more, and `mdmc-embargo` is not in the scope list.
- Your dataset `$ME:my-analysis` shows **only the climate file**. The survey file is still attached, but Rucio hides it from you.

So access follows the **data**, not the dataset that contains it. You cannot "keep" access by copying references into your own scope.
(The files that you downloaded in 4.5 are still on your disk. Rucio controls the data that it manages; after a download, the responsibility is yours. This is why data agreements exist.)

## 4.8 Summary

| Question | Answer in this instance |
|---|---|
| Who decides who is a "student"? | IAM group managers (assignable role, hourly sync) |
| Who decides who reads embargoed data? | A Rucio administrator (non-assignable role) |
| For how long? | Until `expires_at`; then the access stops automatically |
| What does a role give? | `read`, `write` or `delete` access on a scope pattern (`mdmc-open`, or `mdmc-*` for all scopes that start with `mdmc-`) |
| What does the owner of a scope have? | Full access to the scope, with no role |
| Can a user see data that they cannot read? | No. The scope and its DIDs are hidden, also inside other datasets |

**Exercise 4.1 (discussion).** In your own field, think of one dataset that needs a non-assignable role with an expiry date, and one that only needs an assignable role. What is the difference?

Next: [5. Wrap-up](05-wrap-up.md)
