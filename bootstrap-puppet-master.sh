#!/bin/bash


sudo service network-manager stop
sudo ifdown eth1
sudo ifup eth1
sudo service network-manager start


if ps aux | grep "puppet master" | grep -v grep 2> /dev/null
then
    echo "Puppet Master is already installed. Exiting..."
else
    # Install Puppet Master
    wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb 
    sudo dpkg -i puppetlabs-release-trusty.deb 
    sudo apt-get update -yq && sudo apt-get upgrade -yq 
    sudo apt-get install -yq puppetmaster

    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null 
    echo "# Host config for Puppet Master and Agent Nodes" | sudo tee --append /etc/hosts 2> /dev/null 

    # Install jq to parse nodes json file
    sudo apt-get install -y jq

    sudo cp /vagrant/nodes.json nodes.json

    length=$(jq <"nodes.json" '.nodes["puppet.master.vm"][":links"] | length')

    for (( i=0; i<$length; i++ ))
    do

        ip=$(jq <"nodes.json" --arg index $i '.nodes["puppet.master.vm"][":links"][$index|tonumber][":ip"]')

        hostname=$(jq <"nodes.json" --arg index $i '.nodes["puppet.master.vm"][":links"][$index|tonumber][":hostname"]')
    
        host=$(echo "$ip $hostname" | sed 's/"//g')

        sudo echo "$host" >> /etc/hosts
    done
    
    sudo sed -i 's/127\.0\.0\.1.*/&\tpuppet.master.vm/' /etc/hosts
 
    # Add optional alternate DNS names and certname to /etc/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\ndns_alt_names = puppet,puppet.master.vm\ncertname=puppet.master.vm/' /etc/puppet/puppet.conf
    sudo sed -i 's/^templatedir=.*//' /etc/puppet/puppet.conf
 
    # Install some initial puppet modules on Puppet Master server
    sudo puppet module install puppetlabs-ntp
    sudo puppet module install garethr-docker
    sudo puppet module install puppetlabs-vcsrepo

    sudo usermod -a -G puppet vagrant
    sudo chgrp puppet -R /etc/puppet
    sudo chmod g+w -R /etc/puppet 
fi
