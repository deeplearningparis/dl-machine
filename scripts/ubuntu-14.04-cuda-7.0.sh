#!/usr/bin/env bash
# Script to build an Ubuntu-based g2.2xlarge with CUDA 7.0 enabled.

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get -y dist-upgrade
sudo apt-get install -y git wget linux-image-generic build-essential

cd /tmp
wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_7.0-28_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1404_7.0-28_amd64.deb
sudo apt-get update -y
sudo apt-get install -y cuda

echo -e "\nexport CUDA_HOME=/usr/local/cuda\nexport CUDA_ROOT=/usr/local/cuda" >> ~/.bashrc
echo -e "\nexport PATH=/usr/local/cuda/bin:\$PATH\nexport LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc

echo "CUDA installation complete: rebooting the instance now!"
sudo reboot
