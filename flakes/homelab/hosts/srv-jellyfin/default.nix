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
            canonicalName = "srv-jellyfin";
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
                    hash = "$y$j9T$nj3Padhk.uBrvUNeQr7xb/$AZe9YSYtRer6j7L3NuDm/iUtOFdUYAIqRf71/FZPCcB";
                };
            };
            users = { };
        };
    };
}
