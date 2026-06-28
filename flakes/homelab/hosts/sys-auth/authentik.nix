{
    config,
    pkgs,
    lib,
    ...
}:
{
    lesbos.secrets.system = {
        "authentik/main/secret_key" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/email_password" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/bootstrap/email" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/bootstrap/password" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/bootstrap/token" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/host" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/name" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/password" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/main/database/user" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/ldap/token" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
        "authentik/proxy/token" = {
            owner = "authentik";
            group = "authentik";
            mode = "0400";
        };
    };

    sops.templates =
        let
            pl = config.sops.placeholder;
        in
        {
            "authentik.env" = {
                owner = "authentik";
                group = "authentik";
                mode = "0777";
                content = ''
                    AUTHENTIK_SECRET_KEY=${pl."authentik/main/secret_key"}
                    AUTHENTIK_EMAIL__PASSWORD=${pl."authentik/main/email_password"}
                    AUTHENTIK_BOOTSTRAP_PASSWORD=${pl."authentik/main/bootstrap/password"}
                    AUTHENTIK_BOOTSTRAP_EMAIL=${pl."authentik/main/bootstrap/email"}
                    AUTHENTIK_BOOTSTRAP_TOKEN=${pl."authentik/main/bootstrap/token"}
                    AUTHENTIK_POSTGRESQL__HOST=${pl."authentik/main/database/host"}
                    AUTHENTIK_POSTGRESQL__NAME=${pl."authentik/main/database/name"}
                    AUTHENTIK_POSTGRESQL__PASSWORD=${pl."authentik/main/database/password"}
                    AUTHENTIK_POSTGRESQL__USER=${pl."authentik/main/database/user"}
                    AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS=192.168.64.0/24
                    AUTHENTIK_LISTEN__HTTP=0.0.0.0:9000
                    AUTHENTIK_LISTEN__METRICS=0.0.0.0:9300
                '';
            };
            "postgres.env" = {
                owner = "authentik";
                group = "authentik";
                mode = "0777";
                content = ''
                    POSTGRES_DB=${pl."authentik/main/database/name"}
                    POSTGRES_PASSWORD=${pl."authentik/main/database/password"}
                    POSTGRES_USER=${pl."authentik/main/database/user"}
                '';
            };
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
    virtualisation.oci-containers.containers."authentik-postgresql" = {
        image = "docker.io/library/postgres:16-alpine";
        environmentFiles = [ config.sops.templates."postgres.env".path ];
        volumes = [
            "/authentik/database:/var/lib/postgresql/data:rw"
        ];
        log-driver = "journald";
        extraOptions = [
            "--health-cmd=pg_isready -d authentik -U authentik"
            "--health-interval=30s"
            "--health-retries=5"
            "--health-start-period=20s"
            "--health-timeout=5s"
            "--network-alias=postgresql"
            "--network=authentik_default"
        ];
    };
    systemd.services."podman-authentik-postgresql" = {
        serviceConfig = {
            Restart = lib.mkOverride 90 "always";
        };
        after = [
            "podman-network-authentik_default.service"
        ];
        requires = [
            "podman-network-authentik_default.service"
        ];
        partOf = [
            "podman-compose-authentik-root.target"
        ];
        wantedBy = [
            "podman-compose-authentik-root.target"
        ];
    };
    virtualisation.oci-containers.containers."authentik-server" = {
        image = "ghcr.io/goauthentik/server:2026.5.3";
        environmentFiles = [ config.sops.templates."authentik.env".path ];
        volumes = [
            "/authentik/authentik/templates:/templates:rw"
            "/authentik/authentik/data:/data:rw"
        ];
        ports = [
            "9000/tcp"
            "9300/tcp"
            "9443/tcp"
        ];
        cmd = [ "server" ];
        dependsOn = [
            "authentik-postgresql"
        ];
        log-driver = "journald";
        extraOptions = [
            "--network-alias=server"
            "--network=authentik_default"
            "--shm-size=536870912"
        ];
    };
    systemd.services."podman-authentik-server" = {
        serviceConfig = {
            Restart = lib.mkOverride 90 "always";
        };
        after = [
            "podman-network-authentik_default.service"
        ];
        requires = [
            "podman-network-authentik_default.service"
        ];
        partOf = [
            "podman-compose-authentik-root.target"
        ];
        wantedBy = [
            "podman-compose-authentik-root.target"
        ];
    };
    virtualisation.oci-containers.containers."authentik-worker" = {
        image = "ghcr.io/goauthentik/server:2026.5.3";
        environmentFiles = [ config.sops.templates."authentik.env".path ];
        volumes = [
            "/authentik/authentik/certs:/certs:rw"
            "/authentik/authentik/templates:/templates:rw"
            "/authentik/authentik/data:/data:rw"
        ];
        cmd = [ "worker" ];
        dependsOn = [
            "authentik-postgresql"
        ];
        user = "root";
        log-driver = "journald";
        extraOptions = [
            "--network-alias=worker"
            "--network=authentik_default"
            "--shm-size=536870912"
        ];
    };
    systemd.services."podman-authentik-worker" = {
        serviceConfig = {
            Restart = lib.mkOverride 90 "always";
        };
        after = [
            "podman-network-authentik_default.service"
        ];
        requires = [
            "podman-network-authentik_default.service"
        ];
        partOf = [
            "podman-compose-authentik-root.target"
        ];
        wantedBy = [
            "podman-compose-authentik-root.target"
        ];
    };

    # Networks
    systemd.services."podman-network-authentik_default" = {
        path = [ pkgs.podman ];
        serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "podman network rm -f authentik_default";
        };
        script = ''
            podman network inspect authentik_default || podman network create authentik_default
        '';
        partOf = [ "podman-compose-authentik-root.target" ];
        wantedBy = [ "podman-compose-authentik-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-authentik-root" = {
        unitConfig = {
            Description = "Root target generated by compose2nix.";
        };
        wantedBy = [ "multi-user.target" ];
    };

    networking.firewall.allowedTCPPorts = [
        9000
        9443
        9300
    ];
}
