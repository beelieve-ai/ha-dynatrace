# Dynatrace for Home Assistant

Two complementary pieces for monitoring a Home Assistant OS installation with
[Dynatrace](https://www.dynatrace.com/), from one repository:

| Piece | What it monitors | Installed via |
|---|---|---|
| [**Dynatrace integration**](./custom_components/dynatrace) | Home Assistant entities — pushes all numeric entity states to Dynatrace every 60 s (Metrics Ingest v2) | **HACS** |
| [**Dynatrace OneAgent add-on**](./dynatrace-oneagent) | The HAOS host — CPU, memory, processes, network, logs via [OneAgent](https://www.dynatrace.com/platform/oneagent/) (aarch64/amd64) | Add-on store |

## Install the integration via HACS

[![Open your Home Assistant instance and add this repository to HACS](https://my.home-assistant.io/badges/hacs_repository.svg)](https://my.home-assistant.io/redirect/hacs_repository/?owner=beelieve-ai&repository=ha-dynatrace&category=integration)

1. Click the badge above, or in HACS: **⋮ → Custom repositories** → add
   `https://github.com/beelieve-ai/ha-dynatrace` with category **Integration**,
   then download **Dynatrace** and restart Home Assistant.
2. In Dynatrace, create an access token with the **metrics.ingest** scope.
3. Settings → Devices & services → **Add integration → Dynatrace**, enter your
   environment URL (e.g. `https://abc12345.live.dynatrace.com`) and the token.

Metrics arrive as `homeassistant.entity.state` with `entity_id` and `domain`
dimensions — chart them with e.g.
`homeassistant.entity.state:filter(eq(entity_id,sensor.living_room_temperature))`.

## Install the OneAgent add-on

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fbeelieve-ai%2Fha-dynatrace)

OneAgent is host-level software, which HACS (Python integrations only) cannot
deliver and the read-only HAOS cannot install natively — so the host side ships
as an add-on:

1. Click the badge above, or add this repository URL in Settings → Add-ons →
   Add-on store → ⋮ → Repositories.
2. Install **Dynatrace OneAgent** and configure your environment URL and PaaS
   token (see the add-on's Documentation tab).
3. **Disable Protection mode** on the add-on's Info tab — OneAgent needs host
   PID access, which the Supervisor only grants to unprotected add-ons.
4. Start the add-on.

Together, the add-on gives you the host's health and the integration gives you
your smart-home data — same Dynatrace environment, correlated in time.
