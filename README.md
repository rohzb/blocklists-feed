# blocklists-feed

This repository builds malware-focused upstream IP feeds into flat, directly usable output files.
Most behavior (paths, chunk size, output mapping) is configured in YALIC via `config/feeds.yaml`.

## Directory Layout

- `config/`
  - YALIC v0.3 config only (`config/feeds.yaml`)
- `feeds/manual/`
  - manually managed input lists (including whitelists)
- `feeds/upstream/`
  - downloaded upstream snapshot content and metadata
- `feeds/result/`
  - generated result files intended for direct consumption
- `mikrotik/routeros/`
  - RouterOS helper scripts for consuming YALIC outputs

## Result Files

The build writes flat files into `feeds/result/`:

- `malware.netset`
- `malware.bundle/`
  - `index.txt`
  - `block-XXXX.ipset`

After renaming targets/configs, older artifacts (for example `malware-feeds.*`)
may still exist until the next build refreshes outputs.

## RouterOS Bundle Consumer

Use `mikrotik/routeros/yalic_bundle_update.rsc`
to download and apply `malware.bundle` outputs from an HTTP/HTTPS endpoint.
Bundle block lines are plain ipset/netset values, and `# ...` comments are
allowed.

Example on RouterOS:

```routeros
/import file-name=yalic_bundle_update.rsc
$yalicBundleUpdate
```

Set `listName` and `bundleBaseUrl` inside the script before running.

## Run

Docker mode:

```bash
./scripts/update-blocklists.sh
```

Local mode:

```bash
YALIC_MODE=local ./scripts/update-blocklists.sh
```

Local mode against repo-local YALIC source (without reinstalling into `.venv`):

```bash
YALIC_MODE=local YALIC_LOCAL_SOURCE=1 ./scripts/update-blocklists.sh
```

Optional image override:

```bash
YALIC_IMAGE=ghcr.io/rohzb/yalic:v0.3.1 ./scripts/update-blocklists.sh
```

## Automation

GitHub Actions runs every 6 hours and on manual trigger.
If generated outputs changed, it commits and pushes files under `feeds/`.
