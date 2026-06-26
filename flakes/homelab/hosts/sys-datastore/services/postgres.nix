{
    config,
    lib,
    pkgs,
    ...
}:
with lib;
let
    users = config.datastore.postgres.users;
    setupScript = pkgs.writers.writeBash "ds-postgres-setup" ''
        #bash
               echo "No borg repository in $VOL_SOURCE, creating one..."
               borg init -e none $VOL_SOURCE
    '';
in
{
    lesbos.secrets.system = {
        "credentials/pgadmin/password" = {
            mode = "0400";
            owner = "pgadmin";
            group = "pgadmin";
        };
    };
    lesbos.volumes.postgres = {
        enable = true;
        source = {
            type = "share";
            name = "data";
            path = "/systems/sys-datastore/postgres";
            ensureSource = {
                enable = true;
            };
        };
        destination = "/datastore/postgres";
        strategy.custom = {
            enable = true;
            timerConfig = {
                OnActiveSec = "8h";
            };
            setupScript = setupScript;
            backupScript = pkgs.writers.writeBash "ds-postgres-backup" ''
                # bash
                mkdir -p "$VOL_DEST/dump-target"
                pg_dumpall > "$VOL_DEST/dump-target/dump.sql"
                borg create "$VOL_SOURCE::$(date -Iminutes)" "$VOL_DEST/dump-target"
            '';
            user = "postgres";
            group = "postgres";
            mode = "0700";
            packages = with pkgs; [
                coreutils
                postgresql
                borgbackup
            ];
        };
        required_by = [
            "postgresql.service"
            "pgadmin.service"
        ];
    };
    lesbos.volumes.pgadmin = {
        enable = true;
        source = {
            type = "share";
            name = "data";
            path = "/systems/sys-datastore/pgadmin";
            ensureSource = {
                enable = true;
            };
        };
        destination = "/datastore/pgadmin";
        strategy.sync = {
            enable = true;
            user = "pgadmin";
            group = "pgadmin";
            mode = "0770";
            timerConfig = {
                OnActiveSec = "1h";
            };
            restoration = true;
        };
        required_by = [
            "postgresql.service"
            "pgadmin.service"
        ];
    };
    networking.firewall.allowedTCPPorts = [ 5432 ];
    networking.firewall.allowedUDPPorts = [ 5432 ];
    services.postgresql = {
        enable = true;
        enableTCPIP = true;
        settings = {
            port = 5432;
        };
        ensureDatabases = mapAttrsToList (_: u: u.username) (filterAttrs (_: u: u.ensureDatabase) users);
        ensureUsers = mapAttrsToList (_: user: {
            name = user.username;
            ensureDBOwnership = user.ensureDatabase;
            ensureClauses =
                (with user.clauses; {
                    inherit
                        superuser
                        createdb
                        createrole
                        login
                        replication
                        bypassrls
                        ;
                })
                // (optionalAttrs (user.authentication.auth_method == "password") {
                    password = user.authentication.password;
                })
                // (optionalAttrs (!(isNull user.clauses.connection_limit)) {
                    connection_limit = user.clauses.connection_limit;
                });
        }) users;
        authentication = mkOverride 10 ''
            local       all     postgres    trust
            ${concatStringsSep "\n" (
                mapAttrsToList (
                    name:
                    { authentication, ... }:
                    (
                        if authentication.source_type == "local" then
                            ''
                                local ${authentication.database_access} ${name} ${
                                    if authentication.auth_method == "trust" then "trust" else "scram-sha-256"
                                }
                            ''
                        else
                            ''
                                host ${authentication.database_access} ${name} ${authentication.source_address}/24 ${
                                    if authentication.auth_method == "trust" then "trust" else "scram-sha-256"
                                }
                            ''
                    )
                ) users
            )}
        '';
    };
    services.pgadmin = {
        enable = true;
        initialEmail = "me@dax.gay";
        initialPasswordFile = config.sops.secrets."credentials/pgadmin/password".path;
        port = 5050;
        openFirewall = true;
        settings = {
            SQLITE_PATH = "/datastore/pgadmin/pgadmin.db";
            LLM_ENABLED = false;
            MFA_ENABLED = false;
        };
    };
    systemd.services.pgadmin.serviceConfig.ReadWritePaths = ["/datastore/pgadmin"];
}
