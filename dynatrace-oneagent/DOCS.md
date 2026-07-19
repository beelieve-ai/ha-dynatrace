# Dynatrace OneAgent add-on

Runs Dynatrace OneAgent in a container that shares the host's PID, network,
and IPC namespaces, so your Home Assistant OS host shows up in Dynatrace with
real host processes, CPU, memory, and network metrics.

## Prerequisites

- A Dynatrace environment (SaaS or Managed).
- A **PaaS token**: in Dynatrace, open **Access tokens** and create a token
  with the **PaaS integration — Installer download**
  (`InstallerDownload`) scope.

## Configuration

| Option | Required | Description |
|---|---|---|
| `environment_url` | yes | Your environment base URL, e.g. `https://abc12345.live.dynatrace.com` (SaaS) or `https://<your-domain>/e/<environment-id>` (Managed). No trailing slash needed. |
| `paas_token` | yes | The PaaS token with installer download scope. |
| `monitoring_mode` | yes | `infra-only` (default), `fullstack`, or `discovery`. See below. |
| `log_monitoring` | yes | Allow OneAgent to access log contents (`--set-app-log-content-access`). Default `true`. |
| `host_group` | no | Dynatrace host group for this host, e.g. `home_assistant`. |
| `additional_args` | no | Extra space-separated OneAgent installer parameters, e.g. `--set-network-zone=home --set-proxy=...`. |

Example:

```yaml
environment_url: https://abc12345.live.dynatrace.com
paas_token: dt0c01.XXXX...
monitoring_mode: infra-only
log_monitoring: true
host_group: home_assistant
```

## Full host access and Protection mode

After installing, open the add-on's **Info** tab and switch **Protection
mode** off, then start the add-on. The add-on declares Supervisor
`full_access`, which is the Home Assistant equivalent of Docker privileged
mode required by Dynatrace's containerized OneAgent. It also needs the host
PID namespace. Supervisor grants both only to unprotected add-ons. Without
this, the add-on will not see or fully inspect host processes.

## How it works, and known limits

Home Assistant OS is a read-only OS and the Supervisor cannot mount the host
root filesystem into an add-on. This add-on therefore runs OneAgent with:

- **Shared host PID/network/IPC namespaces** — process list, CPU, memory,
  and network metrics are the real host's.
- **Supervisor full access** — the OneAgent container runs with the privileged
  access Dynatrace requires for host and container process monitoring. The
  required Linux capabilities are also declared explicitly for Supervisor
  versions that do not retain them from `full_access` alone.
- **The add-on container's filesystem as the agent's root** — filesystem
  metrics reflect the add-on container (which lives on the HAOS data
  partition), not the whole host disk layout.
- **Persistent agent storage in `/data`** — the host entity survives add-on
  updates.

Home Assistant supplies the add-on configuration as `/data/options.json`.
OneAgent's generated configuration files are written through a bind mount from
`/var/lib/dynatrace/oneagent/agent/config` to the persistent add-on path
`/data/storage/dynatrace_oneagent_storage/var/agent/config`. Both the add-on
settings and OneAgent identity/configuration therefore survive restarts,
rebuilds, and upgrades.

Because the real host filesystem is not reachable:

- **Deep code-level injection into other containers (Home Assistant Core,
  other add-ons) does not work.** `infra-only` is the default and recommended
  mode; `fullstack` will only deep-monitor processes inside this add-on's own
  container.
- The OneAgent installer is re-downloaded from your environment when the
  add-on is rebuilt (updates), not on every start.

## Architecture support

`aarch64` (Raspberry Pi 4/5, ODROID, …) and `amd64`. Select the matching
OneAgent installer architecture in the add-on configuration
(`installer_arch`, default `aarch64`).
