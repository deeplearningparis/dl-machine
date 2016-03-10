#!/usr/bin/env bash
# This script will try to install recent versions of common open source
# tools for deep learning. This requires a Ubuntu 14.04 instance with
# a recent version of CUDA. See "ubuntu-14.04-cuda-6.5.sh" to build setup
# an AWS EC2 g2.2xlarge instance type for instance.
set -xe
cd $HOME


# Check that the NVIDIA drivers are installed properly and the GPU is in a
# good shape:
nvidia-smi

# Build latest stable release of OpenBLAS without OPENMP to make it possible
# to use Python multiprocessing and forks without crash
# The torch install script will install OpenBLAS with OPENMP enabled in
# /opt/OpenBLAS so we need to install the OpenBLAS used by Python in a
# distinct folder.
# Note: the master branch only has the release tags in it
sudo apt-get install -y gfortran
export OPENBLAS_ROOT=/opt/OpenBLAS-no-openmp
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OPENBLAS_ROOT/lib
if [ ! -d "OpenBLAS" ]; then
    git clone -q --branch=master git://github.com/xianyi/OpenBLAS.git
    (cd OpenBLAS \
      && make FC=gfortran USE_OPENMP=0 NO_AFFINITY=1 NUM_THREADS=32 \
      && sudo make install PREFIX=$OPENBLAS_ROOT)
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc
fi
# https://hunseblog.wordpress.com/2014/09/15/installing-numpy-and-openblas/
# Suggested adding this, keeping commented for now, not yet sure is needed
# given the already done export LD_LIBRARY_PATH
#grep -q opt/OpenBLAS /etc/ld.so.conf.d/openblas.conf ||
#    sudo su - -c"echo $OPENBLAS_ROOT/lib >> /etc/ld.so.conf.d/openblas.conf"
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
# Was getting: "ValueError: jpeg is required unless explicitly disabled using --disable-jpeg, aborting"
# Per http://stackoverflow.com/a/34631976/1041319 libjpeg8-dev is missing.
sudo apt-get install libjpeg-dev zlib1g-dev
pip install -U circus circus-web Cython Pillow

# Checkout this project to access installation script and additional resources
if [ ! -d "dl-machine" ]; then
    git clone https://github.com/deeplearningparis/dl-machine.git
else
    if  [ "$1" == "reset" ]; then
        (cd dl-machine && git reset --hard && git checkout master && git pull --rebase origin master)
    fi
fi

# Build numpy from source against OpenBLAS
# You might need to install liblapack-dev package as well
# sudo apt-get install -y liblapack-dev
rm -f ~/.numpy-site.cfg
ln -s dl-machine/numpy-site.cfg ~/.numpy-site.cfg
pip install -U numpy

# Build scipy from source against OpenBLAS
rm -f ~/.scipy-site.cfg
ln -s dl-machine/scipy-site.cfg ~/.scipy-site.cfg
pip install -U scipy

# Install common tools from the scipy stack
sudo apt-get install -y libfreetype6-dev libpng12-dev
pip install -U matplotlib ipython[all] pandas scikit-image

# Scikit-learn (generic machine learning utilities)
pip install -e git+git://github.com/scikit-learn/scikit-learn.git#egg=scikit-learn

# Theano
pip install -e git+git://github.com/Theano/Theano.git#egg=Theano
if [ ! -f ".theanorc" ]; then
    ln -s dl-machine/theanorc ~/.theanorc
fi

# Tutorial files
if [ ! -d "DL4H" ]; then
    git clone https://github.com/SnippyHolloW/DL4H.git
else
    if  [ "$1" == "reset" ]; then
        (cd DL4H && git reset --hard && git checkout master && git pull --rebase origin master)
    fi
fi

# Keras (will be using theano by default)
if [ ! -d "keras" ]; then
    git clone https://github.com/fchollet/keras.git
    (cd keras && python setup.py install)
else
    if  [ "$1" == "reset" ]; then
        (cd keras && git reset --hard && git checkout master && git pull --rebase $REMOTE master && python setup.py install)
    fi
fi

# Tensorflow (cpu mode only, GPU not officially supported on AWS - CUDA 3.0 architecture)
pip install --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-0.5.0-cp27-none-linux_x86_64.whl

# Torch
if [ ! -d "torch" ]; then
    sudo apt-get install -y curl
    curl -sk https://raw.githubusercontent.com/torch/ezinstall/master/install-deps | bash
    git clone https://github.com/torch/distro.git ~/torch --recursive
    sudo apt-get install -y cmake           # Needed.
    sudo apt-get install -y libreadline-dev # Needed, gives "readline.c:7:31: fatal error: readline/readline.h: No such file or directory" otherwise.
    (cd ~/torch && yes | ./install.sh)      # Took fairly long on a vm though.
fi
. ~/torch/install/bin/torch-activate

if [ ! -d "iTorch" ]; then
    git clone https://github.com/facebook/iTorch.git
else
    if  [ "$1" == "reset" ]; then
        (cd iTorch && git reset --hard && git checkout master && git pull --rebase origin master)
    fi
fi
sudo apt-get install -y libzmq3-dev libssl-dev python-zmq # Needed, otherwise, "Missing dependencies for itorch: luacrypto, uuid, lzmq >= 0.4.2"
(cd iTorch && luarocks make)


# Install caffe

sudo apt-get install -y protobuf-compiler libboost-all-dev libgflags-dev libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libsnappy-dev libopencv-dev libyaml-dev libprotobuf-dev

if [ ! -d "caffe" ]; then
    git clone https://github.com/BVLC/caffe.git
    # For CPU only can use: cat $HOME/dl-machine/caffe-Makefile.conf | sed -e 's/# CPU_ONLY/CPU_ONLY/' > Makefile.conf && \
    (cd caffe && \
      cp $HOME/dl-machine/caffe-Makefile.conf Makefile.conf && \
      cmake -DBLAS=open . && make all)
    (cd caffe/python && pip install -r requirements.txt)
else
    if [ "$1" == "reset" ]; then
        (cd caffe && git reset --hard && git checkout master && git pull --rebase origin master && cp $HOME/dl-machine/caffe-Makefile.conf Makefile.conf && cmake -DBLAS=open . && make all)
    fi
fi

# Install Caffe from nvidia packages as a backup if the above build does not work
# https://github.com/NVIDIA/DIGITS/blob/master/docs/UbuntuInstall.md#repository-access
install_caffe_nvidia_packaging() {
  CUDA_REPO_PKG=cuda-repo-ubuntu1404_7.5-18_amd64.deb &&
      wget http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/$CUDA_REPO_PKG &&
      sudo dpkg -i $CUDA_REPO_PKG
  ML_REPO_PKG=nvidia-machine-learning-repo_4.0-2_amd64.deb &&
      wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1404/x86_64/$ML_REPO_PKG &&
      sudo dpkg -i $ML_REPO_PKG
  sudo apt-get install -y caffe-nv python-caffe-nv
}

# Register the circus daemon with Upstart
if [ ! -f "/etc/init/circus.conf" ]; then
    sed -e"s/ubuntu/$USER/g" ~/dl-machine/circus.conf | sudo bash -c 'cat - > /etc/init/circus.conf'
    sudo initctl reload-configuration
fi
# TODO: resolve issue: "start: Job failed to start"
sudo service circus restart


# Register a task job to get the main repo of the image automatically up to date
# at boot time
if [ ! -f "/etc/init/update-instance.conf" ]; then
    sed -e"s/ubuntu/$USER/g" ~/dl-machine/update-instance.conf | sudo bash -c 'cat - > /etc/init/update-instance.conf'
fi
