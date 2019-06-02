# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/bionic64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
  
    # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = 2

    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--vtxux", "on"]
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL

USER=vagrant

apt-get update \
  && apt-get -y dist-update \
  && apt-get install --no-install-recommends -y \
    qemu qemu-kvm virtinst virt-manager virt-viewer libvirt-bin \
    automake autotools-dev build-essential gawk \
    libffi-dev libxslt-dev libxml2-dev libjson-c-dev libyaml-dev \
    libcurl4-gnutls-dev openssl libssl-dev \
    fuse libfuse-dev \
    zip unzip zlibc zlib1g-dev \
    mysql-client sqlite3 libsqlite3-dev \
    python3 python3-dev \
    ruby ruby-dev \
    openssh-client sshpass \
    whois netcat iputils-ping dnsutils ldap-utils \
    wget curl ipcalc git nfs-common figlet

usermod -a -G kvm $USER

# Setup python and install openstack CLI
rm -f /usr/bin/python
ln -s /usr/bin/python3 /usr/bin/python
curl -sL https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py
rm get-pip.py
pip install pyyaml python-openstackclient python-neutronclient python-glanceclient

# Install cf uaa cli
gem install cf-uaac --no-document

# Install CLIs
pushd /usr/local/bin

curl -o /tmp/packer.zip \
  -sJL https://releases.hashicorp.com/packer/1.4.1/packer_1.4.1_linux_amd64.zip
unzip /tmp/packer.zip
rm -f /tmp/packer.zip

curl \
  -sJL https://github.com/rgl/packer-provisioner-windows-update/releases/download/v0.7.1/packer-provisioner-windows-update-linux.tgz \
  | tar xvz
chmod +x packer-provisioner-windows-update

curl -o bosh \
  -sJL https://github.com/cloudfoundry/bosh-cli/releases/download/v5.5.1/bosh-cli-5.5.1-linux-amd64
chmod +x bosh

curl \
  -sJL https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.4.0/credhub-linux-2.4.0.tgz \
  | tar xvz

curl -o mc \
  -sJL https://dl.minio.io/client/mc/release/linux-amd64/mc
chmod +x mc

# Setup direnv to manage environment variables
curl -o direnv \
  -sJL https://github.com/direnv/direnv/releases/download/v2.20.0/direnv.linux-amd64
chmod +x direnv

popd

set +e
grep 'figlet' /home/$USER/.profile 2>&1 > /dev/null
if [[ $? -ne 0 ]]; then
  echo -e "eval \\"\\$(direnv hook bash)\\"" >> /home/$USER/.bashrc
  echo -e "\necho \"\\n\\n\"" >> /home/$USER/.bashrc
  echo -e "\nfiglet \"PCF Automation\"" >> /home/$USER/.bashrc
  echo -e "\necho \"\\n\"" >> /home/$USER/.bashrc
fi

SHELL

end
