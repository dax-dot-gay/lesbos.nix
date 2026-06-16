{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [
        ./autoprovision-secrets.nix
    ];
}
