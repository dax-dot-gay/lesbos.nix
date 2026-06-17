{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ];

    system.stateVersion = "26.05";
    networking.hostName = "infra-router";

    lesbos = {
        proxmox = {
            enable = true;
            network = {
                primary.bridge = "vmbr0";
                extra_interfaces = [
                    {
                        bridge = "vmbr3";
                    }
                ];
            };
            watchdog.enable = true;
            start = {
                on_boot = true;
                on_deploy = true;
                order = 1;
                delay_up = 10;
                delay_down = 10;
            };
            resources.cores = 4;
            resources.memory = 4096;
            storage.disk_size = 65536; # 64 GiB
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "";
                };
            };
            users = { };
        };
    };
}
