#!/bin/bash

git clone https://github.com/BVLC/caffe.git

# git clone https://github.com/scikit-image/scikit-image.git
# cd scikit-image
# python setup.py install

pip install pillow networkx
pip install scikit-image

sudo apt-get install protobuf-compiler

sudo apt-get install libboost-all-dev

sudo apt-get install libgflags-dev

sudo apt-get install libgoogle-glog-dev

sudo apt-get install libhdf5-serial-dev

sudo apt-get install libleveldb-dev

sudo apt-get install liblmdb-dev

sudo apt-get install libsnappy-dev

sudo apt-get install libdc1394-22-dev

cd caffe/python
pip install -r requirements.txt
