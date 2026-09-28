{ ... }:
{
    imports = [
        ./resume.nix
        ./homarr.nix
        ./osync
    ];

    systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];
}
