{ ... }:
{
    imports = [
        ./users.nix
        ./ssh.nix
        ./shell.nix
        ./info.nix
        ./secrets.nix
    ];
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = ["nix-command" "flakes"];
}
