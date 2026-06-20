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
        ./tailscale.nix
        ./nginx
    ];
    lesbos = {
        info = {
            canonicalName = "sys-ingress";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$64t1uSMse2uDDReLmyMp61$/H4EDkBazG9A0W730.6r/keA8Q2eeFVvm6KLDqZnkt0";
                };
            };
            users = { };
        };
    };
}
