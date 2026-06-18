{ ... }:
{
    imports = [
        ./users.nix
        ./ssh.nix
        ./shell.nix
        ./info.nix
    ];
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = ["nix-command" "flakes"];
}
