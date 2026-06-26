#! /usr/bin/env bash

# @describe lesbos.nix build/deploy script

# Setup lobash
set -o errexit -o nounset -o pipefail -o errtrace
(shopt -p inherit_errexit &>/dev/null) && shopt -s inherit_errexit
source "$(git rev-parse --show-toplevel)/scripts/lobash.bash"

inquire_arg() {
    a_value=$1
    a_prompt=$2

    if [ "$(l.str_len "$a_value")" = "0" ]; then
        echo "$(l.ask_input "$a_prompt:")"
    else
        echo "$a_value"
    fi
}

inquire_pass() {
    a_value=$1
    a_prompt=$2

    if [ "$(l.str_len "$a_value")" = "0" ]; then
        read -s -p "$a_prompt: " result
        echo "" >&2
        if [ "$(l.str_len "$result")" = "0" ]; then
            echo $(pwgen -s -c 64 1)
        else
            echo $result
        fi
    else
        echo "$a_value"
    fi
}

replace() {
    lhs="$1"
    rhs="$2"
    output="$3"

    escaped_lhs=$(printf '%s\n' "$lhs" | sed 's:[][\\/.^$*]:\\&:g')
    escaped_rhs=$(printf '%s\n' "$rhs" | sed 's:[\\/&]:\\&:g; $!s/$/\\/')

    sed -i "s/$escaped_lhs/$escaped_rhs/g" "$output"
}

_default_flake() {
    flake=$(printf '%q\n' "${CALLPWD##*/}")
    if [ "$flake" = "common" ]; then
        echo "common"
    elif [ "$flake" = "homelab" ]; then
        echo "homelab"
    elif [ "$flake" = "personal" ]; then
        echo "personal"
    else
        echo "ERROR: Not in a flake directory!!!" >&2
        kill -SIGPIPE "$$"
    fi
}

# @cmd                                      Build nixosConfigurations
# @meta     inherit-flag-options
# @option   -f  --flake=`_default_flake`    Select a flake
# @option   -c  --config!                   Configuration key to build
build() { :; }

