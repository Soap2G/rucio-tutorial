# Rucio tutorial: data management with roles

A 90-minute, hands-on introduction to [Rucio](https://rucio.cern.ch) from the command line, for first-time users from any discipline,
with a chapter on role-based access control (RBAC). First given for the SISSA Master in Data Management and Curation (MDMC).

**Students:** read the tutorial at **<https://rucio-tutorial.docs.cern.ch>**. The source of the pages is in [`docs/`](docs/index.md).

## Repository layout

| Path | Content |
|---|---|
| `docs/` | Tutorial pages (MkDocs). Built and published by GitLab CI with the CERN [mkdocs-ci](https://gitlab.cern.ch/authoring/documentation/mkdocs-ci) template. |
| `setup.sh` | Sets up a SWAN terminal: loads the Rucio RBAC client from CVMFS (`/cvmfs/sw.escape.eu/rucio/41.1.1-rbac-7273054bfdc4`). |
| Docker image | Second way to work, without SWAN: `hdemule/rucio-clients-rbac:7273054bfdc4` (the same client). The pages have a tab for each way ("CERN VRE (SWAN)" and "Docker image"). |
| `admin/` | For organisers: [preparation of the Rucio instance](admin/README.md) and [instructor guide](admin/INSTRUCTOR.md). Not published on the website. |

## Build the website locally

```bash
pip install mkdocs==1.6.1 mkdocs-material==9.7.7
mkdocs serve
```
