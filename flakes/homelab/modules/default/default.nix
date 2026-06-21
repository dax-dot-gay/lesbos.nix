{ ... }:
{
    imports = [
        ./connections.nix
        ./shell.nix
        ./upgrade.nix
        ./networking
        ./proxmox.nix
        ./monitoring
        ./secrets.nix
    ];
}
