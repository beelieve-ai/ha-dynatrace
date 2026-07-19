# beelieve.ai Home Assistant Add-ons

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fbeelieve-ai%2Fha-dynatrace)

## Add-ons

### [Dynatrace OneAgent](./dynatrace-oneagent)

Runs [Dynatrace OneAgent](https://www.dynatrace.com/platform/oneagent/) as a
Home Assistant OS add-on to monitor your Home Assistant host (aarch64/amd64):
host CPU, memory, processes, network, and logs, reported to your Dynatrace
environment.

> **Why an add-on and not HACS?** HACS installs Python integrations into Home
> Assistant Core. OneAgent is host-level software and Home Assistant OS is a
> locked-down, read-only OS — the only supported way to run extra system
> software on it is an add-on container. Installation is still one click via
> the button above (Settings → Add-ons → Add-on store → ⋮ → Repositories also
> works).

## Installation

1. Click the badge above, or add `https://github.com/beelieve-ai/ha-dynatrace`
   as an add-on repository in Settings → Add-ons → Add-on store → ⋮ →
   Repositories.
2. Install **Dynatrace OneAgent** from the store.
3. Configure your Dynatrace environment URL and PaaS token (see the add-on's
   Documentation tab).
4. **Disable Protection mode** on the add-on's Info tab — OneAgent needs host
   PID access, which the Supervisor only grants to unprotected add-ons.
5. Start the add-on.
