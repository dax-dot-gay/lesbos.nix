{ ... }:
{
    imports = [
        ./resume.nix
        ./homarr.nix
        ./obsidian-livesync.nix
    ];

    systemd.timers.podman-auto-update.wantedBy = [ "timers.target" ];
}
