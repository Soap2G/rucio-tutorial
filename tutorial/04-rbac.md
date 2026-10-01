# 4. Roles and access control (25 min)

Research data is not always open. Examples: personal data, data under embargo before publication, data under a contract.
A data manager must be able to say: "this group can read these data, until this date".

This Rucio instance uses **role-based access control (RBAC)**:

```
account ──has──▶ role ──grants──▶ permission = operation on a scope pattern
          (optional        e.g. "read" on "mdmc-open"
           expiry date)        or "read" on "mdmc-*"
```

Rucio checks the access to a scope in this sequence:

1. Is the account `root` or an administrator? Then yes.
2. Is the account the **owner** of the scope? Then yes.
3. Does the account have a role with a permission for this scope and this operation, which has not expired? Then yes.
4. Otherwise, no. Rucio hides the scope and its DIDs.

In this version, roles control **read** access: listing, details, metadata, replicas and download.
To create or change DIDs, you must be the owner of the scope (step 2), as in standard Rucio.

## 4.1 Your roles

```bash
rucio role account list --me --detail
```

Expected result: the role `mdmc-student`, with the permission `read` on `mdmc-open`, and no expiry date.

You can see the permissions of a role that you have:

```bash
rucio role permission list mdmc-student
```

But you cannot see all the roles:

```bash
rucio role list
```

Expected result: an access error. Only administrators can see all roles.

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

> Stop here and wait for the instructor.

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

But the role gives **read** access only:

```bash
rucio did add --type dataset mdmc-embargo:$ME-copy
```

Expected result: an access error. Only the owner of `mdmc-embargo` can change it.

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
| What does a role give? | `read` on a scope pattern (`mdmc-open`, or `mdmc-*` for all scopes that start with `mdmc-`) |
| What does the owner of a scope have? | Full access to the scope, with no role |
| Can a user see data that they cannot read? | No. The scope and its DIDs are hidden, also inside other datasets |

**Exercise 4.1 (discussion).** In your own field, think of one dataset that needs a non-assignable role with an expiry date, and one that only needs an assignable role. What is the difference?

Next: [5. Wrap-up](05-wrap-up.md)
