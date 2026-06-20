{ ... }:
{
    imports = [
        ./postgres.nix
    ];
    users.users = {
        matrix-synapse = {
            isSystemUser = true;
            group = "matrix-synapse";
            extraGroups = [ "matrix-services" ];
        };
        matrix-authentication-service = {
            isSystemUser = true;
            group = "matrix-authentication-service";
            extraGroups = [ "matrix-services" ];
        };
    };
    users.groups.matrix-services = { };
    users.groups.matrix-authentication-service = {};
    users.groups.matrix-synapse = {};
    lesbos.secrets.system = {
        "matrix/synapse.yaml" = {
            owner = "matrix-synapse";
            group = "matrix-synapse";
            mode = "0400";
        };
        "matrix/matrix-authentication/config.yaml" = {
            owner = "matrix-authentication-service";
            group = "matrix-authentication-service";
            mode = "0400";
        };
        "matrix/backup_encryption" = {
            owner = "root";
            group = "root";
            mode = "0400";
        };
    };
}
