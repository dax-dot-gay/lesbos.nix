{
    config,
    lib,
    pkgs,
    ...
}:
let
    setupScript = pkgs.writers.writeBash "matrix-backup-setup" ''
        #bash
               echo "No borg repository in $VOL_SOURCE, creating one..."
               export BORG_PASSCOMMAND="cat ${config.sops.secrets."matrix/backup_encryption".path}"
               borg init -e repokey $VOL_SOURCE
    '';
in
{
    lesbos.volumes.postgres = {
        enable = true;
        source = {
            type = "share";
            name = "data";
            path = "/systems/srv-matrix/postgres";
            ensureSource.enable = true;
        };
        destination = "/matrix-services/postgres";
        strategy.custom = {
            enable = true;
            timerConfig = {
                OnActiveSec = "8h";
            };
            setupScript = setupScript;
            backupScript = pkgs.writers.writeBash "matrix-backup-backup-postgres" ''
                # bash
                               export BORG_PASSCOMMAND="cat ${config.sops.secrets."matrix/backup_encryption".path}"
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
        required_by = [ "postgresql.service" ];
    };

    services.postgresql = {
        enable = true;
        authentication = ''
            #type database  DBuser  auth-method
            local all       all     trust
            local all matrix-synapse trust
            local all matrix-authentication-service trust
            local all root trust
        '';
        dataDir = "/matrix-services/postgres";
        ensureDatabases = [
            "matrix-authentication-service"
            "matrix-synapse"
        ];
        ensureUsers = [
            {
                name = "root";
                ensureClauses = {
                    login = true;
                    superuser = true;
                    createrole = true;
                    createdb = true;
                };
            }
        ];
        initialScript = pkgs.writeText "init-sql-script" ''
            alter user "matrix-authentication-service" with password 'matrix-authentication-service';
        '';
    };
}
