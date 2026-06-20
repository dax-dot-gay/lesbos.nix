{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ./games ];
    lesbos = {
        info = {
            canonicalName = "srv-gameservers";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
            resources = {
                cores = 4;
                memory = 24576;
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
    virtualisation.oci-containers.backend = "podman";
}
