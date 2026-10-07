# 1. Log in (5 min)

You did `source setup.sh <account>` on the [home page](index.md). If not, do it now.

## 1.1 Who am I?

```bash
rucio whoami
```

The first time, Rucio shows a link. Open it in your browser, log in with your IAM account, and accept.
The terminal waits and then continues by itself. You have about **3 minutes**. If the time ends, the terminal says
`Cannot retrieve authentication token!`. Run the command again and use the new link.

Expected result (the order of the lines can be different; `email` can be `None`):

```
account_type : USER
account    : <account>
suspended_at : None
email      : <your email>
status     : ACTIVE
created_at : ...
deleted_at : None
updated_at : ...
```

The line `account` must show your Rucio account, and `status` must be `ACTIVE`.

Rucio keeps a token for about **one hour**. After that, the next `rucio` command shows a new login link. Open it again.
In a long session this happens more than once.

## 1.2 Is the server there?

```bash
rucio ping
```

Expected result: the server version, for example `41.1.1`.

## 1.3 Get help

Each command has help:

```bash
rucio --help
rucio did --help
rucio rule add --help
```

The CLI has the form `rucio <object> <action>`, for example `rucio did list` or `rucio rule add`.

## If something goes wrong

| Message | Cause | What to do |
|---|---|---|
| `Cannot retrieve authentication token!` | You did not finish the login in 3 minutes | Run the command again and open the link at once |
| A login link appears, but you logged in less than an hour ago | Some commands that are **refused** (for example creating a DID in a scope that is not yours) look like an expired login to the client | Press `Ctrl+C`. Do not log in again: the command is not allowed for your account |
| The account cannot be found or does not exist | Wrong account name, or your account is not created yet | Check your IAM username; ask the instructor |
| `command not found: rucio` | The terminal is not set up | `source setup.sh <account>` |

Next: [2. Explore the data](02-explore.md)
