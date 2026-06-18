{{a_hostname}} = {
    inherit self;
    id = {{a_vmid}};
    path = ./hosts/{{a_hostname}};
    name = "{{a_hostname}}";
    tags = [
        # Add tags here
    ];
    modules = [
        ./modules
        # Add extra modules here
    ];
    extraSpecialArgs = {
        # Add extra specialArgs here
    };
};
# @add:host:proxmox