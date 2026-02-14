-- Hardware detection module
-- Automatically installs drivers based on detected hardware

local packages = {}
local description_parts = {}

-- ═══════════════════════════════════════════════════════════════════
-- GPU DRIVERS
-- ═══════════════════════════════════════════════════════════════════

if dcli.hardware.has_nvidia() then
    dcli.log.info("NVIDIA GPU detected")
    table.insert(description_parts, "NVIDIA")

    -- Proprietary drivers
    table.insert(packages, "nvidia")
    table.insert(packages, "nvidia-utils")
    table.insert(packages, "nvidia-settings")
    table.insert(packages, "lib32-nvidia-utils")
end

if dcli.hardware.has_amd_gpu() then
    dcli.log.info("AMD GPU detected")
    table.insert(description_parts, "AMD GPU")

    table.insert(packages, "mesa")
    table.insert(packages, "vulkan-radeon")
    table.insert(packages, "lib32-vulkan-radeon")
    table.insert(packages, "libva-mesa-driver")
end

if dcli.hardware.has_intel_gpu() then
    dcli.log.info("Intel GPU detected")
    table.insert(description_parts, "Intel GPU")

    table.insert(packages, "mesa")
    table.insert(packages, "vulkan-intel")
    table.insert(packages, "intel-media-driver")
end

-- ═══════════════════════════════════════════════════════════════════
-- LAPTOP PACKAGES
-- ═══════════════════════════════════════════════════════════════════

if dcli.hardware.is_laptop() then
    dcli.log.info("Laptop detected - adding power management")
    table.insert(description_parts, "Laptop")

    table.insert(packages, "tlp")
    table.insert(packages, "tlp-rdw")
    table.insert(packages, "powertop")
    table.insert(packages, "acpi")
end

-- Build description
local description = "Hardware drivers"
if #description_parts > 0 then
    description = description .. " (" .. table.concat(description_parts, ", ") .. ")"
end

-- Services for laptop
local services = { enabled = {}, disabled = {} }
if dcli.hardware.is_laptop() then
    table.insert(services.enabled, "tlp.service")
    table.insert(services.disabled, "power-profiles-daemon.service")
end

return {
    description = description,
    packages = packages,
    services = services,
}
