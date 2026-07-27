{ ... }:
{
    imports = [
        ./resume.nix
        ./homarr.nix
    ];

    systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];
}
