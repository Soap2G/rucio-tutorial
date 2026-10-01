# Instructor guide

## Timeline (90 min)

| Time | Chapter | Instructor action |
|---|---|---|
| 0:00 | 0 Concepts | Present the data model on the projector (chapter 0 diagram). |
| 0:10 | 1 Log in | Help with the OIDC login link. Typical problem: wrong account name. |
| 0:15 | 2 Explore | Show `rucio rse list --rses` live. |
| 0:30 | 3 Manage | **Upload demo** (below) at 3.7. Show a rule going from `REPLICATING` to `OK`. |
| 0:55 | 4 RBAC | At 4.3, wait until everybody has seen the error. Then run `./embargo_access.sh grant 15`. |
| 1:10 | 4.7 | When the 15 minutes end (or run `./embargo_access.sh end`), students check 4.7. |
| 1:20 | 5 Wrap-up | Discussion of exercise 4.1. Feedback. |

## Day before

1. `./05_students.sh`: all accounts, scopes, quotas and the `mdmc-student` role are present.
2. `./06_check.sh`: all lines are `OK`.
3. Log in with a test student account in SWAN and do chapters 1 and 2 quickly. This tests CVMFS, the login and the download in the real environment.

## Upload demo (chapter 3.7)

The students cannot write to the storage. You show `rucio upload` with an account that has write access to the EOS path (for example your own account with your grid proxy).

```bash
echo "station,date,value" > demo-result.csv
rucio upload --rse TRIESTE_DISK --scope <your scope> --lifetime 86400 demo-result.csv
rucio did show <your scope>:demo-result.csv
rucio replica list file <your scope>:demo-result.csv --pfns
rucio rule list --did <your scope>:demo-result.csv
```

Points to make: the upload makes the file DID, the replica and a rule in one step, and Rucio computes the checksum.

## RBAC (chapter 4)

```bash
cd admin
./embargo_access.sh grant 15   # gives mdmc-embargo-reader to all students for 15 minutes
./embargo_access.sh end        # ends it now
```

Points to make:

- `mdmc-student` is assignable: IAM controls it. `mdmc-embargo-reader` is not assignable: only a Rucio administrator controls it, and the IAM sync never changes it.
- The roles are **locked**: their permissions cannot change by mistake during the course.
- After the expiry, files from `mdmc-embargo` disappear also from the students' own datasets (4.7).
- A download is outside Rucio's control (4.7 note): this is the link to data agreements.

## Known limits of this RBAC version

Say them only if students ask.

- Role permissions control `read`. Creating or changing DIDs still needs scope ownership. `write` permissions exist in the data model, but this version does not check them.
- `rucio rule add` does not check `read` access to the scope of the DID.
