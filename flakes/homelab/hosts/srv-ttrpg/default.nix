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
            canonicalName = "srv-ttrpg";
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
                    hash = "$y$j9T$Lh7ynohoSu.t9URQiYSp70$uCDSzuf.vHRdOaq7KMGgEQ7pOIac/khYBv5IiJiaIc8";
                };
            };
            users = { };
        };
    };
}
