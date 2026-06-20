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
            canonicalName = "srv-gameservers";
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
                    hash = "$y$j9T$W2qPWNbo55eB8Su29aVIK0$HzJjzyZT/.N1hFQAgprZxgrHC5s/.pANj28Q0GkNvTB";
                };
            };
            users = { };
        };
    };
}
