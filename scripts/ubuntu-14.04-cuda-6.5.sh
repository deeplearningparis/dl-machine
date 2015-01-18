#!/usr/bin/env bash
# Script to build an Ubuntu-based g2.2xlarge with CUDA 6.5 enabled.

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get -y dist-upgrade
sudo apt-get install -y git wget linux-image-generic build-essential gfortran

cd /tmp
wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_6.5-14_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1404_6.5-14_amd64.deb
sudo apt-get update -y
sudo apt-get install -y cuda 

export CUDA_HOME=/usr/local/cuda-6.5
export LD_LIBRARY_PATH=${CUDA_HOME}/lib64
export PATH=${CUDA_HOME}/bin:${PATH}

echo "export CUDA_HOME=/usr/local/cuda-6.5" >> ~/.bashrc
echo "export CUDA_ROOT=$CUDA_HOME" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=${CUDA_HOME}:${CUDA_HOME}/lib64" >> ~/.bashrc
echo "export PATH=${CUDA_HOME}/bin:${PATH}" >> ~/.bashrc

echo "CUDA installation complete: rebooting the instance now!"
sudo reboot
