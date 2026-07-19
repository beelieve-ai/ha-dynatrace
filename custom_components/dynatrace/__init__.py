"""Push numeric Home Assistant entity states to Dynatrace (Metrics Ingest v2)."""

from __future__ import annotations

import logging
from datetime import timedelta

import aiohttp

from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.aiohttp_client import async_get_clientsession
from homeassistant.helpers.event import async_track_time_interval

from .const import CONF_API_TOKEN, CONF_ENVIRONMENT_URL, INGEST_PATH

_LOGGER = logging.getLogger(__name__)

# ponytail: fixed 60s push interval and one hardcoded metric key; add options
# flow when someone needs tuning or entity filtering.
PUSH_INTERVAL = timedelta(seconds=60)
BATCH_SIZE = 1000  # ingest API line limit per request


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    session = async_get_clientsession(hass)
    url = entry.data[CONF_ENVIRONMENT_URL].rstrip("/") + INGEST_PATH
    headers = {
        "Authorization": f"Api-Token {entry.data[CONF_API_TOKEN]}",
        "Content-Type": "text/plain; charset=utf-8",
    }

    async def push(_now=None) -> None:
        lines = []
        for state in hass.states.async_all():
            try:
                value = float(state.state)
            except (ValueError, TypeError):
                continue
            domain = state.entity_id.split(".", 1)[0]
            lines.append(
                f'homeassistant.entity.state,entity_id="{state.entity_id}",domain="{domain}" {value}'
            )
        for i in range(0, len(lines), BATCH_SIZE):
            body = "\n".join(lines[i : i + BATCH_SIZE])
            try:
                resp = await session.post(
                    url,
                    data=body,
                    headers=headers,
                    timeout=aiohttp.ClientTimeout(total=30),
                )
                if resp.status >= 400:
                    _LOGGER.warning(
                        "Dynatrace metrics ingest failed: HTTP %s: %s",
                        resp.status,
                        await resp.text(),
                    )
            except aiohttp.ClientError as err:
                _LOGGER.warning("Dynatrace metrics ingest failed: %s", err)

    entry.async_on_unload(async_track_time_interval(hass, push, PUSH_INTERVAL))
    hass.async_create_task(push())
    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    return True
