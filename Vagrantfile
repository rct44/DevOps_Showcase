# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp-vagrant/centos-7.4"
  config.vm.hostname = "vagrantCentos"
#  config.vm.synced_folder "share/", "/vagrant"
  config.vm.synced_folder ".", "/vagrant"
  config.vm.network "forwarded_port", guest: 5000, host: 5000

  config.vm.provider "virtualbox" do |vb|
   # Display the VirtualBox GUI when booting the machine
   # vb.gui = true
   # Customize the amount of memory on the VM:
    vb.memory = "4096"
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--vram", "64"]
	vb.customize ["modifyvm", :id, "--monitorcount", "1"]
  end

  #config.vbguest.auto_update = false

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-'SHELL'
    sudo yum install epel-release -y
	sudo yum install ansible -y
	sudo yum upgrade ansible
	cd /vagrant/ansible
	ansible-galaxy install -r requirements.yml
	ansible-playbook -i 'localhost,' -c local site.yml
  SHELL
end
