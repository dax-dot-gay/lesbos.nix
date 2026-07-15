{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ];
    lesbos = {
        info = {
            canonicalName = "srv-misc";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$OIbJRqvUhuL8yPxtVwmCq/$O4ipPUvl3wrLIRDKk9cshGHOAN1t0EaD7p9v1WP/eqD";
                };
            };
            users = { };
        };
    };
}
