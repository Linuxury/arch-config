---@meta
-- dcli Lua API type definitions
-- This file provides type hints for editors/IDEs

---@class dcli
---@field hardware dcli.hardware
---@field system dcli.system
---@field package dcli.package
---@field file dcli.file
---@field env dcli.env
---@field util dcli.util
---@field log dcli.log
---@field service dcli.service
---@field power dcli.power
---@field security dcli.security
---@field desktop dcli.desktop
---@field boot dcli.boot
---@field network dcli.network
---@field audio dcli.audio
---@field storage dcli.storage
dcli = {}

---@class dcli.hardware
---@field cpu_vendor fun(): string Returns "intel", "amd", or "unknown"
---@field gpu_vendors fun(): string[] Returns array of GPU vendors
---@field has_nvidia fun(): boolean Check if NVIDIA GPU is present
---@field has_amd_gpu fun(): boolean Check if AMD GPU is present
---@field has_intel_gpu fun(): boolean Check if Intel GPU is present
---@field is_laptop fun(): boolean Check if system is a laptop
---@field has_battery fun(): boolean Check if battery is present
---@field chassis_type fun(): string Returns "desktop", "laptop", "server", "tablet", or "unknown"
dcli.hardware = {}

---@class dcli.system
---@field hostname fun(): string Get system hostname
---@field kernel_version fun(): string Get kernel version
---@field arch fun(): string Get system architecture
---@field os fun(): string Get operating system
---@field distro fun(): string Get distribution ID
---@field distro_name fun(): string Get full distribution name
---@field distro_version fun(): string Get distribution version
---@field memory_total_mb fun(): number Get total RAM in MB
---@field cpu_cores fun(): number Get number of CPU cores
dcli.system = {}

---@class dcli.package
---@field is_installed fun(name: string): boolean Check if package is installed
---@field version fun(name: string): string|nil Get package version
---@field is_available fun(name: string): boolean Check if package is in repos
---@field repo fun(name: string): string|nil Get package repository
---@field is_foreign fun(name: string): boolean Check if package is from AUR
---@field list_installed fun(): string[] Get all installed packages
---@field list_explicit fun(): string[] Get explicitly installed packages
---@field flatpak_installed fun(id: string): boolean Check if flatpak is installed
---@field flatpak_version fun(id: string): string|nil Get flatpak version
---@field aur_available fun(name: string): boolean Check if package is in AUR
dcli.package = {}

---@class dcli.file
---@field exists fun(path: string): boolean Check if file/directory exists
---@field is_file fun(path: string): boolean Check if path is a file
---@field is_dir fun(path: string): boolean Check if path is a directory
---@field read fun(path: string): string|nil Read file contents (sandboxed)
---@field read_lines fun(path: string): string[]|nil Read file as lines (sandboxed)
dcli.file = {}

---@class dcli.env
---@field get fun(name: string): string|nil Get environment variable
---@field home fun(): string Get home directory
---@field user fun(): string Get current username
---@field config_dir fun(): string Get XDG config directory
---@field data_dir fun(): string Get XDG data directory
---@field cache_dir fun(): string Get XDG cache directory
---@field shell fun(): string Get user's default shell
dcli.env = {}

---@class dcli.util
---@field contains fun(tbl: table, value: any): boolean Check if array contains value
---@field keys fun(tbl: table): any[] Get table keys
---@field values fun(tbl: table): any[] Get table values
---@field merge fun(t1: table, t2: table): table Merge tables (t2 overrides t1)
---@field extend fun(target: table, source: table): table Append source to target
---@field split fun(str: string, delim: string): string[] Split string by delimiter
---@field trim fun(str: string): string Remove leading/trailing whitespace
---@field starts_with fun(str: string, prefix: string): boolean Check string prefix
---@field ends_with fun(str: string, suffix: string): boolean Check string suffix
---@field version_compare fun(v1: string, v2: string): number Compare versions (-1, 0, 1)
---@field version_gte fun(v1: string, v2: string): boolean Check if v1 >= v2
---@field version_gt fun(v1: string, v2: string): boolean Check if v1 > v2
---@field version_lte fun(v1: string, v2: string): boolean Check if v1 <= v2
---@field version_lt fun(v1: string, v2: string): boolean Check if v1 < v2
dcli.util = {}

