{{a_hostname}} = {
    id = {{a_vmid}};
    path = ./hosts/{{a_hostname}};
    flake = "{{a_flake}}";
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