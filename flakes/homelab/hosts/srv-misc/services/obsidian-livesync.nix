{ config, ... }:
let
    pl = config.sops.placeholder;
in
{
    lesbos.secrets.system = {
        "obsidian-livesync/username" = { };
        "obsidian-livesync/password" = { };
    };
    sops.templates."obsidian-livesync.env" = {
        owner = "root";
        group = "root";
        mode = "0444";
        content = ''
            COUCHDB_USER=${pl."obsidian-livesync/username"}
            COUCHDB_PASSWORD=${pl."obsidian-livesync/password"}
        '';
    };
    virtualisation.oci-containers.containers.obsidian-livesync = {
        serviceName = "obsidian-livesync";
        image = "docker.io/couchdb:latest";
        environmentFiles = [
            config.sops.templates."obsidian-livesync.env".path
        ];
        volumes = [
            "/services/obsidian-livesync/data:/opt/couchdb/data"
            "/services/obsidian-livesync/etc:/opt/couchdb/etc/local.d"
        ];
        ports = [ "0.0.0.0:5984:5984" ];
    };
}
