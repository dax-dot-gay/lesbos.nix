{ config, pkgs, lib, ... }:
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
    networking.firewall.allowedTCPPorts = [ 5984 ];
    pkgs = [
        pkgs.deno
        pkgs.curl
        (pkgs.writeShellScriptBin "provision-livesync" ''
            DBNAME=$1
            export hostname=https://obsidian-livesync.dax.gay
            export database=$DBNAME
            export username="$(cat ${config.sops.secrets."obsidian-livesync/username".path})"
            export password="$(cat ${config.sops.secrets."obsidian-livesync/password".path})"
            curl -s https://raw.githubusercontent.com/vrtmrz/obsidian-livesync/main/utils/couchdb/couchdb-init.sh | bash
        '')
    ];
}
