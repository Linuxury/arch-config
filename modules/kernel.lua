local packages = {
    "linux-zen",   -- default kernel
}

-- Optional RC kernel
if dcli.util.option_enabled("rc_kernel") then
    table.insert(packages, "linux-rc")
end

return {
    description = "Kernel packages (Zen default, optional RC)",
    packages = packages,
}
