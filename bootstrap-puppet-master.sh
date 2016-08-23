#!/bin/sh

if ps aux | grep "puppet master" | grep -v grep 2> /dev/null
then
    echo "Puppet Master is already installed. Exiting..."
else
    # Install Puppet Master
    wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb && \
    sudo dpkg -i puppetlabs-release-trusty.deb && \
    sudo apt-get update -yq && sudo apt-get upgrade -yq && \
    sudo apt-get install -yq puppetmaster

    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "# Host config for Puppet Master and Agent Nodes" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.56.105    puppet.master.vm" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "192.168.56.106    production.puppet.node.vm" | sudo tee --append /etc/hosts 2> /dev/null     
    sudo sed -i 's/127\.0\.0\.1.*/&\tpuppet.master.vm/' /etc/hosts
 
    # Add optional alternate DNS names and certname to /etc/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\ndns_alt_names = puppet,puppet.master.vm\ncertname=puppet.master.vm/' /etc/puppet/puppet.conf
 
    # Install some initial puppet modules on Puppet Master server
    sudo puppet module install puppetlabs-ntp
    sudo puppet module install garethr-docker
    sudo puppet module install puppetlabs-vcsrepo
 
fi
