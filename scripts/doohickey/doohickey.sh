#! /usr/bin/env bash

# @describe lesbos.nix build/deploy script

# @cmd                                      Proxmox-related commands
# @meta     inherit-flag-options
# @option   -f  --flake=homelab             Select flake
proxmox() { :; }

# @cmd                                      Deploy a selected nixosConfiguration to Proxmox
# @arg      config!                         nixosConfigurations key to deploy
proxmox::deploy() {
    cd "$(git rev-parse --show-toplevel)/flakes/$argc_flake"
    rm -rf ./result
    mkdir result

    nix build ".#host-${argc_config}" -o result/vm
    nix build ".#host-${argc_config}-deploy" -o result/deploy-vm.sh
    nix build ".#host-${argc_config}-setup" -o result/setup-vm.sh

    ./result/deploy-vm.sh

    echo "Deployed $argc_flake.$argc_config to $PROXMOX_ADDR"
    rm -rf result
}

# @cmd                                      Build a selected nixosConfiguration for deployment to Proxmox
# @arg      config!                         nixosConfigurations key to build
proxmox::build() {
    cd "$(git rev-parse --show-toplevel)/flakes/$argc_flake"
    rm -rf ./result
    mkdir result

    nix build ".#host-${argc_config}" -o result/vm
    nix build ".#host-${argc_config}-deploy" -o result/deploy-vm.sh
    nix build ".#host-${argc_config}-setup" -o result/setup-vm.sh

    echo "Build artifacts in: $(git rev-parse --show-toplevel)/flakes/$argc_flake"
}

eval "$(argc --argc-eval "$0" "$@")"

