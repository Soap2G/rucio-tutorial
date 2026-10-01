# Rucio CLI cheatsheet

| Task | Command |
|---|---|
| Who am I | `rucio whoami` |
| List RSEs (optional expression) | `rucio rse list [--rses 'country=IT&type=DISK']` |
| RSE attributes | `rucio rse attribute list <RSE>` |
| Scopes I can read | `rucio scope list` |
| List datasets and containers | `rucio did list '<scope>:*'` |
| Content of a collection | `rucio did content list <scope>:<name>` |
| Details of a DID | `rucio did show <scope>:<name>` |
| Metadata | `rucio did metadata list <did>` / `rucio did metadata set <did> --key K --value V` |
| Replicas of a dataset | `rucio replica list dataset <did>` |
| Replicas of a file, with addresses | `rucio replica list file <did> --pfns` |
| Download | `rucio download <did> [--rses <expr>] [--nrandom N] [--impl webdav]` |
| New dataset | `rucio did add --type dataset <my-scope>:<name>` |
| Add files to a dataset | `rucio did content add --to-did <dataset> <did> [<did> ...]` |
| Close a dataset | `rucio did update --close <dataset>` |
| New rule | `rucio rule add <did> --copies N --rses '<expr>' --lifetime <seconds>` |
| Rule state | `rucio rule show <rule-id>` (`--examine` for transfer errors) |
| My rules | `rucio rule list --account $ME` |
| Rules for a DID (and its parents) | `rucio rule list --did <did> --traverse` |
| Remove a rule | `rucio rule remove <rule-id>` |
| Quota and usage | `rucio account limit list $ME` |
| My roles | `rucio role account list --me --detail` |
| Permissions of my role | `rucio role permission list <role>` |

## RSE expressions

| Expression | Meaning |
|---|---|
| `TRIESTE_DISK` | one RSE |
| `country=IT` | all RSEs with the attribute `country=IT` |
| `A&B` | in A and in B |
| `A\|B` | in A or in B |
| `A\B` | in A but not in B |

## Lifetimes

| Seconds | Duration |
|---|---|
| 3600 | 1 hour |
| 86400 | 1 day |
| 604800 | 1 week |
