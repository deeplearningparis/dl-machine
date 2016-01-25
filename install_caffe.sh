#!/bin/bash

sudo apt-get install protobuf-compiler libboost-all-dev libgflags-dev libgoogle-glog-dev libhdf5-serial-dev libleveldb-dev liblmdb-dev libsnappy-dev libopencv-dev libyaml-dev

git clone https://github.com/BVLC/caffe.git ../caffe

cp Makefile.config.example ../caffe/Makefile.config

cd ../caffe
make all
make pycaffe

cd python
pip install networkx -U
pip install pillow -U
pip install -r requirements.txt

ln -s /home/ubuntu/caffe/python/caffe /home/ubuntu/venv/lib/python2.7/site-packages/caffe
