# Changelog

## 1.1.0

- Add `installer_arch` dropdown (aarch64/amd64, default aarch64) selecting
  the OneAgent installer architecture.
- Ship tar/gzip in the image so the installer can self-extract into the
  container-as-host root.

## 1.0.0

- Initial release: Dynatrace OneAgent (infra-only by default) for Home
  Assistant OS on aarch64 and amd64.
