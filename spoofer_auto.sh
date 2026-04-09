#!/bin/bash

set -e

echo "==== Spoofer 自动检测脚本 ===="

WORKDIR="$HOME/spoofer-auto"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ================= 下载源码 =================
if [ ! -f "spoofer-1.4.13.tar.gz" ]; then
    echo "[+] 下载源码..."
    wget https://www.caida.org/projects/spoofer/downloads/spoofer-1.4.13.tar.gz
fi

# ================= 解压 =================
if [ ! -d "spoofer-1.4.13" ]; then
    echo "[+] 解压源码..."
    tar -zxvf spoofer-1.4.13.tar.gz
fi

cd spoofer-1.4.13

# ================= 安装依赖 =================
echo "[+] 安装依赖..."
apt update
apt install -y build-essential libpcap-dev libssl-dev \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    protobuf-compiler libprotobuf-dev pkg-config

# ================= 编译 =================
echo "[+] 开始编译..."
./configure
make -j$(nproc)

# ================= 运行 =================
echo "[+] 开始运行测试..."

RESULT_FILE="$WORKDIR/result.txt"

(
echo "yes"
echo "no"
) | sudo ./prober/spoofer-prober > "$RESULT_FILE" 2>&1

echo "[+] 测试完成，解析结果..."

# ================= 提取报告链接 =================

REPORT_URL=$(grep -oE "https://spoofer.caida.org/report.php\\?sessionkey=[a-z0-9]+" "$RESULT_FILE" | head -n 1 || true)

# ================= 解析 =================

OUT_PRIV=$(grep -i "private addresses, outbound" "$RESULT_FILE" || true)
OUT_ROUT=$(grep -i "routable addresses, outbound" "$RESULT_FILE" || true)
IN_PRIV=$(grep -i "private addresses, inbound" "$RESULT_FILE" || true)
IN_INT=$(grep -i "internal addresses, inbound" "$RESULT_FILE" || true)
ADJ=$(grep -i "can spoof" "$RESULT_FILE" || true)

function parse_status() {
    if echo "$1" | grep -qi "blocked"; then
        echo "❌ 不可伪造"
    elif echo "$1" | grep -qi "received"; then
        echo "⚠️ 可伪造"
    else
        echo "❓ 未知"
    fi
}

OUT_PRIV_RES=$(parse_status "$OUT_PRIV")
OUT_ROUT_RES=$(parse_status "$OUT_ROUT")
IN_PRIV_RES=$(parse_status "$IN_PRIV")
IN_INT_RES=$(parse_status "$IN_INT")

if echo "$ADJ" | grep -qi "can spoof"; then
    ADJ_RES="⚠️ 同网段可伪造"
else
    ADJ_RES="❌ 同网段不可伪造"
fi

# ================= 输出表格 =================

echo ""
echo "========== 检测结果 =========="

printf "%-30s %-20s\n" "检测项" "结果"
printf "%-30s %-20s\n" "------------------------------" "--------------------"

printf "%-30s %-20s\n" "出站私网伪造" "$OUT_PRIV_RES"
printf "%-30s %-20s\n" "出站公网伪造" "$OUT_ROUT_RES"
printf "%-30s %-20s\n" "入站私网伪造" "$IN_PRIV_RES"
printf "%-30s %-20s\n" "入站内部伪造" "$IN_INT_RES"
printf "%-30s %-20s\n" "同网段伪造能力" "$ADJ_RES"

echo ""
echo "========== 综合判断 =========="

if echo "$OUT_ROUT" | grep -qi "blocked" && echo "$ADJ" | grep -qi "can spoof"; then
    FINAL="⚠️ 半开放网络（仅同网段可伪造）"
elif echo "$OUT_ROUT" | grep -qi "blocked"; then
    FINAL="✅ 安全网络（已启用过滤）"
else
    FINAL="🔴 高危网络（可伪造公网IP）"
fi

echo "👉 $FINAL"

# ================= 输出报告链接 =================

echo ""
echo "========== 完整测评报告 =========="

if [ -n "$REPORT_URL" ]; then
    echo "Test Complete."
    echo "Your test results:"
    echo "    $REPORT_URL"
else
    echo "⚠️ 未检测到报告链接（可能网络问题或解析失败）"
fi

echo ""
echo "[+] 原始结果保存在: $RESULT_FILE"

# ================= 广告 =================

echo ""
echo "=================================================="
echo "☁️ 七九网络 · 079IDC 高性价比BGP云服务器"
echo "✔ 正规企业 · 持证经营"
echo "✔ BGP 多线接入 · 南北互通 · 国内外访问均衡"
echo "✔ KVM 架构 · 性能真实不虚标"
echo "✔ 适合建站 / 代理 / 业务部署 / 长期运行"
echo "✔ 线路干净 · 价格克制 · 运维不折腾"
echo ""
echo "官网：https://079idc.net"
echo "=================================================="
