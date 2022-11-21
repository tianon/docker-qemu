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


## running a cloud-init template
```bash
wget -O hda.qcow2 https://cloud-images.ubuntu.com/minimal/releases/focal/release/ubuntu-20.04-minimal-cloudimg-amd64.img

cat > metadata.yaml <<EOF
instance-id: myinstanceid
local-hostname: sample-host
EOF

cat > user-data.yaml <<EOF
#cloud-config
users:
  - name: ubuntu
    groups: [ sudo ]
    shell: /bin/bash
    lock_passwd: false
    passwd: "$6$oJOMxTzH.9aSN$Sq97LTr4JLrtUxZ7qDb1UcMz13iwdLIRhjIVlE.DyiA8lamx.uyhs84wMQ6KURLW9PCo/W4Us31dnd0TE6h4h1"
# password is ubuntu
EOF


docker run -it --rm \
	--device /dev/kvm \
	--name qemu-container \
	-v $PWD/hda.qcow2:/tmp/hda.qcow2 \
	-v $PWD/metadata.yaml:/tmp/metadata.yaml \
	-v $PWD/user-data.yaml:/tmp/user-data.yaml \
	-e QEMU_HDA=/tmp/hda.qcow2 \
	-e QEMU_HDA_SIZE=100G \
	-e QEMU_CPU=4 \
	-e QEMU_RAM=4096 \
	-e QEMU_BOOT='order=d' \
	-e QEMU_PORTS='2375 2376' \
	-p "5900:5900" \
	docker-qemu \
	  /bin/bash -c "/usr/bin/cloud-localds /tmp/seed.img /tmp/user-data.yaml /tmp/metadata.yaml && start-qemu -drive if=virtio,format=raw,file=/tmp/seed.img"

```

