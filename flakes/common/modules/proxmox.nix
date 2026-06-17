{
    lib,
    config,
    pkgs,
    ...
}:
with lib;
let
    cfg = config.lesbos.proxmox;
    mkSubmodule =
        description: options:
        mkOption {
            description = description;
            type = types.submodule {
                options = options;
            };
            default = { };
        };
    extraDisk = types.submodule {
        options = {
            device = mkOption {
                description = ''
                    Proxmox device name

                    Can be one of:
                     - `virtio<1-15>`, ie virtio1
                     - `scsi<0-30>`, ie scsi0
                     - `sata<0-5>`, ie sata0
                '';
                type = types.strMatching "^(virtio|sata|scsi)[0-9]{1,2}$";
                example = "virtio1";
            };
            size = mkOption {
                description = "Size of this disk in GiB";
                type = types.ints.positive;
                default = 64;
            };
            volume = mkOption {
                description = "Proxmox storage volume (if `null`, defaults to `storage.volume`)";
                type = types.nullOr types.singleLineStr;
                default = null;
            };
            cache = mkOption {
                description = "Cache mode to use";
                type = types.enum [
                    "none"
                    "directsync"
                    "unsafe"
                    "writeback"
                    "writethrough"
                ];
                default = "none";
            };
            format = mkOption {
                description = "Drive's backing file format";
                type = types.enum [
                    "raw"
                    "cloop"
                    "qcow"
                    "qcow2"
                    "qed"
                    "vmdk"
                ];
                default = "raw";
            };
            read_only = mkOption {
                description = "Whether disk is read-only";
                type = types.bool;
                default = false;
            };
        };
    };
    networkInterface = types.submodule {
        options = {
            bridge = mkOption {
                description = "Proxmox network bridge to attach to";
                type = types.strMatching "^vmbr[0-9]+$";
            };
            model = mkOption {
                description = "Device model (subset of supported)";
                type = types.enum [
                    "e1000"
                    "virtio"
                ];
                default = "virtio";
            };
        };
    };

    setupScript = if cfg.enable then  (
        pkgs.writeScript "setup-vm.sh" ''
            #! /usr/bin/env bash

            STORAGE_PATH=$(pvesh get /storage --output-format json | jq -r '.[] | select(.storage | contains("${cfg.storage.volume}")) | .path')

            qmrestore "$STORAGE_PATH/dump/vzdump-qemu-${toString cfg.metadata.id}-${cfg.metadata.name}.vma.zst" ${toString cfg.metadata.id} --unique --force
            qm set ${toString cfg.metadata.id} --efidisk0 ${cfg.storage.volume}:1,format=raw,efitype=4m,pre-enrolled-keys=0
            ${concatStringsSep "\n" (
                imap1 (index: disk: ''
                    qm set ${toString cfg.metadata.id} --${disk.device} ${
                        if (isNull disk.volume) then cfg.storage.volume else disk.volume
                    }:${toString disk.size},cache=${disk.cache},format=${disk.format}${
                        if (disk.read_only && (isNull (match "sata" disk.device))) then ",ro=1" else ""
                    }
                '') cfg.storage.extra_disks
            )}

            ${
                if cfg.start.on_deploy then ''
                    echo "Deployed! Starting..."
                    qm start ${toString cfg.metadata.id}

                    echo "Waiting to confirm status..."
                    qm status ${toString cfg.metadata.id}
                '' else ''
                    echo "Deployed but not started -- further configuration may be required"
                ''
            }
        ''
    ) else (pkgs.writeScript "deploy-vm.sh" "echo DOES NOTHING");

    deployScript = if cfg.enable then (
        pkgs.writeScript "deploy-vm.sh" ''
            #! /usr/bin/env bash

            STORAGE_PATH=$(ssh $PROXMOX_ADDR "bash -c 'pvesh get /storage --output-format json | jq -r \".[] | select(.storage | contains(\\\"core-encrypted\\\")) | .path\"'")
            scp result/vm/vzdump-qemu-${toString cfg.metadata.id}-${cfg.metadata.name}.vma.zst "$PROXMOX_ADDR:$STORAGE_PATH/dump/"
            ssh $PROXMOX_ADDR 'bash -s' < result/setup-vm.sh

            echo "Setting tmpfs back to initial size..."
            sudo mount -o remount,size=32G /tmp
        ''
    ) else (pkgs.writeScript "deploy-vm.sh" "echo DOES NOTHING");

    presetupScript = if cfg.enable then (
        pkgs.writeScript "deploy-vm.sh" ''
            #! /usr/bin/env bash

            echo "Ensuring /tmp has enough space..."
            sudo mount -o remount,size=${toString (cfg.storage.disk_size * 2)}M /tmp
        ''
    ) else (pkgs.writeScript "presetup-vm.sh" "echo DOES NOTHING");