---@class dcli.log
---@field info fun(msg: string) Log info message
---@field warn fun(msg: string) Log warning message
---@field debug fun(msg: string) Log debug message
---@field error fun(msg: string) Log error message
dcli.log = {}

---@class dcli.service
---@field is_enabled fun(name: string): boolean Check if service is enabled
---@field is_active fun(name: string): boolean Check if service is active
---@field is_running fun(name: string): boolean Alias for is_active
---@field exists fun(name: string): boolean Check if service unit exists
---@field status fun(name: string): string Get service status
---@field list_enabled fun(): string[] Get enabled services
---@field list_active fun(): string[] Get active services
---@field list_failed fun(): string[] Get failed services
---@field is_user_service fun(name: string): boolean Check user service status
dcli.service = {}

---@class dcli.power
---@field on_battery fun(): boolean Check if on battery power
---@field on_ac fun(): boolean Check if on AC power
---@field battery_percent fun(): number|nil Get battery percentage
---@field battery_status fun(): string Get battery status
---@field has_suspend fun(): boolean Check suspend support
---@field has_hibernate fun(): boolean Check hibernate support
---@field cpu_governor fun(): string Get CPU governor
---@field available_governors fun(): string[] Get available governors
---@field supports_turbo fun(): boolean Check turbo boost support
---@field turbo_enabled fun(): boolean Check if turbo is enabled
dcli.power = {}

---@class dcli.security
---@field has_selinux fun(): boolean Check SELinux availability
---@field selinux_enabled fun(): boolean Check if SELinux is enabled
---@field has_apparmor fun(): boolean Check AppArmor availability
---@field apparmor_enabled fun(): boolean Check if AppArmor is enabled
---@field has_secureboot fun(): boolean Check Secure Boot support
---@field secureboot_enabled fun(): boolean Check if Secure Boot is enabled
---@field has_tpm fun(): boolean Check TPM presence
---@field tpm_version fun(): string|nil Get TPM version
---@field firewall_active fun(): boolean Check if firewall is active
---@field firewall_type fun(): string Get firewall type
---@field has_luks fun(): boolean Check for LUKS encryption
---@field kernel_lockdown fun(): string Get kernel lockdown mode
dcli.security = {}

---@class dcli.desktop
---@field environment fun(): string Get desktop environment
---@field display_server fun(): string Get display server type
---@field is_wayland fun(): boolean Check if running Wayland
---@field is_x11 fun(): boolean Check if running X11
---@field window_manager fun(): string Get window manager
---@field session_type fun(): string Get session type
---@field has_display fun(): boolean Check if display is available
---@field compositor fun(): string|nil Get compositor name
---@field theme fun(): string|nil Get desktop theme
---@field icon_theme fun(): string|nil Get icon theme
---@field screen_resolution fun(): string|nil Get screen resolution
dcli.desktop = {}

---@class dcli.boot
---@field bootloader fun(): string Get bootloader name
---@field is_uefi fun(): boolean Check if UEFI boot
---@field is_bios fun(): boolean Check if BIOS boot
---@field init_system fun(): string Get init system
---@field kernel_params fun(): string[] Get kernel parameters
---@field has_kernel_param fun(param: string): boolean Check kernel parameter
---@field efi_vars_supported fun(): boolean Check EFI variable support
---@field boot_id fun(): string Get boot session ID
dcli.boot = {}

---@class dcli.network
---@field has_wifi fun(): boolean Check WiFi hardware
---@field has_ethernet fun(): boolean Check Ethernet hardware
---@field has_bluetooth fun(): boolean Check Bluetooth hardware
---@field is_connected fun(): boolean Check network connectivity
---@field connection_type fun(): string Get connection type
---@field list_interfaces fun(): string[] Get network interfaces
dcli.network = {}

---@class dcli.audio
---@field has_pipewire fun(): boolean Check if PipeWire is running
---@field has_pulseaudio fun(): boolean Check if PulseAudio is running
---@field has_alsa fun(): boolean Check ALSA availability
---@field audio_server fun(): string Get audio server type
dcli.audio = {}

---@class dcli.storage
---@field has_ssd fun(): boolean Check for SSD
---@field has_nvme fun(): boolean Check for NVMe drive
---@field has_hdd fun(): boolean Check for HDD
---@field root_filesystem fun(): string Get root filesystem type
---@field list_disks fun(): string[] Get disk devices
---@field disk_info fun(device: string): table|nil Get disk information
dcli.storage = {}

return dcli
