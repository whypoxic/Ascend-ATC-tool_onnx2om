#!/usr/bin/env bash
set -e 

# ========= 0. 参数检查 =========
if [ $# -ne 2 ]; then
    echo "用法: $0 <onnx模型文件名> <输出om模型名>"
    echo "示例: $0 yolov5s.onnx yolov5s_om"
    exit 1
fi

# ======== A.环境配置 ========

echo "======== A.环境配置 ========"

CONDA_ENV="atc"
PYTHON_VERSION="3.9.2"

# ======== 1.安装conda ========
echo "[INFO] 检查 conda 是否已安装..."
if ! command -v conda &>/dev/null; then
    echo "[INFO] 未检测到 conda,开始安装 Miniconda..."
    wget -O Miniconda3.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash Miniconda3.sh -b -p $HOME/miniconda3
    rm Miniconda3.sh

    echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

    export PATH="$HOME/miniconda3/bin:$PATH"
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

# ======== 2.安装环境 ========

echo "[INFO] 安装依赖..."
pip install -i https://pypi.tuna.tsinghua.edu.cn/simple \
    protobuf \
    psutil \
    numpy \
    scipy \
    decorator \
    sympy \
    cffi \
    pyyaml \
    pathlib2

echo "[INFO] Python 环境准备完成: $CONDA_ENV"




# ======== B.模型转化 ========
echo "======== B.模型转化 ========"

ONNX_MODEL="$1"
OM_MODEL="$2"

# ========= 1. 路径定义 =========
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $SCRIPT_DIR
TOOLKIT_ROOT="$SCRIPT_DIR"
echo $TOOLKIT_ROOT
RUN_DIR="$SCRIPT_DIR/run"

# ========= 2. 检查文件 =========
if [ ! -f "$RUN_DIR/$ONNX_MODEL" ]; then
    echo "[ERROR] ONNX 模型不存在: $RUN_DIR/$ONNX_MODEL"
    exit 1
fi

if [ ! -f "$RUN_DIR/op.cfg" ]; then
    echo "[ERROR] op.cfg 配置文件不存在: $RUN_DIR/op.cfg"
    exit 1
fi

# ========= 3. 配置 Ascend 环境 =========
# 目标文件路径
TARGET_FILE="$TOOLKIT_ROOT/Ascend/ascend-toolkit/latest/x86_64-linux/bin/setenv.bash"
if [ ! -f "$TARGET_FILE" ]; then
    echo "[ERROR] 找不到目标文件: $TARGET_FILE"
    exit 1
fi
# 修改脚本
chmod u+w "$TARGET_FILE"
chmod u+x "$TARGET_FILE"
cat > "$TARGET_FILE" << 'EOF'
source $TOOLKIT_ROOT/Ascend/ascend-toolkit/5.20.t6.2.b060/x86_64-linux/compiler/bin/setenv.bash
source $TOOLKIT_ROOT/Ascend/ascend-toolkit/5.20.t6.2.b060/x86_64-linux/runtime/bin/setenv.bash
source $TOOLKIT_ROOT/Ascend/ascend-toolkit/5.20.t6.2.b060/x86_64-linux/opp/bin/setenv.bash
source $TOOLKIT_ROOT/Ascend/ascend-toolkit/5.20.t6.2.b060/x86_64-linux/toolkit/bin/setenv.bash
EOF

echo "[INFO] 修改完成: $TARGET_FILE"

echo "[INFO] 配置 Ascend 工具环境..."
export BATCH_MODE=1
set +e # 防止配置环境以外退出
source $TOOLKIT_ROOT/Ascend/ascend-toolkit/latest/x86_64-linux/bin/setenv.bash
set -e

# 验证 atc 工具是否可用
if ! command -v atc &>/dev/null; then
    echo "[ERROR] atc 工具未找到，请检查 Ascend Toolkit 是否正确安装"
    exit 1
fi

# ========= 4. 执行转换 =========
echo "[INFO] 开始转换: $ONNX_MODEL → $OM_MODEL.om"
cd "$RUN_DIR"

atc \
    --model="$ONNX_MODEL" \
    --framework=5 \
    --output="$OM_MODEL" \
    --soc_version="OPTG" \
    --output_type=FP32 \
    --insert_op_conf="./op.cfg"

echo "[INFO] 转换完成，输出文件: $RUN_DIR/${OM_MODEL}.om"
