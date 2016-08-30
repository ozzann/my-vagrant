#!/bin/sh
 
if ps aux | grep "puppet agent" | grep -v grep 2> /dev/null
then
    echo "Puppet Agent is already installed. Moving on..."
else
    sudo apt-get update -yq && sudo apt-get upgrade -yq
    sudo apt-get install -yq puppet
fi
 
if cat /etc/crontab | grep puppet 2> /dev/null
then
    echo "Puppet Agent is already configured. Exiting..."
else
    sudo puppet resource cron puppet-agent ensure=present user=root minute=30 command='/usr/bin/puppet agent --onetime --no-daemonize --splay'
 
    sudo puppet resource service puppet ensure=running enable=true
 
    # Configure /etc/hosts file
    echo "" | sudo tee --append /etc/hosts 2> /dev/null && \
    echo "# Host config for Puppet Master and Agent Nodes" | sudo tee --append /etc/hosts 2> /dev/null
    echo "192.168.56.105    puppet.master.vm" | sudo tee --append /etc/hosts 2> /dev/null
    echo "192.168.56.106    production.puppet.node.vm" | sudo tee --append /etc/hosts 2> /dev/null
    sudo sed -i 's/127\.0\.0\.1.*/&\tproduction.puppet.node.vm/' /etc/hosts
 
    # Add agent section to /etc/puppet/puppet.conf
    echo "" && echo "[agent]\nserver=puppet.master.vm" | sudo tee --append /etc/puppet/puppet.conf 2> /dev/null
    # Add certname to main section of /etc/puppet/puppet.conf
    sudo sed -i 's/.*\[main\].*/&\ncertname=production.puppet.node.vm/' /etc/puppet/puppet.conf

    sudo puppet agent --enable
fi
