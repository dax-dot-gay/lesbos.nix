{
    pkgs,
    config,
    lib,
    ...
}:
{
    lesbos.volumes = {
        immich-media = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/data/media/Photos";
                ensureSource.enable = true;
            };
            destination = "/immich/media";
            strategy.bindMapped = {
                enable = true;
                permissions = "0700";
                user = "immich";
                group = "immich";
            };
        };
        immich-database = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/systems/sys-storage/immich/database";
                ensureSource.enable = true;
            };
            destination = "/immich/database";
            strategy.bindMapped = {
                enable = true;
                permissions = "0700";
                user = "immich";
                group = "immich";
            };
        };
    };

    services.immich = {
        enable = true;
        host = "0.0.0.0";
        port = 2300;
        openFirewall = true;
        redis = {
            enable = true;
        };
        database = {
            enable = true;
        };
        machine-learning.enable = false;
        mediaLocation = "/immich/media";
    };

    services.postgresql.dataDir = lib.mkForce "/immich/database";
}
