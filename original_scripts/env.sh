#!/usr/bin/env bash
set -e

CONDA_ENV="atc"
PYTHON_VERSION="3.9.2"

echo "[INFO] 检查 conda 是否已安装..."
if ! command -v conda &>/dev/null; then
    echo "[INFO] 未检测到 conda,开始安装 Miniconda..."
    wget -O Miniconda3.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3.sh -b -p $HOME/miniconda3
    rm Miniconda3.sh

    echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "[INFO] 检测到 conda,跳过安装"
fi

echo "[INFO] 检查环境 $CONDA_ENV..."
if conda env list | grep -q "$CONDA_ENV"; then
    echo "[INFO] 环境 $CONDA_ENV 已存在，跳过创建"
else
    echo "[INFO] 创建 conda 环境: $CONDA_ENV (Python $PYTHON_VERSION)"
    conda create -y -n $CONDA_ENV python=$PYTHON_VERSION
fi

echo "[INFO] 激活环境..."
# which conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate $CONDA_ENV

echo "[INFO] 安装依赖..."
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
    protobuf==3.13.0 \
    psutil==5.7.0 \
    numpy==2.0.2 \
    scipy==1.13.1 \
    decorator==4.4.0 \
    sympy==1.5.1 \
    cffi==1.12.3 \
    pyyaml==6.0.2 \
    pathlib2

echo "[INFO] Python 环境准备完成: $CONDA_ENV"
