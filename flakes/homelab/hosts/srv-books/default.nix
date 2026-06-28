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

    # Runtime
    virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerCompat = true;
    };

    # Enable container name DNS for all Podman networks.
    networking.firewall.interfaces =
        let
            matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
        in
        {
            "${matchAll}".allowedUDPPorts = [ 53 ];
        };

    virtualisation.oci-containers.backend = "podman";

    # Containers
    virtualisation.oci-containers.containers."grimmory" = {
        image = "grimmory/grimmory:latest";
        environmentFiles = [config.sops.templates."grimmory.env".path];
        environment = {
            "BOOKLORE_PORT" = "6060";
            "DATABASE_URL" = "jdbc:mariadb://mariadb:3306/grimmory";
            "DATABASE_USERNAME" = "grimmory";
            "GROUP_ID" = "1000";
            "TZ" = "America/New_York";
            "USER_ID" = "1000";
        };
        volumes = [
            "/grimmory/data/bookdrop:/bookdrop:rw"
            "/grimmory/library:/books:rw"
            "/grimmory/data/app:/app/data:rw"
        ];
        ports = [
            "6060:6060/tcp"
        ];
        dependsOn = [
            "grimmory-mariadb"
        ];
        log-driver = "journald";
        extraOptions = [
            "--network-alias=grimmory"
            "--network=grimmory_default"
        ];
    };
    systemd.services."podman-grimmory" = {
        serviceConfig = {
            Restart = lib.mkOverride 90 "always";
        };
        after = [
            "podman-network-grimmory_default.service"
        ];
        requires = [
            "podman-network-grimmory_default.service"
        ];
        partOf = [
            "podman-compose-grimmory-root.target"
        ];
        wantedBy = [
            "podman-compose-grimmory-root.target"
        ];
    };
    virtualisation.oci-containers.containers."grimmory-mariadb" = {
        image = "lscr.io/linuxserver/mariadb:11.4.5";
        environmentFiles = [config.sops.templates."mariadb.env".path];
        environment = {
            "MYSQL_DATABASE" = "grimmory";
            "MYSQL_USER" = "grimmory";
            "PGID" = "1000";
            "PUID" = "1000";
            "TZ" = "America/New_York";
        };
        volumes = [
            "/grimmory/mariadb:/config:rw"
        ];
        log-driver = "journald";
        extraOptions = [
            "--health-cmd=[\"mariadb-admin\", \"ping\", \"-h\", \"localhost\"]"
            "--health-interval=5s"
            "--health-retries=10"
            "--health-timeout=5s"
            "--network-alias=mariadb"
            "--network=grimmory_default"
        ];
    };
    systemd.services."podman-grimmory-mariadb" = {
        serviceConfig = {
            Restart = lib.mkOverride 90 "always";
        };
        after = [
            "podman-network-grimmory_default.service"
        ];
        requires = [
            "podman-network-grimmory_default.service"
        ];
        partOf = [
            "podman-compose-grimmory-root.target"
        ];
        wantedBy = [
            "podman-compose-grimmory-root.target"
        ];
    };

    # Networks
    systemd.services."podman-network-grimmory_default" = {
        path = [ pkgs.podman ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "podman network rm -f grimmory_default";
        };
        script = ''
            podman network inspect grimmory_default || podman network create grimmory_default
        '';
        partOf = [ "podman-compose-grimmory-root.target" ];
        wantedBy = [ "podman-compose-grimmory-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-grimmory-root" = {
        unitConfig = {
            Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
    };

    networking.firewall.allowedTCPPorts = [ 6060 ];
}
