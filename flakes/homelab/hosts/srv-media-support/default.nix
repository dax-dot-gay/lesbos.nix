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
            canonicalName = "srv-media-support";
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
                    hash = "$y$j9T$PzX4FuuAnML7rQw3yvC3/.$I4uFhMWOOWIS244UjKIjHBVKnaMo3L0BwB4/MzXL6p4";
                };
            };
            users = { };
        };
    };
}
