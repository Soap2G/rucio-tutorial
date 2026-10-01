# 5. Wrap-up (10 min)

## What you did

| Data curation idea | What you did in Rucio |
|---|---|
| Persistent identifiers | Each file, dataset and container has a unique `scope:name` that is never reused |
| Integrity | Rucio knows the checksum of each file and checks it at each copy and download |
| Description | Metadata on datasets (`rucio did metadata`) |
| Preservation | Rules keep N copies in selected places (`country=CH&type=DISK`); a "preservation copy" on an archive RSE |
| Lifecycle | Rules with a lifetime; Rucio deletes the replicas that no rule needs |
| Fair use of resources | Quotas per account and RSE |
| Access control | Ownership of scopes, plus roles with expiry dates, synchronised with the identity provider |

## Clean up

Your rules expire after one day. You can remove them now:

```bash
rucio rule list --account $ME
rucio rule remove <rule id>
```

Your datasets stay in your scope. A DID name is never reused, also after deletion.

## More information

- Rucio documentation: <https://rucio.github.io/documentation/>
- Rucio project: <https://rucio.cern.ch>
- Paper: M. Barisits et al., *Rucio: Scientific Data Management*, Comput Softw Big Sci 3, 11 (2019). <https://doi.org/10.1007/s41781-019-0026-3>

## Feedback

Tell the instructor what was clear and what was not. Thank you!
