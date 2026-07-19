"""Config flow for the Dynatrace integration."""

from __future__ import annotations

from typing import Any

import aiohttp
import voluptuous as vol

from homeassistant import config_entries
from homeassistant.helpers.aiohttp_client import async_get_clientsession

from .const import CONF_API_TOKEN, CONF_ENVIRONMENT_URL, DOMAIN, INGEST_PATH

SCHEMA = vol.Schema(
    {
        vol.Required(CONF_ENVIRONMENT_URL): str,
        vol.Required(CONF_API_TOKEN): str,
    }
)


class DynatraceConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    VERSION = 1

    async def async_step_user(self, user_input: dict[str, Any] | None = None):
        errors: dict[str, str] = {}
        if user_input is not None:
            url = user_input[CONF_ENVIRONMENT_URL].rstrip("/")
            session = async_get_clientsession(self.hass)
            try:
                resp = await session.post(
                    url + INGEST_PATH,
                    data='homeassistant.integration.heartbeat,source="config_flow" 1',
                    headers={
                        "Authorization": f"Api-Token {user_input[CONF_API_TOKEN]}",
                        "Content-Type": "text/plain; charset=utf-8",
                    },
                    timeout=aiohttp.ClientTimeout(total=15),
                )
                if resp.status == 202:
                    await self.async_set_unique_id(url)
                    self._abort_if_unique_id_configured()
                    return self.async_create_entry(
                        title=url.removeprefix("https://"),
                        data={
                            CONF_ENVIRONMENT_URL: url,
                            CONF_API_TOKEN: user_input[CONF_API_TOKEN],
                        },
                    )
                errors["base"] = (
                    "invalid_auth" if resp.status in (401, 403) else "cannot_connect"
                )
            except aiohttp.ClientError:
                errors["base"] = "cannot_connect"
        return self.async_show_form(
            step_id="user", data_schema=SCHEMA, errors=errors
        )
