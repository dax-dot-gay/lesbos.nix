{{a_hostname}} = {
    id = {{a_vmid}};
    path = ./hosts/{{a_hostname}};
    hostConfig = {
        thisflake = "{{a_flake}}";
        hostname = "{{a_hostname}}";
        enable_root = {{a_enable_root}};
        root_passhash = "{{root_passhash}}:l
        enable_user = {{a_enable_user}};
        enable_user_wheel = {{a_user_wheel}};
        username = "{{a_user_name}}";
        user_passhash = "{{user_passhash}};
        stateVersion = "{{a_state_version}}";
    };
    name = "{{a_hostname}}";
    tags = [
        # Add tags here
    ];
    modules = [
        # Add extra modules here
    ];
    extraSpecialArgs = {
        # Add extra specialArgs here
    };
};
# @add:host:proxmox