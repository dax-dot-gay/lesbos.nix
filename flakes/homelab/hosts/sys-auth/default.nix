{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [
        ./provision-secrets.nix
        ./authentik.nix
    ];
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
                    path = "/systems/sys-auth/authentik";
                    ensureSource.enable = true;
                    subdirectories = [
                        "certs"
                        "templates"
                        "data"
                    ];
                };
                destination = "/authentik/authentik";
                strategy.bindMapped = {
                    enable = true;
                    user = "authentik";
                    group = "authentik";
                    permissions = "0777";
                };
                required_by = [
                    "podman-network-authentik_default.service"
                    "podman-authentik-worker.service"
                    "podman-authentik-server.service"
                    "podman-authentik-postgresql.service"
                ];
            };
            authentik-db = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/sys-auth/database";
                    ensureSource.enable = true;
                };
                destination = "/authentik/database";
                strategy.bindMapped = {
                    enable = true;
                    user = "postgres";
                    group = "postgres";
                    permissions = "0750";
                };
                required_by = [
                    "podman-network-authentik_default.service"
                    "podman-authentik-worker.service"
                    "podman-authentik-server.service"
                    "podman-authentik-postgresql.service"
                ];
            };
        };
        backups = {
            authentik-postgresql = {
                enable = true;
                settings = {
                    encryption.enable = true;
                    quota = "256G";
                };
                schedule = "hourly";
                sources = {
                    psql = {
                        enable = true;
                        type = "postgresql";
                        postgresql = {
                            database = "all";
                            container = "authentik-postgresql";
                            port = 5432;
                            username = "authentik";
                            passwordFile = config.sops.secrets."authentik/main/database/password".path;
                            commands = {
                                pg_dump = "pg_dump";
                                pg_restore = "pg_restore";
                                psql = "psql";
                            };
                        };
                    };
                };
                repositories = {
                    authentik-psql-backup = {
                        enable = true;
                        type = "volume";
                        volume = {
                            type = "share";
                            name = "data";
                            path = "/systems/sys-auth/psql-backups";
                        };
                    };
                };
            };
        };
    };

    systemd.tmpfiles.rules = [ "d /authentik/postgresql 1750 postgres postgres -" ];

    users = {
        users.authentik = {
            isSystemUser = true;
            group = "authentik";
        };
        groups.authentik = { };
        users.postgres = {
            isSystemUser = true;
            group = "postgres";
        };
        groups.postgres = { };
    };
}
