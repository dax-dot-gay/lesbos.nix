{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ];
    lesbos = {
        info = {
            canonicalName = "sys-cicd";
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
                    hash = "$y$j9T$l.NIDr6s3w8RaF4UPcErj.$TvBvtI8315YlWCYTzlJpo.O7MOTbEZGybJZZFMMBTd2";
                };
            };
            users = { };
        };
    };
}
