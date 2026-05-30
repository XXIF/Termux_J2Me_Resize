#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 彩色常量定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PURPLE="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
RESET="\033[0m"

# 项目配置
PROJECT_NAME="[·Termux J2ME 游戏画面适配工具·]"
ASM_JAR="asm-4.0.jar"
ASM_URL="https://repo1.maven.org/maven2/org/ow2/asm/asm/4.0/asm-4.0.jar"
CLDC_JAR="cldcapi11.jar"
MIDP_LIB="midpapi20.jar"
REPO_URL="https://github.com/XXIF/Termux_J2Me_Resize"

# 双源下载配置
ORIGIN_BASE="https://raw.githubusercontent.com/XXIF/Termux_J2Me_Resize/main"
MIRROR_BASE="https://github.dpik.top/https://raw.githubusercontent.com/XXIF/Termux_J2Me_Resize/main"

# 需要从项目仓库下载的文件
PROJECT_FILES=(
    "run.sh"
    "${CLDC_JAR}"
    "${MIDP_LIB}"
)

# 双源容错下载函数
download_file() {
    local filename="$1"
    local origin_url="${ORIGIN_BASE}/${filename}"
    local mirror_url="${MIRROR_BASE}/${filename}"
    
    echo -e "      ${YELLOW}正在下载: ${filename}${RESET}"
    
    # 先尝试镜像地址
    if ! wget --timeout=15 -q "$mirror_url" -O "$filename"; then
        echo -e "      ${YELLOW}[提示] 镜像链接超时，切换官方地址${RESET}"
        if ! wget -q "$origin_url" -O "$filename"; then
            echo -e "      ${RED}[!] 下载失败${RESET}"
            return 1
        fi
    fi
    
    echo -e "      ${GREEN}[√] 下载成功${RESET}"
    return 0
}

# 艺术标题
echo -e "${CYAN}=============================================${RESET}"
echo -e "${BLUE}        ${PROJECT_NAME}${RESET}"
echo -e "${CYAN}=============================================${RESET}"

# 检测存储权限
echo -e "\n${YELLOW}[+] 检测设备存储权限${RESET}"
[ -d "$HOME/storage" ] || termux-setup-storage
echo -e "${GREEN}[√] 存储权限校验完成${RESET}"

# 安装基础依赖
pkg update -y 2>/dev/null
pkg upgrade -y 2>/dev/null

echo -e "\n${YELLOW}[+] 安装基础工具${RESET}"
pkg install wget unzip imagemagick zip -y 2>/dev/null
echo -e "${GREEN}[√] 基础工具就绪${RESET}"

# ========== OpenJDK 21 安装（Termux 原生 pkg） ==========
echo -e "\n${YELLOW}[+] 安装 OpenJDK 21${RESET}"
pkg install openjdk-21 -y 2>/dev/null
if ! java -version &>/dev/null; then
    echo -e "${RED}[!] Java 安装失败，请检查 Termux 版本${RESET}"
    exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -1)
echo -e "      ${GREEN}[√] ${JAVA_VER}${RESET}"

# ========== ASM 4.0 下载 ==========
echo -e "\n${YELLOW}[+] 下载 ASM 4.0 字节码库${RESET}"

if [ ! -f "${ASM_JAR}" ]; then
    # Maven Central 直连（46KB，无需镜像）
    if ! wget -q --timeout=15 "${ASM_URL}" -O "${ASM_JAR}"; then
        echo -e "${RED}[!] ASM 4.0 下载失败${RESET}"
        echo -e "      可手动下载: ${ASM_URL}"
        exit 1
    fi
else
    echo -e "      ${YELLOW}[提示] ${ASM_JAR} 已存在，跳过${RESET}"
fi
echo -e "${GREEN}[√] ASM 4.0 就绪${RESET}"

# ========== 下载项目文件（run.sh + J2ME 标准库）==========
echo -e "\n${YELLOW}[+] 检查并下载项目文件${RESET}"

MISSING_FILES=()
for file in "${PROJECT_FILES[@]}"; do
    if [ ! -f "${file}" ]; then
        MISSING_FILES+=("${file}")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo -e "      ${YELLOW}[提示] 发现 ${#MISSING_FILES[@]} 个缺失文件，开始下载...${RESET}"
    for file in "${MISSING_FILES[@]}"; do
        if ! download_file "${file}"; then
            echo -e "\n${RED}[!] 文件 ${file} 下载失败，请检查网络${RESET}"
            echo -e "      手动下载: ${ORIGIN_BASE}/${file}"
            exit 1
        fi
    done
else
    echo -e "${GREEN}[√] 所有项目文件已就绪${RESET}"
fi

# 验证 J2ME 标准库完整性
echo -e "\n${YELLOW}[+] 验证 J2ME 标准库${RESET}"
for lib in "${CLDC_JAR}" "${MIDP_LIB}"; do
    if [ -f "${lib}" ] && unzip -tq "${lib}" 2>/dev/null; then
        echo -e "      ${GREEN}[√] ${lib} 校验通过${RESET}"
    else
        echo -e "${RED}[!] ${lib} 缺失或损坏，请确保文件已推送到 GitHub 仓库${RESET}"
        exit 1
    fi
done

# 设置脚本可执行权限
echo -e "\n${YELLOW}[+] 设置脚本执行权限${RESET}"
chmod +x run.sh
echo -e "${GREEN}[√] 权限设置完成${RESET}"

# 结束提示
echo -e "\n${CYAN}=============================================${RESET}"
echo -e "${GREEN}环境全部部署完毕！${RESET}"
echo -e "${BLUE}运行环境:${RESET}"
java -version 2>&1 | head -1
echo -e "${BLUE}编译工具:${RESET} ASM 4.0, CLDC 1.1, MIDP 2.0"
echo -e "${WHITE}\n执行命令：${PURPLE}./run.sh${WHITE} 开始处理JAR文件${RESET}"
echo -e "${CYAN}=============================================${RESET}"
