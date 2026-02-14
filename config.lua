-- config.lua
-- Dynamically selects the host configuration based on machine hostname
-- or environment variable

local uname = io.popen("hostname"):read("*l")  -- get current hostname

local host_map = {
    ["Ryzen5900x"] = "Ryzen5900x",
    ["ThinkPad"]   = "ThinkPad",
}

local host_name = host_map[uname]

if not host_name then
    error("No host configuration found for hostname: " .. uname)
end

return {
    host = host_name
}
