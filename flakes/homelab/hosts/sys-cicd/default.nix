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
        ./woodpecker.nix
    ];
    lesbos = {
        info = {
            canonicalName = "sys-cicd";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
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
            resources = {
                cores = 6;
                memory = 16384;
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
                    hash = "$y$j9T$l.NIDr6s3w8RaF4UPcErj.$TvBvtI8315YlWCYTzlJpo.O7MOTbEZGybJZZFMMBTd2";
                };
            };
            users = { };
        };
        volumes = {
            woodpecker = {
                enable = true;
                source = {
                    type = "share";
                    name = "data";
                    path = "/systems/sys-cicd/woodpecker";
                    ensureSource.enable = true;
                };
                destination = "/var/lib/woodpecker";
                strategy.bindMapped = {
                    enable = true;
                    permissions = "0700";
                    user = "woodpecker";
                    group = "woodpecker";
                };
                required_by = ["woodpecker-server.service" "woodpecker-agent-docker.service"];
            };
        };
    };

    users = {
        users.woodpecker = {
            isSystemUser = true;
            group = "woodpecker";
        };
        groups.woodpecker = {};
    };
}
