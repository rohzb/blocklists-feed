# blocklists-feed

There are many public blocklists online, but I could not find the exact shape I wanted for quick reuse.
So this repo does one small job: fetch selected sources and write ready-to-use `hosts` files.

## What it creates

| File | Description |
| --- | --- |
| `adlists/cuii.hosts` | Hosts file generated from the https://cuiiliste.de/ list of blocked domains. |
| `adlists/combined.hosts` | Combined hosts file. |

Each line is in this format:

```text
0.0.0.0 example.com
```

## Run locally

Requirements: `bash`, `curl`, `jq`, `awk`, `sort`

```bash
./scripts/update-adlists.sh
```

## Automation

GitHub Actions runs every 6 hours and on manual trigger.
If generated files changed, it commits and pushes them.
