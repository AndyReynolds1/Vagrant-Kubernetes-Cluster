# Variables
BOX_NAME = "ubuntu/focal64"

Vagrant.configure("2") do |config|
  
  # Add hosts file entries for all nodes
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    echo "192.168.56.10  master" >> /etc/hosts
    echo "192.168.56.11  node-01" >> /etc/hosts
    echo "192.168.56.12  node-02" >> /etc/hosts
  SHELL

  # Master node
  config.vm.define "master" do |master|
    master.vm.box = BOX_NAME
    master.vm.hostname = "master-01"
    master.vm.network "private_network", ip: "192.168.56.10", netmask: "255.255.255.0"
    master.vm.provider "virtualbox" do |vb|
      vb.name = "master-01"  
      vb.memory = 4048
      vb.cpus = 2
    end
    master.vm.provision "shell", path: "scripts/common.sh"
    master.vm.provision "shell", path: "scripts/master.sh"
  end

  # Worker nodes
  (1..2).each do |i|
  
    config.vm.define "node-0#{i}" do |node|
      node.vm.box = BOX_NAME
      node.vm.hostname = "node-0#{i}"
      node.vm.network "private_network", ip: "192.168.56.1#{i}", netmask: "255.255.255.0"
      node.vm.provider "virtualbox" do |vb|
        vb.name = "node-0#{i}"
        vb.memory = 2048
        vb.cpus = 1
      end
      node.vm.provision "shell", path: "scripts/common.sh"
      node.vm.provision "shell", inline: "sudo /bin/bash /vagrant/config/join.sh -v"
    end
  end
end
