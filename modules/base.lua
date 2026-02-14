local packages = {
    "base",
    "base-devel",
    "bluez",
    "bluez-utils",
    "flatpak",
    "snapper",
    "networkmanager",
}

-- CPU microcode
local cpu = dcli.hardware.cpu_vendor()
if cpu == "intel" then
    dcli.log.info("Intel CPU detected - adding intel-ucode")
    table.insert(packages, "intel-ucode")
elseif cpu == "amd" then
    dcli.log.info("AMD CPU detected - adding amd-ucode")
    table.insert(packages, "amd-ucode")
end

local services = {
    enabled = {
        "NetworkManager.service",
        "bluetooth.service",
    },
    disabled = {},
}

return {
    description = "Base system packages",
    packages = packages,
    services = services,
}
