local is_laptop = dcli.hardware.is_laptop()
local memory_mb = dcli.system.memory_total_mb()

dcli.log.info(string.format("Loading config for Ryzen5900x (%d MB RAM)", memory_mb))

local enabled_modules = {
    "base",
    "hardware",
    "kernel",
    "cosmic",
    "dev",
    "gaming",
}

local services = {
    enabled = {},
    disabled = {},
}

return {
    host = "Ryzen5900x",
    description = "Ryzen5900x",

    enabled_modules = enabled_modules,
    packages = {},
    exclude = {},
    services = services,

    default_apps = {
        browser = "firefox",
        terminal = "ghostty",
        text_editor = "zed",
        file_manager = "com.system76.CosmicFiles",
    },

    flatpak_scope = "user",
    auto_prune = false,
    module_processing = "parallel",
    aur_helper = "paru",

    config_backups = {
        enabled = true,
        max_backups = 5,
    },

    system_backups = {
        enabled = true,
        backup_on_sync = true,
        backup_on_update = true,
        tool = "snapper",
        snapper_config = "root",
    },
}
