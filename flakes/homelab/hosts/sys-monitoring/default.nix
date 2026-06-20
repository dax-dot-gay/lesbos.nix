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
            canonicalName = "sys-monitoring";
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
                    hash = "$y$j9T$v0IjvsuilfsQxOXpBaunL.$/hySrns/cwbMJINS5nZ46qeiDyfJE0Q8Kxye7stAH16";
                };
            };
            users = { };
        };
    };
}
