{ ... }:
{
    imports = [
        ./users.nix
        ./ssh.nix
        ./shell.nix
    ];
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = ["nix-command" "flakes"];
}
