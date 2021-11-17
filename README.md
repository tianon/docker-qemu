# tianon/qemu

```console
$ touch /home/jsmith/hda.qcow2
$ docker run -it --rm \
	--device /dev/kvm \
	--name qemu-container \
	-v /home/jsmith/hda.qcow2:/tmp/hda.qcow2 \
	-e QEMU_HDA=/tmp/hda.qcow2 \
	-e QEMU_HDA_SIZE=100G \
	-e QEMU_CPU=4 \
	-e QEMU_RAM=4096 \
	-v /home/jsmith/downloads/debian.iso:/tmp/debian.iso:ro \
	-e QEMU_CDROM=/tmp/debian.iso \
	-e QEMU_BOOT='order=d' \
	-e QEMU_PORTS='2375 2376' \
	tianon/qemu:native
```

Note: port 22 will always be mapped (regardless of the contents of `QEMU_PORTS`).

For supplying additional arguments, use a command of `start-qemu <args>`. For example, to use `-curses`, one would `docker run ... tianon/qemu start-qemu -curses`.

For UEFI support, [the `ovmf` package](https://packages.debian.org/sid/ovmf) is installed, which can be utilized most easily by supplying `--bios /usr/share/ovmf/OVMF.fd`.

By default, this image will use [QEMU's user-mode networking stack](https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29), which means if you want ping/ICMP working, you'll likely need to also include something like `--sysctl net.ipv4.ping_group_range='0 2147483647'` in your container runtime settings.

The `native` variants for `amd64` only contain `qemu-system-x86_64` -- the non-`native` variants contain QEMU compiled for a variety of target CPUs.

## For non-native

```console
$ touch /hdimages/armhf.qcow2
$ docker run -it --rm \
    --device /dev/kvm \
    --name qemu-container-arm \
    --user="$(id --user):$(id --group)" \
    -v /hdimages/armhf.qcow2:/tmp/hda.qcow2 \
    -v /bootimages/initrd-debian11-armhf.gz:/tmp/initrd.gz \
    -v /bootimages/vmlinuz-debian11-armhf:/tmp/vmlinuz \
    -e QEMU_HDA=/tmp/hda.qcow2 \
    -e QEMU_HDA_SIZE=20G \
    -e QEMU_CPU=1 \
    -e QEMU_RAM=1024 \
    -v /cdimages/debian-11.1.0-armhf-netinst.iso:/tmp/debian.iso:ro \
    -e QEMU_CDROM=/tmp/debian.iso \
    -e QEMU_BOOT='order=d' \
    -e QEMU_PORTS='2375 2376' \
    -e QEMU_ARCH='arm' \
    -e QEMU_MACHINE='virt' \
    -e QEMU_KERNEL=/tmp/vmlinuz \
    -e QEMU_INITRD=/tmp/initrd.gz \
    <your alias>/qemu:6.1
```

If ARM or MIPS is selected, kernel image and initrd image are required, so use it like [here (non-EFI)](https://gist.github.com/KunoiSayami/934c7690dcf357f42537562dbdf90b56) or [here (EFI)](https://gist.github.com/ag88/163a7c389af0c6dcef5a32a3394e8bac)

### Manually root activation

When using the ARM platform, it was confirmed that the settings were not reflected in `/etc/passwd` and `/etc/shadow`.
