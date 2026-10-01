# 1. Log in (5 min)

You did `source setup.sh <account>` in the [README](../README.md). If not, do it now.

## 1.1 Who am I?

```bash
rucio whoami
```

The first time, Rucio shows a link. Open it in your browser, log in with your IAM account, and accept.
The terminal waits and then continues by itself.

Expected result:

```
status     : ACTIVE
account    : <account>
account_type : USER
...
```

Rucio keeps a token, so you do not log in again for some hours.

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
| `Cannot authenticate` | Login not done or token expired | Run `rucio whoami` again and use the link |
| `Account ... does not exist` | Wrong account name, or your account is not created yet | Check your IAM username; ask the instructor |
| `command not found: rucio` | The terminal is not set up | `source setup.sh <account>` |

Next: [2. Explore the data](02-explore.md)
