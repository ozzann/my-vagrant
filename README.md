## Vagrant to provision a CI pipeline with Docker, Jenkins and Puppet

This repo contains Vagrantfile and bootstrap shell scripts, and some configs required for all VMs to set up correctly. 

The goal of this Vagrant file is to create a simplified real environment, including Jenkins server for CI and a production server. More detailed, it should put together a pipeline from a GitHub repository through a Jenkins build to deploy an application running in a Docker container, with a redeployment every time a change is checked in that builds and tests correctly. The application deployed at the production is a simple C# network application. It listens on a port and send back "Hello, world!" message.

The Vagrantfile creates three virtual machines. One of them is for Jenkins Server. Also because the production should be managed by Puppet, there are also Puppet Master VM and Production VM is a Puppet Agent at the same time. All of the machines are Ubuntu Desktop 14.04 based development boxes.

This project contains Vagrant file which creates an environment
and some shell scripts and required configuration files.

## Prerequisites

In order to provision this system one has to have only Vagrant and VirtualBox installed.

## Usage


After cloning this directory to set up the environment run a command:
      
      vagrant up


Then after all VMs had successfully set up, one should build Jenkins 'app' job and after that synchronize Puppet master and Puppet Client manually by running these commands:

  - run puppet agent at production.puppet.node.vm
    
    	sudo puppet agent -t

  - at puppet.master.vm to reassure there is a certificate for 'production.puppet.node.vm'
    
    	sudo puppet cert list --all     

  - sign all certificates at puppet.master including just created certificate from 'production.puppet.node.vm'
  
    	sudo puppet cert sign --all
        
  - run agent to apply puppet manifests at 'production.puppet.node.vm'
  
    	sudo puppet agent -t


As a result three virtual machines: **jenkins.server.vm, puppet.master.vm, production.puppet.node.vm** should be running.

In order to check if everything is set up correct call curl command at 'production.puppet.node':

    curl localhost:9000

or ping a server from any other VM using its IP address:

    curl 192.168.56.106:9000
    
    
## What's inside




