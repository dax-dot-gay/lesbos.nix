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
            canonicalName = "srv-books";
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
                    hash = "$y$j9T$nJTmVrLRPFhlNEVDcgQjm.$p.KJFdx9QRhRRkMnTZEPYC9ZRRep2nM7qeDj6Z3E199";
                };
            };
            users = { };
        };
    };
}
