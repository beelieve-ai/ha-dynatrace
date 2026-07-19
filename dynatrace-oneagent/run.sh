#!/bin/bash
# Wraps the stock dynatrace/oneagent entrypoint for Home Assistant OS.
set -e

OPTS=/data/options.json
opt() { jq -r ".$1 // empty" "${OPTS}"; }

ENV_URL="$(opt environment_url)"
ENV_URL="${ENV_URL%/}"
TOKEN="$(opt paas_token)"
MODE="$(opt monitoring_mode)"
LOG_MONITORING="$(opt log_monitoring)"
HOST_GROUP="$(opt host_group)"
ADDITIONAL_ARGS="$(opt additional_args)"

if [ -z "${ENV_URL}" ] || [ -z "${TOKEN}" ]; then
	echo "ERROR: 'environment_url' and 'paas_token' must be set in the add-on configuration." >&2
	exit 1
fi

# <arch> is substituted by the upstream bootstrap (arm/x86 auto-detected).
export ONEAGENT_INSTALLER_SCRIPT_URL="${ENV_URL}/api/v1/deployment/installer/agent/unix/default/latest?arch=<arch>&flavor=default"
export ONEAGENT_INSTALLER_DOWNLOAD_TOKEN="${TOKEN}"

# The Supervisor cannot bind-mount the host root filesystem into an add-on,
# and the HAOS root is read-only squashfs anyway. So the agent's "host root"
# is this container's own filesystem, while PID/NET/IPC namespaces are shared
# with the host: processes, CPU, memory and network metrics are the real host,
# only the filesystem view is the container's.
# ponytail: no host-root mount possible under Supervisor; a native install on
# HAOS would need Dynatrace to ship a HAOS OS agent — no upgrade path from here.
mkdir -p /mnt/root
mountpoint -q /mnt/root || mount --rbind / /mnt/root

# Persist agent data storage in the add-on's /data volume so the host entity
# survives add-on updates (container rebuilds). The path is resolved relative
# to the agent's host root, which is this container's fs — i.e. /data/storage.
export ONEAGENT_ENABLE_VOLUME_STORAGE=true
export ONEAGENT_CONTAINER_STORAGE_PATH=/data/storage
mkdir -p /data/storage

# Our fake host root is the container fs itself — remounting is pointless,
# and deep injection into other containers cannot work without the real host fs.
export ONEAGENT_NO_REMOUNT_ROOT=true
export ONEAGENT_DISABLE_CONTAINER_INJECTION=true

ARGS=("--set-monitoring-mode=${MODE}" "--set-app-log-content-access=${LOG_MONITORING:-true}")
[ -n "${HOST_GROUP}" ] && ARGS+=("--set-host-group=${HOST_GROUP}")
# ponytail: word-split on purpose — additional_args is a space-separated list
# shellcheck disable=SC2206
[ -n "${ADDITIONAL_ARGS}" ] && ARGS+=(${ADDITIONAL_ARGS})

exec /bin/bash /tmp/entrypoint.sh "${ARGS[@]}"
