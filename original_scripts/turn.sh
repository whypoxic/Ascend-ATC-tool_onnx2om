#!/usr/bin/env bash
set -e  # 出错就退出

# ========= 1. 参数检查 =========
if [ $# -ne 2 ]; then
    echo "用法: $0 <onnx模型文件名> <输出om模型名>"
    echo "示例: $0 yolov5s.onnx yolov5s_om"
    exit 1
fi

ONNX_MODEL="$1"
OM_MODEL="$2"

# ========= 2. 路径定义 =========
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo $SCRIPT_DIR
TOOLKIT_ROOT="$SCRIPT_DIR"
echo $TOOLKIT_ROOT
RUN_DIR="$SCRIPT_DIR/run"

# ========= 3. 检查文件 =========
if [ ! -f "$RUN_DIR/$ONNX_MODEL" ]; then
    echo "[ERROR] ONNX 模型不存在: $RUN_DIR/$ONNX_MODEL"
    exit 1
fi

if [ ! -f "$RUN_DIR/op.cfg" ]; then
    echo "[ERROR] op.cfg 配置文件不存在: $RUN_DIR/op.cfg"
    exit 1
fi

# ========= 4. 配置 Ascend 环境 =========
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

# ========= 5. 执行转换 =========
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
