{ config, lib, ... }:
with lib;
let
    cfg = config.datastore;
    pguser = types.submodule (
        { config, ... }:
        {
            options = {
                username = mkOption {
                    description = "Username";
                    type = types.str;
                    default = config._module.args.name;
                };
                ensureDatabase = mkOption {
                    description = "Whether to create a database owned by and named after this user";
                    type = types.bool;
                    default = true;
                };
                clauses = {
                    superuser = mkEnableOption "Enable SUPERUSER";
                    createdb = mkEnableOption "Enable CREATEDB";
                    createrole = mkEnableOption "Enable CREATEROLE";
                    login = mkEnableOption "Enable LOGIN";
                    replication = mkEnableOption "Enable REPLICATION";
                    bypassrls = mkEnableOption "Enable BYPASSRLS";
                    connection_limit = mkOption {
                        description = "If set, enables a connection limit for this user";
                        type = types.nullOr types.ints.positive;
                        default = null;
                    };
                };
                authentication = {
                    source_type = mkOption {
                        description = "Whether this user is local or remote";
                        type = types.enum [
                            "local"
                            "remote"
                        ];
                        default = "remote";
                    };
                    source_address = mkOption {
                        description = "User remote address/IP range";
                        type = types.nullOr types.str;
                        default = null;
                    };
                    database_access = mkOption {
                        description = "Database to allow access to";
                        type = types.str;
                        default = "sameuser";
                    };
                    auth_method = mkOption {
                        description = "Which auth method to use";
                        type = types.enum [
                            "password"
                            "trust"
                        ];
                        default = "password";
                    };
                    password = mkOption {
                        description = "Hashed password";
                        type = types.nullOr types.str;
                        default = null;
                    };
                };
            };
        }
    );
in
{
    options.datastore = {
        postgres = mkOption {
            description = "Postgres users & databases";
            type = types.submodule {
                options = {
                    users = mkOption {
                        description = "Attribute set of users to add";
                        type = types.attrsOf pguser;
                        default = { };
                    };
                };
            };
            default = {
                users = { };
            };
        };
    };
}
