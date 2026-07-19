#!/bin/bash
# Wraps the stock dynatrace/oneagent entrypoint for Home Assistant OS.
set -e

OPTS=/data/options.json
opt() { jq -r ".$1 // empty" "${OPTS}"; }

if [ ! -r "${OPTS}" ]; then
	echo "ERROR: Home Assistant add-on options are not readable at ${OPTS}." >&2
	exit 1
fi

ENV_URL="$(opt environment_url)"
ENV_URL="${ENV_URL%/}"
TOKEN="$(opt paas_token)"
MODE="$(opt monitoring_mode)"
INSTALLER_ARCH="$(opt installer_arch)"
LOG_MONITORING="$(opt log_monitoring)"
HOST_GROUP="$(opt host_group)"
ADDITIONAL_ARGS="$(opt additional_args)"

if [ -z "${ENV_URL}" ] || [ -z "${TOKEN}" ]; then
	echo "ERROR: 'environment_url' and 'paas_token' must be set in the add-on configuration." >&2
	exit 1
fi

# Map HA arch names to Dynatrace installer arch families.
case "${INSTALLER_ARCH:-aarch64}" in
	amd64) DT_ARCH=x86 ;;
	*) DT_ARCH=arm ;;
esac
export ONEAGENT_INSTALLER_SCRIPT_URL="${ENV_URL}/api/v1/deployment/installer/agent/unix/default/latest?arch=${DT_ARCH}&flavor=default"
export ONEAGENT_INSTALLER_DOWNLOAD_TOKEN="${TOKEN}"

# Persist agent state in the add-on's /data volume so the host entity survives
# add-on updates (container rebuilds): bind the agent's default install/config/
# log paths onto /data. Deliberately NOT using ONEAGENT_ENABLE_VOLUME_STORAGE —
# with ONEAGENT_NO_REMOUNT_ROOT the bootstrap skips mountBasicDirectories and
# never pre-creates the storage skeleton, yet still writes ConfigDir=/data/...
# into dockerdeployment.conf, which the installer can't mkdir and fails on.
# With volume storage off, the installer uses its default paths, which resolve
# through these binds into /data. Dir names kept from the volume-storage layout
# so state from earlier add-on versions is reused.
STORAGE=/data/storage/dynatrace_oneagent_storage
for pair in \
	opt:/opt/dynatrace/oneagent \
	var:/var/lib/dynatrace/oneagent \
	var_enrichment:/var/lib/dynatrace/enrichment \
	var_log:/var/log/dynatrace/oneagent; do
	src="${STORAGE}/${pair%%:*}" dst="${pair#*:}"
	mkdir -p "${src}" "${dst}"
	mountpoint -q "${dst}" || mount --bind "${src}" "${dst}"
done

# OneAgent does not reliably create this hierarchy when upgrading an existing
# container deployment. Create it through the bind mount so deployment.conf,
# monitoringmode.conf and the other generated settings always land on the
# Supervisor-managed /data volume, never in the disposable container layer.
CONFIG_DIR=/var/lib/dynatrace/oneagent/agent/config
mkdir -p \
	"${CONFIG_DIR}" \
	/var/lib/dynatrace/oneagent/agent/watchdog \
	/var/lib/dynatrace/enrichment \
	/var/log/dynatrace/oneagent

if [ ! -d "${STORAGE}/var/agent/config" ]; then
	echo "ERROR: OneAgent configuration storage was not created under ${STORAGE}." >&2
	exit 1
fi
echo "OneAgent configuration persists at ${STORAGE}/var/agent/config"

# The Supervisor cannot bind-mount the host root filesystem into an add-on,
# and the HAOS root is read-only squashfs anyway. So the agent's "host root"
# is this container's own filesystem, while PID/NET/IPC namespaces are shared
# with the host: processes, CPU, memory and network metrics are the real host,
# only the filesystem view is the container's.
# ponytail: no host-root mount possible under Supervisor; a native install on
# HAOS would need Dynatrace to ship a HAOS OS agent — no upgrade path from here.
mkdir -p /mnt/root
mountpoint -q /mnt/root || mount --rbind / /mnt/root

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
