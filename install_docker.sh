#!/bin/bash

sudo apt-get -Yq update
sudo apt-get -Yq install apt-transport-https ca-certificates

sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list

sudo apt-get -Yq update
sudo apt-get -Y purge lxc-docker
apt-cache policy docker-engine

sudo apt-get -Y update
sudo apt-get install docker-engine
sudo service docker start


