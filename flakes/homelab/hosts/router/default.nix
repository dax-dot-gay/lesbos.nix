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
    ];

    lesbos.proxmox = {
        enable = true;
        network = {
            primary.bridge = "vmbr0";
            extra_interfaces = [
                {
                    bridge = "vmbr3";
                }
            ];
        };
    };
}
