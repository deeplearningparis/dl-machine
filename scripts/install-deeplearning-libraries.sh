#!/usr/bin/env bash
# This script will try to install recent versions of common open source
# tools for deep learning. This requires a Ubuntu 14.04 instance with
# a recent version of CUDA. See "ubuntu-14.04-cuda-6.5.sh" to build setup
# an AWS EC2 g2.2xlarge instance type for instance.
set -xe

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
git clone -q --branch=master git://github.com/xianyi/OpenBLAS.git
export OPENBLAS_ROOT=/opt/OpenBLAS-no-openmp
(cd OpenBLAS \
  && make FC=gfortran USE_OPENMP=0 NO_AFFINITY=1 NUM_THREADS=32 \
  && make install PREFIX=$OPENBLAS_ROOT)
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OPENBLAS_ROOT/lib
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc
sudo ldconfig

# Python basics: update pip and setup a virtualenv to avoid mixing packages
# installed from source with system packages
sudo apt-get install -y python-dev python-pip htop
sudo pip install -U pip virtualenv
virtualenv venv
source venv/bin/activate
echo "source ~/venv/bin/activate" >> ~/.bashrc
pip install Cython

# Build numpy from source against OpenBLAS
git clone -q --branch=v1.9.1 git://github.com/numpy/numpy.git
echo "[openblas]" >> numpy/site.cfg
echo "libraries = openblas" >> numpy/site.cfg
echo "library_dirs = $OPENBLAS_ROOT/lib" >> numpy/site.cfg
echo "include_dirs = $OPENBLAS_ROOT/include" >> numpy/site.cfg
(cd numpy && python setup.py install)

# Build scipy from source against OpenBLAS
git clone -q --branch=v0.15.1  git://github.com/scipy/scipy.git
echo "[DEFAULT]" >> scipy/site.cfg
echo "library_dirs = $OPENBLAS_ROOT/lib:/usr/local/lib" >> scipy/site.cfg
echo "include_dirs = $OPENBLAS_ROOT/include:/usr/local/include" >> scipy/site.cfg
echo "[blas_opt]" >> scipy/site.cfg
echo "libraries = openblas" >> scipy/site.cfg
echo "[lapack_opt]" >> scipy/site.cfg
echo "libraries = openblas" >> scipy/site.cfg
(cd scipy && python setup.py install)

# Install common tools from the scipy stack
sudo apt-get install -y libfreetype6-dev libpng12-dev
pip install matplotlib ipython[all] pandas

# Scikit-learn (generic machine learning utilities)
pip install -e git+git://github.com/scikit-learn/scikit-learn.git#egg=scikit-learn

# Theano
pip install -e git+git://github.com/Theano/Theano.git#egg=Theano

# Torch
curl -sk https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash
curl -sk https://raw.githubusercontent.com/torch/ezinstall/master/install-luajit+torch | PREFIX=~/torch bash
echo "export PATH=~/torch/bin:\$PATH; export LD_LIBRARY_PATH=~/torch/lib:\$LD_LIBRARY_PATH; " >>~/.bashrc && source ~/.bashrc
git clone https://github.com/facebook/iTorch.git
(cd iTorch && luarocks make)
