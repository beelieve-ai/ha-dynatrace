# Changelog

## 1.1.2

- Fix installer failing with "No such file or directory" under
  `/data/storage/dynatrace_oneagent_storage/var/agent/config`: volume storage
  is now disabled entirely. With `ONEAGENT_NO_REMOUNT_ROOT` the image
  bootstrap skips the mount phase that pre-creates the storage skeleton, yet
  still points the installer's `ConfigDir` at the bare storage path, which it
  cannot create. run.sh instead bind-mounts the agent's default paths
  (`/opt/dynatrace/oneagent`, `/var/lib/dynatrace/{oneagent,enrichment}`,
  `/var/log/dynatrace/oneagent`) onto `/data` itself — same persistence,
  installer stays on its default, well-tested paths.

## 1.1.0

- Add `installer_arch` dropdown (aarch64/amd64, default aarch64) selecting
  the OneAgent installer architecture.
- Ship tar/gzip in the image so the installer can self-extract into the
  container-as-host root.

## 1.0.0

- Initial release: Dynatrace OneAgent (infra-only by default) for Home
  Assistant OS on aarch64 and amd64.
