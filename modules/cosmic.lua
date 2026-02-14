return {
    description = "COSMIC desktop environment (full group)",

    packages = {
        "cosmic",
    },

    services = {
        enabled = {
            "cosmic-greeter.service",
        },
        disabled = {},
    },
}
