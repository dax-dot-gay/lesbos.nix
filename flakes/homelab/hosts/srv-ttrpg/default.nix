{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ./foundry.nix ];
    lesbos = {
        info = {
            canonicalName = "srv-ttrpg";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            storage = {
                disk_size = "64G";
                virtiofs = [
                    {
                        name = "data";
                        mount = true;
                        id = "DATA";
                        expose_acl = true;
                        expose_xattr = true;
                    }
                ];
            };
            resources = {
                cores = 4;
                memory = 8192;
            };
            start.order = 100;
            network.primary.bridge = "vmbr3";
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
        volumes.foundry = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/systems/srv-ttrpg/foundry";
                ensureSource.enable = true;
            };
            destination = "/foundryvtt";
            strategy.bindMapped = {
                enable = true;
                user = "root";
                group = "root";
                permissions = "0777";
            };
            required_by = ["foundry.service"];
        };
    };
}
