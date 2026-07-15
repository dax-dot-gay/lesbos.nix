{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ./services ];
    lesbos = {
        info = {
            canonicalName = "srv-misc";
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
                    hash = "$y$j9T$OIbJRqvUhuL8yPxtVwmCq/$O4ipPUvl3wrLIRDKk9cshGHOAN1t0EaD7p9v1WP/eqD";
                };
            };
            users = { };
        };
        volumes = {
            resume-data = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-misc/resume/app-data";
                    ensureSource.enable = true;
                };
                destination = "/services/resume/app";
                strategy.bindMapped = {
                    enable = true;
                    user = "node";
                    group = "node";
                    permissions = "0750";
                };
                required_by = ["resume-app.service" "resume-postgres.service"];
            };
            resume-postgres = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-misc/resume/postgres";
                    ensureSource.enable = true;
                };
                destination = "/services/resume/postgres";
                strategy.bindMapped = {
                    enable = true;
                    user = "postgres";
                    group = "postgres";
                    permissions = "0750";
                };
                required_by = ["resume-app.service" "resume-postgres.service"];
            };
        };
    };

    users = {
        users.postgres = {
            isSystemUser = true;
            group = "postgres";
        };
        groups.postgres = {};
        users.node = {
            isSystemUser = true;
            group = "node";
        };
        groups.node = {};
    };
}
