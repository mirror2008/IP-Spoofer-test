#!/bin/bash

set -e

echo "==== Spoofer 自动检测脚本（DEBUG版） ===="

WORKDIR="$HOME/spoofer-auto"
SRC_DIR="$WORKDIR/spoofer-1.4.13"
RESULT_FILE="$WORKDIR/result.txt"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ================= 下载源码 =================
if [ ! -f "spoofer-1.4.13.tar.gz" ]; then
    echo "[+] 下载源码..."
    wget https://www.caida.org/projects/spoofer/downloads/spoofer-1.4.13.tar.gz
fi

# ================= 解压 =================
if [ ! -d "$SRC_DIR" ]; then
    echo "[+] 解压源码..."
    tar -zxvf spoofer-1.4.13.tar.gz
fi

cd "$SRC_DIR"

# ================= 编译检测 =================
if [ -f "./prober/spoofer-prober" ]; then
    echo "[+] 检测到已编译版本，跳过编译"
else
    echo "[+] 未检测到编译结果，开始编译..."

    apt update
    apt install -y build-essential libpcap-dev libssl-dev \
        qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
        protobuf-compiler libprotobuf-dev pkg-config

    ./configure
    make -j$(nproc)
fi

# ================= 检查 =================
PROBER_PATH="$SRC_DIR/prober/spoofer-prober"

if [ ! -x "$PROBER_PATH" ]; then
    echo "❌ spoofer-prober 不存在或不可执行"
    exit 1
fi

echo "[DEBUG] 使用路径: $PROBER_PATH"

# ================= 安装 expect =================
if ! command -v expect >/dev/null 2>&1; then
    echo "[+] 安装 expect..."
    apt update
    apt install -y expect
fi

echo "[+] 开始运行测试..."

# ================= 运行 =================
set +e

expect <<EOF > "$RESULT_FILE" 2>&1
log_user 1
set timeout 30

puts "[DEBUG] 启动 spoofer..."

spawn sudo $PROBER_PATH

puts "[DEBUG] 等待第一个提示..."

expect {
    "Allow anonymized" {
        puts "[DEBUG] 命中 anonymized 提示"
    }
    timeout {
        puts "[ERROR] 未匹配到 anonymized 提示"
        exit 1
    }
}

send "yes\r"
puts "[DEBUG] 已发送 yes"

puts "[DEBUG] 等待第二个提示..."

expect {
    "Allow unanonymized" {
        puts "[DEBUG] 命中 unanonymized 提示"
    }
    timeout {
        puts "[ERROR] 未匹配到 unanonymized 提示"
        exit 1
    }
}

send "no\r"
puts "[DEBUG] 已发送 no"

puts "[DEBUG] 等待测试完成..."

expect eof
puts "[DEBUG] spoofer 运行结束"
EOF

RET=$?
set -e

echo "[DEBUG] spoofer 返回码: $RET"
echo "[+] 测试完成"

# ================= DEBUG输出 =================
echo ""
echo "========== 原始输出（DEBUG） =========="
cat "$RESULT_FILE"
echo "======================================"

# ================= 成功检测 =================
if ! grep -q "IPv4 Result Summary" "$RESULT_FILE"; then
    echo "❌ 测试未成功执行（未进入核心测试阶段）"
    exit 1
fi

# ================= 提取报告 =================
REPORT_URL=$(grep -oE "https://spoofer.caida.org/report.php\\?sessionkey=[a-z0-9]+" "$RESULT_FILE" | head -n 1 || true)

# ================= 解析 =================
OUT_PRIV=$(grep -i "private addresses, outbound" "$RESULT_FILE" || true)
OUT_ROUT=$(grep -i "routable addresses, outbound" "$RESULT_FILE" || true)
IN_PRIV=$(grep -i "private addresses, inbound" "$RESULT_FILE" || true)
IN_INT=$(grep -i "internal addresses, inbound" "$RESULT_FILE" || true)
ADJ=$(grep -i "can spoof" "$RESULT_FILE" || true)

parse_status() {
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

# ================= 输出 =================
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

if [ -z "$OUT_ROUT" ]; then
    FINAL="❌ 测试失败（无有效结果）"
elif echo "$OUT_ROUT" | grep -qi "blocked" && echo "$ADJ" | grep -qi "can spoof"; then
    FINAL="⚠️ 半开放网络"
elif echo "$OUT_ROUT" | grep -qi "blocked"; then
    FINAL="✅ 安全网络"
else
    FINAL="🔴 高危网络"
fi

echo "👉 $FINAL"

# ================= 报告 =================
echo ""
echo "========== 完整测评报告 =========="

if [ -n "$REPORT_URL" ]; then
    echo "Test Complete."
    echo "Your test results:"
    echo "    $REPORT_URL"
else
    echo "⚠️ 未检测到报告链接"
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
