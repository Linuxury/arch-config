local packages = {
    "helix",   -- preferred text editor
    "zed",     -- alternative editor
    "python",
    "python-pip",
}

-- Rust via rustup
table.insert(packages, "rustup")
table.insert(packages, "cargo")

-- CLI dev tools
table.insert(packages, "git")
table.insert(packages, "htop")
table.insert(packages, "fd")
table.insert(packages, "ripgrep")
table.insert(packages, "fzf")
table.insert(packages, "tmux")

return {
    description = "Development environment (Python, Rust, Helix, Zed, CLI tools)",
    packages = packages,
}
