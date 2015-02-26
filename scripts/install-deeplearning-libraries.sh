#!/usr/bin/env bash
# This script will try to install recent versions of common open source
# tools for deep learning. This requires a Ubuntu 14.04 instance with
# a recent version of CUDA. See "ubuntu-14.04-cuda-6.5.sh" to build setup
# an AWS EC2 g2.2xlarge instance type for instance.
set -xe
cd $HOME

# Make it possible to pull from the HTTP remote when ssh environment is
# not available such for instance at boot time
if [ "$2" == 'http' ]; then
    REMOTE="http"
else
    REMOTE="origin"
fi

# Check that the NVIDIA drivers are installed properly and the GPU is in a
# good shape:
nvidia-smi

# Build latest stable release of OpenBLAS without OPENMP to make it possible
# to use Python multiprocessing and forks without crash
# The torch install script will install OpenBLAS with OPENMP enabled in
# /opt/OpenBLAS so we need to install the OpenBLAS used by Python in a
# distinct folder.
# Note: the master branch only has the release tags in it
sudo chown ubuntu:ubuntu /opt/

if [ ! -d "OpenBLAS" ]; then
    git clone -q --branch=master git://github.com/xianyi/OpenBLAS.git
    export OPENBLAS_ROOT=/opt/OpenBLAS-no-openmp
    (cd OpenBLAS \
      && make FC=gfortran USE_OPENMP=0 NO_AFFINITY=1 NUM_THREADS=32 \
      && make install PREFIX=$OPENBLAS_ROOT)
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OPENBLAS_ROOT/lib
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc
fi
sudo ldconfig

# Python basics: update pip and setup a virtualenv to avoid mixing packages
# installed from source with system packages
sudo apt-get update
sudo apt-get install -y python-dev python-pip htop
sudo pip install -U pip virtualenv
if [ ! -d "venv" ]; then
    virtualenv venv
    echo "source ~/venv/bin/activate" >> ~/.bashrc
fi
source venv/bin/activate
pip install -U pip
pip install -U circus circus-web Cython Pillow

# Checkout this project to access installation script and additional resources
if [ ! -d "dl-machine" ]; then
    git clone git@github.com:deeplearningparis/dl-machine.git
    git remote add http https://github.com/deeplearningparis/dl-machine.git
else
    if  [ "$1" == "reset" ]; then
        (cd dl-machine && git reset --hard && git checkout master && git pull --rebase $REMOTE master)
    fi
fi

# Build numpy from source against OpenBLAS
if [ ! -d "numpy" ]; then
    git clone -q --branch=v1.9.1 git://github.com/numpy/numpy.git
    ln -s dl-machine/numpy-site.cfg numpy/site.cfg
    (cd numpy && python setup.py install)
fi

# Build scipy from source against OpenBLAS
if [ ! -d "scipy" ]; then
    git clone -q --branch=v0.15.1  git://github.com/scipy/scipy.git
    ln -s dl-machine/scipy-site.cfg scipy/site.cfg
    (cd scipy && python setup.py install)
fi

# Install common tools from the scipy stack
sudo apt-get install -y libfreetype6-dev libpng12-dev
pip install -U matplotlib ipython[all] pandas

# Scikit-learn (generic machine learning utilities)
pip install -e git+git://github.com/scikit-learn/scikit-learn.git#egg=scikit-learn

# Theano
pip install -e git+git://github.com/Theano/Theano.git#egg=Theano
if [ ! -f ".theanorc" ]; then
    ln -s dl-machine/theanorc ~/.theanorc
fi

# Tutorial files
if [ ! -d "DL4H" ]; then
    git clone git@github.com:SnippyHolloW/DL4H.git
    git remote add http https://github.com/SnippyHolloW/DL4H.git
else
    if  [ "$1" == "reset" ]; then
        (cd DL4H && git reset --hard && git checkout master && git pull --rebase $REMOTE master)
    fi
fi

# Torch
if [ ! -d "torch" ]; then
    curl -sk https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash
    git clone https://github.com/torch/distro.git ~/torch --recursive
    (cd ~/torch && yes | ./install.sh)
    source .bashrc
fi

export PATH=$PATH:$HOME/torch/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/torch/lib

if [ ! -d "iTorch" ]; then
    git clone git@github.com:facebook/iTorch.git
    git remote add http https://github.com/facebook/iTorch.git
else
    if  [ "$1" == "reset" ]; then
        (cd iTorch && git reset --hard && git checkout master && git pull --rebase $REMOTE master)
    fi
fi
(cd iTorch && luarocks make)

# Register the circus daemon with Upstart
if [ ! -f "/etc/init/circus.conf" ]; then
    sudo ln -s /home/ubuntu/dl-machine/circus.conf /etc/init/circus.conf
    sudo initctl reload-configuration
fi
sudo service circus restart


# Register a task job to get the main repo of the image automatically up to date
# at boot time
if [ ! -f "/etc/init/update-instance.conf" ]; then
    sudo ln -s /home/ubuntu/dl-machine/update-instance.conf /etc/init/update-instance.conf
fi
