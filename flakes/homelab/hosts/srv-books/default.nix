{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
with lib;
{
    imports = [ ./provision-secrets.nix ];
    lesbos = {
        info = {
            canonicalName = "srv-books";
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
            storage = {
                disk_size = "256G";
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
            network.primary.bridge = "vmbr3";
            start.order = 100;
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$nJTmVrLRPFhlNEVDcgQjm.$p.KJFdx9QRhRRkMnTZEPYC9ZRRep2nM7qeDj6Z3E199";
                };
            };
            users = { };
        };
        volumes = {
            library = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/data/media/Library";
                };
                destination = "/grimmory/library";
                strategy.bindMapped = {
                    enable = true;
                    user = "grimmory";
                    group = "grimmory";
                    permissions = "0770";
                };
                required_by = [
                    "podman-grimmory.service"
                    "podman-mariadb.service"
                ];
            };
            grimmory_data = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-books/grimmory";
                    ensureSource = {
                        enable = true;
                    };
                    subdirectories = [
                        "app"
                        "bookdrop"
                    ];
                };
                destination = "/grimmory/data";
                strategy.bindMapped = {
                    enable = true;
                    user = "grimmory";
                    group = "grimmory";
                    permissions = "0770";
                };
                required_by = [
                    "podman-grimmory.service"
                    "podman-mariadb.service"
                ];
            };
            mariadb_data = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/srv-books/mariadb";
                    ensureSource = {
                        enable = true;
                    };
                };
                destination = "/grimmory/mariadb";
                strategy.bindMapped = {
                    enable = true;
                    user = "grimmory";
                    group = "grimmory";
                    permissions = "0770";
                };
                required_by = [
                    "podman-grimmory.service"
                    "podman-mariadb.service"
                ];
            };
        };
    };

    users = {
        users.grimmory = {
            isSystemUser = true;
            group = "grimmory";
            uid = 1000;
        };
        groups.grimmory = {
            gid = 1000;
        };
    };

    lesbos.secrets.system."db_password" = {
        owner = "grimmory";
        group = "grimmory";
        mode = "0444";
    };

    sops.templates."grimmory.env" = {
        owner = "grimmory";
        group = "grimmory";
        mode = "0444";
        content = ''
            DATABASE_PASSWORD=${config.sops.placeholder."db_password"}
        '';
    };

    sops.templates."mariadb.env" = {
        owner = "grimmory";
        group = "grimmory";
        mode = "0444";
        content = ''
            MYSQL_ROOT_PASSWORD=${config.sops.placeholder."db_password"}_root
            MYSQL_PASSWORD=${config.sops.placeholder."db_password"}
        '';
    };

    virtualisation.oci-containers = {
        backend = "podman";
        containers = {
            grimmory = {
                image = "grimmory/grimmory:latest";
                dependsOn = [ "mariadb" ];
                extraOptions = [
                    "--network=host"
                ];
                volumes = [
                    "/grimmory/data/app:/app/data"
                    "/grimmory/library:/books"
                    "/grimmory/data/bookdrop"
                ];
                environment = {
                    USER_ID = "${toString config.users.users.grimmory.uid}";
                    GROUP_ID = "${toString config.users.groups.grimmory.gid}";
                    TZ = "America/New_York";
                    DATABASE_URL = "jdbc:mariadb://localhost:3306/grimmory";
                    DATABASE_USERNAME = "grimmory";
                    BOOKLORE_PORT = "6060";
                };
                environmentFiles = [ config.sops.templates."grimmory.env".path ];
            };
            mariadb = {
                image = "lscr.io/linuxserver/mariadb:11.4.5";
                extraOptions = [
                    "--network=host"
                    "--health-cmd='[\"CMD-SHELL\", \"mariadb-admin ping -h localhost\"]'"
                    "--health-interval=5s"
                    "--health-timeout=5s"
                    "--health-retries=10"
                ];
                volumes = [
                    "/grimmory/mariadb:/config"
                ];
                environment = {
                    PUID = "${toString config.users.users.grimmory.uid}";
                    PGID = "${toString config.users.groups.grimmory.gid}";
                    TZ = "America/New_York";
                    MYSQL_DATABSE = "grimmory";
                    MYSQL_USER = "grimmory";
                };
                environmentFiles = [ config.sops.templates."mariadb.env".path ];
            };
        };
    };

    networking.firewall.allowedTCPPorts = [ 6060 ];
}
