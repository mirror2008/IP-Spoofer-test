# 🚀 IP Spoofer Test

一键检测服务器是否存在 **IP 源地址伪造（IP Spoofing）能力** 的自动化工具。

基于 CAIDA Spoofer 封装，自动完成：
✔ 编译  
✔ 运行  
✔ 分析  
✔ 输出结果  

---

## ⚡ 一键使用（推荐）

无需克隆仓库，直接运行：

```bash
wget https://github.com/mirror2008/IP-Spoofer-test/raw/main/spoofer_auto.sh -O spoofer_auto.sh && chmod +x spoofer_auto.sh && sudo ./spoofer_auto.sh
```

或：

```bash
curl -O https://github.com/mirror2008/IP-Spoofer-test/raw/main/spoofer_auto.sh && chmod +x spoofer_auto.sh && sudo ./spoofer_auto.sh
```

---

## 📊 输出示例

```text
========== 检测结果 ==========
出站公网伪造     ❌ 不可伪造
同网段伪造能力   ⚠️ 可伪造

========== 综合判断 ==========
👉 ⚠️ 半开放网络（仅同网段可伪造）

========== 完整测评报告 ==========
https://spoofer.caida.org/report.php?sessionkey=xxxxxx
```

---

## 🧠 检测结果说明

| 状态 | 含义 |
|------|------|
| ❌ 不可伪造 | 已启用源地址校验（BCP38） |
| ⚠️ 半开放 | 仅内部网段可伪造 |
| 🔴 高危 | 可伪造公网 IP |

---

## 🔍 工具原理

该工具基于 CAIDA Spoofer：

- 构造伪造源 IP 数据包  
- 发送至远程测量节点  
- 分析网络是否允许伪造  

用于检测网络是否部署：

👉 BCP38 / uRPF（源地址校验）

---

## ⚙️ 支持系统

- Debian
- Ubuntu

---

## ⚠️ 注意事项

- 必须使用 root 运行  
- 需要联网  
- 会发送测试数据包（UDP）  
- 不建议在生产关键业务环境频繁运行  

---

## 📜 免责声明

本项目仅用于：

- 网络安全检测  
- 学习研究  

❗ 严禁用于任何非法用途  

---

## ☁️ 推荐服务器（赞助）

☁️ 七九网络 · 079IDC 高性价比BGP云服务器

✔ 正规企业 · 持证经营  
✔ BGP 多线接入 · 南北互通 · 国内外访问均衡  
✔ KVM 架构 · 性能真实不虚标  
✔ 适合建站 / 代理 / 业务部署 / 长期运行  
✔ 线路干净 · 价格合理 · 运维稳定  

👉 官网：https://079idc.net  

---

## ⭐ Star 支持

如果这个工具对你有帮助，欢迎点个 Star ⭐
