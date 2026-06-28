{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ./authentik.nix ];
    lesbos = {
        info = {
            canonicalName = "sys-auth";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            resources = {
                cores = 4;
                memory = 8192;
            };
            start.order = 4;
            network.primary.bridge = "vmbr3";
            storage = {
                disk_size = "128G";
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
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$TnULhQVGpD.m38Wc1h1dZ/$Yc/D8hhQogrwGRX2BCFCfSXfooM4cxJa//8wS1NCDAC";
                };
            };
            users = { };
        };
        volumes = {
            authentik = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/sys-auth";
                    ensureSource.enable = true;
                    subdirectories = [
                        "media"
                        "blueprints"
                        "templates"
                    ];
                };
                destination = "/authentik";
                strategy.bindMapped = {
                    enable = true;
                    user = "authentik";
                    group = "authentik";
                    permissions = "0770";
                };
                required_by = ["authentik.service" "authentik-worker.service" "authentik-migrate.service"];
            };
        };
    };

    users = {
        users.authentik = {
            isSystemUser = true;
            group = "authentik";
        };
        groups.authentik = {};
    };
}
