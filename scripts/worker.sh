#! /bin/bash

# Join cluster
sudo /bin/bash /vagrant/config/join.sh -v

# Setup config file for kubectl
mkdir -p $HOME/.kube
sudo cp -i /vagrant/config/config $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo chmod 600 $HOME/.kube/config