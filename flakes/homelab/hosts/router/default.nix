{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    lesbos.proxmox = {
        enable = true;
        network = {
            primary = {
                bridge = "vmbr0";
            };
            extra_interfaces = [
                {
                    bridge = "vmbr1";
                }
            ];
        };
    };
}
