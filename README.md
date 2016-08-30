# my-vagrant

This project contains Vagrant file which creates an environment
and some shell scripts and required configuration files.

Vagrant creates three virtual machine:
    -- jenkins.server.vm with Jenkins installed
    -- puppet.master.vm which manages Production VM by Puppet
    -- production.puppet.node.vm - endpoint of the pipeline where the application should be deployed



To set up the environment just run a command:
      
      vagrant up


Then after all virtual machines have set up, 
one should synchronize puppet master and puppet node by running:
  
    sudo puppet agent -t     # run puppet agent at production.puppet.node.vm

    sudo puppet cert list --all     # at puppet.master.vm to reassure there is a certificate 
                               #  for 'production.puppet.node.vm'

    sudo puppet cert sign --all     # sign all certificates at puppet.master
                               # including just created certificate 
                               # from 'production.puppet.node.vm'
 
    sudo puppet agent -t     # run agent to apply puppet manifests at production.puppet.node.vm


In order to check if everything is set up correct, one should call curl command:

    curl http://localhost:9000    # at production.puppet.node.vm

or

    curl 192.168.56.106:9000    # at any other virtual machine. This IP address is production VM's IP.
