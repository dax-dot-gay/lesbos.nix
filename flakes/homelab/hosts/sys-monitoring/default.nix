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
        ./prometheus.nix
    ];
    lesbos = {
        info = {
            canonicalName = "sys-monitoring";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            resources.memory = 4096;
            resources.cores = 2;
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
            network.primary.bridge = "vmbr3";
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$v0IjvsuilfsQxOXpBaunL.$/hySrns/cwbMJINS5nZ46qeiDyfJE0Q8Kxye7stAH16";
                };
            };
            users = { };
        };
    };
}
