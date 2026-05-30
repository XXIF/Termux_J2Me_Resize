# Termux_J2Me_Resize
✨ Termux 平台 J2ME 游戏画面适配工具
自动配置Java环境 | 图片智能处理 | 双源容错下载 | 彩色炫酷终端界面

## 📌 项目简介
本项目基于 Android Termux 终端运行，依托**OpenJDK**运行环境与**ASM字节码插桩**技术，一键完成环境部署、JAR文件画面适配、背景图透明挖空处理。

无需复杂手动配置，交互式输入文件路径即可启动操作；支持两种处理模式：基础版仅画面偏移适配，背景图版支持自定义背景图并自动挖空中间游戏区域。

## 🎨 界面特色
- 彩色分级状态提示，运行进度直观清晰
- 艺术字开场动画，终端视觉体验出色
- 自动检测存储权限、系统运行依赖
- 异常报错高亮提醒，便捷排查故障问题
- 双模式选择，灵活适配不同需求场景

## 🧰 核心依赖
- 运行环境：OpenJDK 21
- 字节码插桩：ASM 9.7
- 图片处理：ImageMagick

## 📋 运行环境要求
1. 安卓设备，安装最新版本 Termux
2. 设备网络状态正常，可正常拉取资源
3. 待处理文件：J2ME 格式 JAR 游戏文件
4. 背景图（可选）：支持常见图片格式（PNG/JPG/JPEG）

## 🚀 快速使用教程
### 1. 拉取环境安装脚本
打开 Termux 终端，按需选择对应命令执行，自动完成工具与环境部署
```bash
# 国内加速源（优先推荐）
curl -s https://github.dpik.top/https://raw.githubusercontent.com/XXIF/Termux_J2Me_Resize/main/install.sh | bash
```

```bash
# GitHub官方源
curl -s https://raw.githubusercontent.com/XXIF/Termux_J2Me_Resize/main/install.sh | bash
```

```bash
# wget 国内加速通道
wget -qO- https://github.dpik.top/https://raw.githubusercontent.com/XXIF/Termux_J2Me_Resize/main/install.sh | bash
```

```bash
# wget 官方直连通道
wget -qO- https://raw.githubusercontent.com/XXIF/Termux_J2Me_Resize/main/install.sh | bash
```

### 2. 工具使用
环境部署完毕后，执行以下命令启动工具：
```bash
./run.sh
```

根据终端交互提示，选择处理模式并输入相关文件路径：

**模式选择**：
- `[1] 基础版` - 仅画面偏移适配，将游戏画面偏移至屏幕中央
- `[2] 背景图版` - 带背景图处理，支持自定义背景并自动挖空中间区域

**输入示例**：
```bash
请选择处理模式 [1/2]: 2
请输入原始 JAR 文件路径: /sdcard/game.jar
请输入背景图片路径: /sdcard/bg.jpg
```

处理完成的 JAR 文件，会自动在原目录生成带 `_Resize` 后缀的成品文件。

## 📐 画面布局说明
处理后的画面尺寸为 **240x320**，中间 **176x208** 区域为游戏画面显示区：
- 画面偏移：水平偏移 32px，垂直偏移 56px
- 背景挖空：中间 176x208 区域保持透明，游戏画面叠加显示

## 🖼️ 背景图处理规则
- 自动将图片缩放/裁剪至 240x320
- 中间 176x208 区域自动挖空透明
- 最终图片压缩至小于 15KB

## ⚠️ 相关须知
1. 首次启动工具会自动下载 OpenJDK、ASM、ImageMagick 相关依赖，等待加载完成即可
2. 务必为 Termux 授予设备存储权限，否则无法读取文件与导出处理结果
3. 本工具仅限个人学习研究使用，禁止用于侵权破解等违规行为

## 📁 项目结构
```
Termux_J2Me_Resize/
├── install.sh        # 环境安装脚本
├── run.sh            # 运行脚本（内含字节码插桩代码）
└── asm-9.7.jar       # ASM字节码库
```

## 🤝 支持与贡献
欢迎提交 Issue 和 Pull Request！

## 💰 赞助支持
如果本项目对您有帮助，欢迎打赏支持开发！

| 微信 | 支付宝 |
|:---:|:---:|
| ![微信收款码](wxpay.png) | ![支付宝收款码](alipay.jpg) |

## 🌹 鸣谢
- 特别感谢 群内大佬 [zcb] 为本项目贡献锚点资料
- 感谢 [ImageMagick](https://www.imagemagick.org/) 提供的图片处理功能

# 🎀 交流群
- QQ 群号：133052781

## 📄 许可证
MIT License