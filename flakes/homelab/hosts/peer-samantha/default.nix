{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [ ./provision-secrets.nix ];
    lesbos = {
        info = {
            canonicalName = "peer-samantha";
            flake = "homelab";
            stateVersion = "26.05";
            runningVersion = "26.05";
        };
        proxmox = {
            enable = true;
        };
        base.users = {
            root = {
                enable = true;
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "$y$j9T$dqtofzM7Pl4lzYzznBLm/.$rNvcWH.F7dqaStRwLRRrw9l32ZgC1F9k6M.t7CdxCz8";
                };
            };
            users = {
                samantha = {
                    enable = true;
                    ssh.enable = true;
                    password = {
                        enable = true;
                        hash = "$y$j9T$7IY5ppGGRfesUXTmqHsQ.1$HqBSWUc1Ykla97b7gs/BeKMXo9FRrKW2fu99r99vpa3";
                    };
                };
            };
        };
        volumes.samantha = {
            enable = true;
            source = {
                type = "share";
                name = "data";
                path = "/data/users/samantha";
                ensureSource = {
                    enable = true;
                    user = "root";
                    group = "root";
                    mode = "0770";
                };
            };
            destination = "/home/samantha/shared";
            strategy.bindMapped = {
                enable = true;
                user = "samantha";
                permissions = "0700";
            };
        };
    };
}
