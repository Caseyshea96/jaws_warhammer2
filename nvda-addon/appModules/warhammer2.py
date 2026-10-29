"""Keep NVDA quiet inside Warhammer II while the external companion speaks."""

import appModuleHandler


class AppModule(appModuleHandler.AppModule):
	"""Disable NVDA object events and scripts only while Warhammer2.exe is focused."""

	sleepMode = True
