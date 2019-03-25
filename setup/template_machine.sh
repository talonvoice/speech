#!/bin/bash -ue

sudo apt-get -y install vim screen tmux aria2

## START wav2letter++

# from https://www.tensorflow.org/install/gpu
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo apt install ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
sudo apt-get -y update
sudo apt-get -y install --no-install-recommends cuda-10-0 libcudnn7=7.4.1.5-1+cuda10.0 libcudnn7-dev=7.4.1.5-1+cuda10.0
rm {cuda,nvidia}*-repo-*.deb

# from wav2letter++ Dockerfile-CUDA https://github.com/facebookresearch/wav2letter/blob/master/Dockerfile-CUDA
sudo apt-get install -y build-essential ca-certificates cmake wget git vim emacs nano htop g++ openssh-server openssh-client libopenmpi-dev libomp-dev libnccl2 libnccl-dev autoconf automake autogen build-essential libasound2-dev libflac-dev libogg-dev libopus-dev libopus-dev libtool libvorbis-dev pkg-config python cpio libfftw3-dev zlib1g-dev libbz2-dev liblzma-dev libboost-all-dev libgflags-dev libgoogle-glog-dev sox libcublas-dev libsox-fmt-mp3

cd /tmp
wget https://github.com/Kitware/CMake/releases/download/v3.14.0/cmake-3.14.0-Linux-x86_64.sh -O cmake.sh
if [[ "$(sha256sum cmake.sh | awk '{print $1}')" != "7f3e227cfd9804ee9931490a83cb7029991bc73573ceb1c8ba11714775e8c334" ]]; then
    echo "cmake check hash failed"
    exit 1
fi
sudo ./cmake.sh --prefix=/usr/local/ --skip-license

# ==================================================================
# python (for receipts data processing)
# ------------------------------------------------------------------
sudo apt-get install -y python3-dev python3-pip
sudo pip3 install sox tqdm

# ==================================================================
# arrayfire https://github.com/arrayfire/arrayfire/wiki/
# ------------------------------------------------------------------
cd /tmp
git clone --recursive https://github.com/arrayfire/arrayfire.git

cd arrayfire
git checkout v3.6.2
mkdir build && cd build
CXXFLAGS=-DOS_LNX cmake .. -DCMAKE_BUILD_TYPE=Release -DAF_BUILD_CPU=OFF -DAF_BUILD_OPENCL=OFF -DAF_BUILD_EXAMPLES=OFF
make -j8
sudo make install

# ==================================================================
# flashlight https://github.com/facebookresearch/flashlight.git
# ------------------------------------------------------------------
# If the driver is not found (during docker build) the cuda driver api need to be linked against the
# libcuda.so stub located in the lib[64]/stubs directory
cd /tmp
git clone --recursive https://github.com/facebookresearch/flashlight.git
cd flashlight && mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DFLASHLIGHT_BACKEND=CUDA
make -j8
sudo make install

# ==================================================================
# libsndfile https://github.com/erikd/libsndfile.git
# ------------------------------------------------------------------
cd /tmp
git clone https://github.com/erikd/libsndfile.git
cd libsndfile
git checkout 5056a77fdae85f96eee4dff82af462db5a5c341e
./autogen.sh
./configure --enable-werror
make -j8 && make check
sudo make install

# ==================================================================
# MKL https://software.intel.com/en-us/mkl
# ------------------------------------------------------------------
cd /tmp
wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
sudo apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
wget https://apt.repos.intel.com/setup/intelproducts.list -O /etc/apt/sources.list.d/intelproducts.list
sudo sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list'
sudo apt-get update
sudo apt-get install -y intel-mkl-64bit-2018.4-057

# ==================================================================
# KenLM https://github.com/kpu/kenlm
# ------------------------------------------------------------------
if [[ ! -e /opt/kenlm ]]; then
    sudo mkdir /opt/kenlm
    sudo chmod 777 /opt/kenlm
    cd /opt && git clone https://github.com/kpu/kenlm.git
    cd kenlm && git checkout e47088ddfae810a5ee4c8a9923b5f8071bed1ae8
    mkdir build && cd build
    cmake .. &&
    make -j8
    sudo make install
fi

# ==================================================================
# config & cleanup
# ------------------------------------------------------------------
sudo ldconfig
sudo apt-get clean
sudo apt-get autoremove
sudo rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

# ==================================================================
# wav2letter with GPU backend https://github.com/facebookresearch/wav2letter
# ------------------------------------------------------------------
sudo mkdir /opt/wav2letter
sudo chmod 777 /opt/wav2letter
cd /opt && git clone https://github.com/facebookresearch/wav2letter.git
cd wav2letter
mkdir build && cd build

export MKLROOT=/opt/intel/mkl
export KENLM_ROOT_DIR=/opt/kenlm
cmake .. -DCMAKE_BUILD_TYPE=Release -DW2L_CRITERION_BACKEND=CUDA
make -j8
