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
            canonicalName = "srv-immich";
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
                    hash = "$y$j9T$9X1KmUEcPjvdFfZL2bHTg/$N8zODhfP1dlmxrD8qIT3Q5WAeDSvwrzvavmokrEw0K.";
                };
            };
            users = { };
        };
    };
}