in
{
    options = {
        lesbos.proxmox = {
            enable = mkEnableOption "expanded proxmox configuration";
            __deploy_script = mkOption {
                description = "internal deploy script";
                type = types.anything;
                internal = true;
                readOnly = true;
                default = deployScript;
            };
            __setup_script = mkOption {
                description = "internal setup script";
                type = types.anything;
                internal = true;
                readOnly = true;
                default = setupScript;
            };
            __presetup_script = mkOption {
                description = "internal presetup script";
                type = types.anything;
                internal = true;
                readOnly = true;
                default = presetupScript;
            };
            metadata = {
                id = mkOption {
                    description = "VM ID - Mapped into filename and VM name";
                    type = types.ints.positive;
                };
                name = mkOption {
                    description = "VM Name & hostname";
                    type = types.singleLineStr;
                };
                tags = mkOption {
                    description = "VM Tags";
                    type = types.listOf types.singleLineStr;
                };
            };
            storage = mkSubmodule "VM Storage configuration" {
                volume = mkOption {
                    description = "Proxmox storage volume";
                    type = types.singleLineStr;
                    default = "core-encrypted";
                };
                disk_size = mkOption {
                    description = "Root disk size in MiB";
                    type = types.ints.positive;
                    default = 20480; # 20 GiB
                };
                boot_size = mkOption {
                    description = "Size of the boot partition";
                    type = types.singleLineStr;
                    default = "256M";
                };
                extra_disks = mkOption {
                    description = "Configuration of extra disks to add to the VM";
                    type = types.listOf extraDisk;
                    default = [ ];
                };
                virtiofs = mkOption {
                    description = "List of virtiofs shares to expose from the host";
                    type = types.listOf (
                        types.submodule {
                            id = mkOption {
                                description = "Mapping identifier and mount tag";
                                type = types.singleLineStr;
                            };
                            cache = mkOption {
                                description = "Caching mode";
                                type = types.enum [
                                    "auto"
                                    "always"
                                    "metadata"
                                    "never"
                                ];
                                default = "auto";
                            };
                            direct_io = mkOption {
                                description = "Honor the O_DIRECT flag passed down by guest applications";
                                type = types.bool;
                                default = false;
                            };
                            expose_acl = mkOption {
                                description = "Enable support for POSIX ACLs (enabled ACL implies xattr) for this mount";
                                type = types.bool;
                                default = false;
                            };
                            expose_xattr = mkOption {
                                description = "Enable support for extended attributes for this mount";
                                type = types.bool;
                                default = false;
                            };
                        }
                    );
                    default = [ ];
                };
            };
            resources = mkSubmodule "VM resources (RAM, CPU, etc)" {
                cpu_type = mkOption {
                    description = "CPU type (full `cpu` string from proxmox)";
                    type = types.singleLineStr;
                    default = "cputype=host";
                };
                cores = mkOption {
                    description = "Number of CPU cores";
                    type = types.ints.positive;
                    default = 2;
                };
                sockets = mkOption {
                    description = "Number of CPU sockets";
                    type = types.ints.positive;
                    default = 1;
                };
                memory = mkOption {
                    description = "Memory in MiB";
                    type = types.ints.positive;
                    default = 2048;
                };
            };
            network = mkSubmodule "Network interfaces to assign to the guest" {
                primary = mkOption {
                    description = "Primary network interface (net0 - maps to ens18)";
                    type = networkInterface;
                    default = {
                        bridge = "vmbr3";
                        model = "virtio";
                    };
                };
                extra_interfaces = mkOption {
                    description = ''
                        Extra interfaces, starting at net1.

                        On the guest, interfaces (starting at net1) map from ens19 up.
                    '';
                    type = types.listOf networkInterface;
                    default = [ ];
                };
            };
            agent = mkOption {
                description = "Enable the QEMU agent & the guest agent on the host";
                type = types.bool;
                default = true;
            };
            watchdog = mkSubmodule "Configuration of system watchdog" {
                enable = mkEnableOption "hardware watchdog device, and enables basic watchdog functions on the guest";
                action = mkOption {
                    description = "Watchdog action on failure";
                    type = types.enum [
                        "debug"
                        "pause"
                        "poweroff"
                        "reset"
                        "shutdown"
                        "none"
                    ];
                    default = "reset";
                };
            };
            start = mkSubmodule "VM startup configuration" {
                on_boot = mkOption {
                    description = "Whether to start on boot";
                    type = types.bool;
                    default = true;
                };
                on_deploy = mkOption {
                    description = "Whether to start on deploy";
                    type = types.bool;
                    default = true;
                };
                order = mkOption {
                    description = "What order to start in";
                    type = types.nullOr types.ints.positive;
                    default = null;
                };
                delay_up = mkOption {
                    description = "Delay in seconds before starting the next VM";
                    type = types.nullOr types.ints.positive;
                    default = null;
                };
                delay_down = mkOption {
                    description = "Delay in seconds before stopping the next VM";
                    type = types.nullOr types.ints.positive;
                    default = null;
                };
            };
        };
    };

    config = mkIf cfg.enable {
        proxmox = {
            qemuConf = {
                name = "${cfg.metadata.name}";
                scsihw = "virtio-scsi-single";
                boot = "order=virtio0;ide2";
                virtio0 = "${cfg.storage.volume}:vm-${toString cfg.metadata.id}-disk-0";
                ostype = "l26";
                bios = "ovmf";
                cores = cfg.resources.cores;
                memory = cfg.resources.memory;
                net0 = "${cfg.network.primary.model}=00:00:00:00:00:00,bridge=${cfg.network.primary.bridge},firewall=0";
                agent = cfg.agent;
            };
            qemuExtraConf = mkMerge [
                {
                    tags = concatStringsSep "," cfg.metadata.tags;
                    cpu = cfg.resources.cpu_type;
                    sockets = cfg.resources.sockets;
                    onboot = if cfg.start.on_boot then "1" else "0";
                }
                (listToAttrs (
                    imap0 (index: share: {
                        name = "virtiofs${index}";
                        value = concatStringsSep "," [
                            "cache=${share.cache}"
                            "dirid=${share.id}"
                            "direct-io=${if share.direct_io then "1" else "0"}"
                            "expose-xattr=${if share.expose_xattr_io then "1" else "0"}"
                            "expose-acl=${if share.expose_acl then "1" else "0"}"
                        ];
                    }) cfg.storage.virtiofs
                ))
                (listToAttrs (
                    imap1 (index: iface: {
                        name = "net${toString index}";
                        value = "${iface.model}=00:00:00:00:00:00,bridge=${iface.bridge},firewall=0";
                    }) cfg.network.extra_interfaces
                ))
                (optionalAttrs cfg.watchdog.enable {
                    watchdog = "model=i6300esb,action=${cfg.watchdog.action}";
                })
                (optionalAttrs ((!isNull cfg.start.order) || (!isNull cfg.start.delay_up) || (!isNull cfg.start.delay_down)) {
                    startup = concatStringsSep "," (concatLists [
                        (optional (!isNull cfg.start.order) "order=${toString cfg.start.order}")
                        (optional (!isNull cfg.start.delay_up) "up=${toString cfg.start.delay_up}")
                        (optional (!isNull cfg.start.delay_down) "down=${toString cfg.start.delay_down}")
                    ]);
                })
            ];
            partitionTableType = "efi";
            filenameSuffix = "${toString cfg.metadata.id}-${cfg.metadata.name}";
            cloudInit = {
                enable = false;
                defaultStorage = cfg.storage.volume;
            };
        };

        virtualisation.diskSize = cfg.storage.disk_size;
        services.qemuGuest.enable = cfg.agent;
        services.watchdogd = mkIf cfg.watchdog.enable {
            enable = true;
            settings = {
                interval = mkDefault 10;
            };
        };
        networking.hostName = mkForce cfg.metadata.name;
    };
}