# @cmd                                      Build this as a proxmoxConfiguration
build::proxmox() {
    ORIGINAL_PWD=$(git rev-parse --show-toplevel)
    mkdir -p ~/.cache/doohickey
    cp -R ./** ~/.cache/doohickey
    cd ~/.cache/doohickey
    rm -rf .git
    git init -b main .

    git add -A
    git commit -m "nul"

    cd "flakes/$argc_flake"
    rm -rf ./result
    mkdir result

    cp ../../templates/provision-secrets-filled.nix ./hosts/$argc_config/provision-secrets.nix

    nix build ".#host-${argc_config}" -o result/vm
    nix build ".#host-${argc_config}-deploy" -o result/deploy-vm.sh
    nix build ".#host-${argc_config}-setup" -o result/setup-vm.sh

    echo "Build artifacts in: $(git rev-parse --show-toplevel)/flakes/$argc_flake"
    rm -rf "$ORIGINAL_PWD/flakes/$argc_flake/result"
    mkdir -p "$ORIGINAL_PWD/flakes/$argc_flake/result"
    cp -R result/** "$ORIGINAL_PWD/flakes/$argc_flake/result/"
    cd $ORIGINAL_PWD
    rm -rf ~/.cache/doohickey
}

# @cmd                                      Deploy nixosConfigurations
# @meta     inherit-flag-options
# @option   -f  --flake=`_default_flake`    Select a flake
# @option   -c  --config!                   Configuration key to deploy
deploy() { :; }

# @cmd                                      Deploy this configuration to Proxmox
deploy::proxmox() {
    ORIGINAL_PWD=$(git rev-parse --show-toplevel)
    mkdir -p ~/.cache/doohickey
    cp -R ./** ~/.cache/doohickey
    cd ~/.cache/doohickey
    rm -rf .git
    git init -b main .

    git add -A
    git commit -m "nul"

    cd "flakes/$argc_flake"
    rm -rf ./result
    mkdir result

    cp ../../templates/provision-secrets-filled.nix ./hosts/$argc_config/provision-secrets.nix

    nix build ".#host-${argc_config}" -o result/vm
    nix build ".#host-${argc_config}-deploy" -o result/deploy-vm.sh
    nix build ".#host-${argc_config}-setup" -o result/setup-vm.sh

    ./result/deploy-vm.sh

    echo "Deployed $argc_flake.$argc_config to $PROXMOX_ADDR"
    rm -rf "$ORIGINAL_PWD/flakes/$argc_flake/result"
    mkdir -p "$ORIGINAL_PWD/flakes/$argc_flake/result"
    cp -R result/** "$ORIGINAL_PWD/flakes/$argc_flake/result/"

    cd $ORIGINAL_PWD
    rm -rf ~/.cache/doohickey
}

# @cmd                                      Create new resource
# @meta     inherit-flag-options
# @option   -f  --flake=`_default_flake`    Select a flake
add() { :; }

# @cmd                                      Create a new host (nixosConfiguration) in the target flake (options not specified will be asked for interactively)
# @meta     inherit-flag-options
# @option       --state-version=26.05       Set the stateVersion
# @option       --hostname=                 Set the hostname
# @flag         --enable-root               Enable the root account
# @option       --root-password=            Set the root password
# @flag         --enable-user               Enable the user account
# @flag         --enable-user-wheel         Allow the created user to run sudo
# @option       --user-name=                Set username
# @option       --user-password=            Set user password
add::host() { :; }

# @cmd                                      Create a proxmox host
# @option       --vmid=                     VM ID
add::host::proxmox() {
    cd "$(git rev-parse --show-toplevel)/flakes/$argc_flake"
    export a_flake="$argc_flake"
    export a_vmid="$(inquire_arg "$argc_vmid" "Enter VM ID")"
    export a_hostname="$(inquire_arg "$argc_hostname" "Enter hostname (also VM name)")"
    export a_state_version="$argc_state_version"
    if [ "${argc_enable_root:-"0"}" = "1" ] || [ "$(l.ask "Enable root account?" "N" )" = "YES" ]; then
        export a_enable_root="true"
        export a_root_password="$(inquire_pass "$argc_root_password" "Enter password for root account")"
        export root_passhash="$(mkpasswd $a_root_password)"
    else
        export a_enable_root="false"
        export a_root_password=""
        export root_passhash=""
    fi

    if [ "${argc_enable_user:-"0"}" = "1" ] || [ "$(l.ask "Enable primary user account?" "N" )" = "YES" ]; then
        export a_enable_user="true"
        export a_user_name="$(inquire_arg "$argc_user_name" "Enter username for primary user")"
        export a_user_password="$(inquire_pass "$argc_user_password" "Enter password for primary user")"
        export user_passhash="$(mkpasswd $a_user_password)"

        if [ "${argc_enable_user_wheel:-"0"}" = "1" ] || [ "$(l.ask "Allow primary user account to sudo?" "N" )" = "YES" ]; then
            export a_user_wheel="true"
        else
            export a_user_wheel="false"
        fi
    else
        export a_enable_user="false"
        export a_user_name=""
        export a_user_password=""
        export a_user_wheel="false"
        export user_passhash=""
    fi

    mkdir -p "hosts/$a_hostname"
    cp ../../templates/proxmox_default.mo "hosts/$a_hostname/default.nix"

    if [ "$a_enable_root" = "false" ]; then
        sed -i 's/@root.*$//g' "hosts/$a_hostname/default.nix"
    else
        sed -i 's/@root//g' "hosts/$a_hostname/default.nix"
    fi

    if [ "$a_enable_user" = "false" ]; then
        sed -i 's/@user.*$//g' "hosts/$a_hostname/default.nix"
    else 
        sed -i 's/@user//g' "hosts/$a_hostname/default.nix"
    fi

    templated_config="$(cat "hosts/$a_hostname/default.nix" | mo)"
    echo $templated_config > "hosts/$a_hostname/default.nix"

    nixfmt --width=100 --indent=4 "hosts/$a_hostname/default.nix"

    cp ../../templates/provision-secrets-empty.nix "hosts/$a_hostname/provision-secrets.nix"
    generated="$(cat ../../templates/proxmox_host.mo | mo)"

    escaped_rhs=$(printf '%s\n' "$generated" | sed 's:[\\/&]:\\&:g; $!s/$/\\/')
    sed -i "s/# @add:host:proxmox/$escaped_rhs/g" ./flake.nix
    nixfmt --width=100 --indent=4 ./flake.nix

    mkdir -p "hosts/$a_hostname/.host-secrets"
    install -d "hosts/$a_hostname/.host-secrets/etc/ssh"
    ssh-keygen -A -f "hosts/$a_hostname/.host-secrets"
    sed -i -e "s/$(id -un)@$(hostname)/root@$a_hostname/g" hosts/$a_hostname/.host-secrets/etc/ssh/*.pub
    chmod 600 hosts/$a_hostname/.host-secrets/etc/ssh/*

    mkdir -p "../../secrets/$a_flake/per-system/$a_hostname"
    age_key=$(ssh-to-age -i "hosts/$a_hostname/.host-secrets/etc/ssh/ssh_host_ed25519_key.pub")

    replace "# @add:key-def" "- &$a_flake-host-$a_hostname $age_key\n    # @add:key-def" ../../.sops.yaml
    replace "# @add:key-ref" "- *$a_flake-host-$a_hostname\n          # @add:key-ref" ../../.sops.yaml

    if [ "$a_flake" = "homelab" ]; then
        replace "# @add:homelab:key-ref" "- *$a_flake-host-$a_hostname\n          # @add:homelab:key-ref" ../../.sops.yaml
    else
        replace "# @add:personal:key-ref" "- *$a_flake-host-$a_hostname\n          # @add:personal:key-ref" ../../.sops.yaml
    fi

    sed -i 's/\\n/\n/g' ../../.sops.yaml

    new_entry=$(cat << EOF
- path_regex: secrets/$a_flake/per-system/$a_hostname/system.yaml$
    key_groups:
      - age:
          - *root
          - *$a_flake-host-$a_hostname
  # @add:new-path
EOF
)

    replace "# @add:new-path" "$new_entry" ../../.sops.yaml
    echo "---" > "../../secrets/$a_flake/per-system/$a_hostname/system.yaml"
    sops encrypt -i "../../secrets/$a_flake/per-system/$a_hostname/system.yaml"
    sops updatekeys -y ../../secrets/global.yaml
    sops updatekeys -y ../../secrets/$a_flake/global.yaml

    if [ "$a_enable_root" = "true" ]; then
        sops set "../../secrets/$a_flake/per-system/$a_hostname/system.yaml" "[\"users\"][\"root\"][\"password-raw\"]" "\"$a_root_password\""
    fi

    if [ "$a_enable_user" = "true" ]; then
        sops set "../../secrets/$a_flake/per-system/$a_hostname/system.yaml" "[\"users\"][\"$a_user_name\"][\"password-raw\"]" "\"$a_user_password\""
    fi
    
}

# @cmd                                      Perform flake operations on all flakes, or a single one if specified
flakes() { :; }

# @cmd update common input for all flakes
flakes::recommon() {
    nix flake update --flake ./flakes/homelab lesbos-common
    nix flake update --flake ./flakes/personal lesbos-common
}

# @cmd                                      Update flakes
# @arg      flake=all       <FLAKE>         Flake to update
flakes::update() {
    if [ "$argc_flake" = "all" ]; then
        nix flake update --flake ./flakes/homelab
        nix flake update --flake ./flakes/personal
        nix flake update --flake ./flakes/common
    else
        nix flake update --flake "./flakes/$argc_flake"
    fi
}

# @cmd                                      Check flakes
# @arg      flake=all       <FLAKE>         Flake to check
flakes::check() {
    if [ "$argc_flake" = "all" ]; then
        echo "Checking homelab..."
        cd flakes/homelab
        nix flake check

        echo "Checking personal..."
        cd ../../flakes/personal
        nix flake check

        echo "Checking common..."
        cd ../../flakes/common
        nix flake check
    else
        cd "flakes/$argc_flake"
        nix flake check
    fi
}

# @cmd                                      Generate password hashes
password() { :; }

# @cmd                                      Generate a linux system password hash
# @option       --password=                 Supply password from the commandline
password::linux() {
    plain="$(inquire_pass "$argc_password" "Enter a password (leave empty to generate one)")"
    hashed="$(mkpasswd "$plain")"

    echo "Plain text: $plain"
    echo "Hashed    : $hashed"
}

# @cmd                                      Generate a postgresql password hash
# @option       --password=                 Supply password from the commandline
password::postgres() {
    plain="$(inquire_pass "$argc_password" "Enter a password (leave empty to generate one)")"
    hashed="$(./scripts/doohickey/pgpass.py "$plain")"

    echo "Plain text: $plain"
    echo "Hashed    : $hashed"
}



eval "$(argc --argc-eval "$0" "$@")"

