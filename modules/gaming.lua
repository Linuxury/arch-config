local packages = {
    "steam",
    "faugus-launcher",
    "heroic",
    "wine",
    "wine-mono",
    "winetricks",
    "gamemode",
    "lib32-gamemode",
    "mangohud",
    "lib32-mangohud",
    "discord",  -- native
}

local services = {
    enabled = { "gamemode.service" },
    disabled = {},
}

return {
    description = "Gaming environment (Steam, Faugus, Heroic, native Discord, Wine, gamemode/MangoHUD)",
    packages = packages,
    services = services,
}
