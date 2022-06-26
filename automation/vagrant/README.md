# Vagrant Automation

See the references for the original information.

TLDR: You can use `packer`/`vagrant` to automate the process for setting up the windows server machine.

TODO:
- Change the Unattend.xml file in order to remove the GUI component.
- Change the Memory to 512 Mb and and CPU to 1

```bash
# sudo apt install packer
packer build template.json

# sudo apt install vagrant
vagrant box add --name dc1 dc1.box

# start the machine
vagrant up
```

## References

- [Packer template for Windows Server 2019 Vagrant box](https://github.com/mcree/vagrant-windows-server-2019)

