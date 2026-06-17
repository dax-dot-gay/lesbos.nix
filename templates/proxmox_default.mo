{
    config,
    lib,
    pkgs,
    inputs,
    ...
}:
{
    imports = [
        ./provision-secrets.nix
    ];

    lesbos = {
        proxmox = {
            enable = true;
        };
        base.users = {
            @root<
            root = {
                enable = {{a_enable_root}};
                ssh.enable = true;
                password = {
                    enable = true;
                    hash = "{{a_root_passhash}}";
                };
            };
            >root
            
            @users<
            users = {
                "{{a_user_name}}" = {
                    enable = true;
                    ssh.enable = true;
                    password = {
                        enable = true;
                        hash = "{{a_user_password}}";
                    };
                    sudo = {{a_user_wheel}};
                };
            };
            >users
        };
    };
}
