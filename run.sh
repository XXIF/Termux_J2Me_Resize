#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# 彩色常量定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
WHITE="\033[37m"
RESET="\033[0m"

# 固定配置（J2ME 标准编译环境）
ASM_JAR="asm-4.0.jar"
CLDC_JAR="cldcapi11.jar"
MIDP_LIB="midpapi20.jar"
TMP_DIR="tmp_jar_work"
TMP_PACK="temp_build.jar"
BG_IMG_NAME="bg.png"

# ★ 内嵌预验证 ResizeBgHelper.class (base64)
#   JDK 1.6.0_45 编译, target 1.4, Halo preverify.exe 处理 | v48.0 | CLDC StackMap
#   免 JDK 编译、免 ASM StripFrames、免 ClassVersionPatcher
RESIZE_BG_HELPER_B64="yv66vgAAADAAJQoACQASCQAIABMKABQAFQgAFgoAFwAYBwAZCgAGABoHABsHABwBAAdiZ0ltYWdlAQAgTGphdmF4L21pY3JvZWRpdGlvbi9sY2R1aS9JbWFnZTsBAAY8aW5pdD4BAAMoKVYBAARDb2RlAQAGZHJhd0JnAQAmKExqYXZheC9taWNyb2VkaXRpb24vbGNkdWkvR3JhcGhpY3M7KVYBAAg8Y2xpbml0PgwADAANDAALAAsHAB0MAB4AHwEABy9iZy5wbmcHACAMACEAIgEAE2phdmEvbGFuZy9FeGNlcHRpb24MACMADQEADlJlc2l6ZUJnSGVscGVyAQAQamF2YS9sYW5nL09iamVjdAEAIWphdmF4L21pY3JvZWRpdGlvbi9sY2R1aS9HcmFwaGljcwEACWRyYXdJbWFnZQEAJihMamF2YXgvbWljcm9lZGl0aW9uL2xjZHVpL0ltYWdlO0lJSSlWAQAeamF2YXgvbWljcm9lZGl0aW9uL2xjZHVpL0ltYWdlAQALY3JlYXRlSW1hZ2UBADQoTGphdmEvbGFuZy9TdHJpbmc7KUxqYXZheC9taWNyb2VkaXRpb24vbGNkdWkvSW1hZ2U7AQAPcHJpbnRTdGFja1RyYWNlAQAIU3RhY2tNYXAAIQAIAAkAAAABAAkACgALAAAAAwABAAwADQABAA4AAAARAAEAAQAAAAUqtwABsQAAAAAACQAPABAAAQAOAAAAGAAFAAEAAAAMKrIAAgMDEBS2AAOxAAAAAAAIABEADQABAA4AAAA8AAEAAQAAABESBLgABbMAAqcACEsqtgAHsQABAAAACAALAAYAAQAkAAAAEQACAAsAAAABBwAGABAAAAAAAAA="

# 分辨率配置
RESOLUTIONS=(
    "176x208"
    "176x220"
    "208x208"
    "128x160"
)

# 目标屏幕尺寸
SCREEN_W=240
SCREEN_H=320

# 分辨率对应的游戏画面尺寸
GAME_W=176
GAME_H=208

# 默认背景色（白色）
BG_COLOR_HEX="FFFFFF"

# 预设背景色
BG_COLOR_PRESETS=(
    "000000:黑色"
    "FFFFFF:白色"
    "808080:灰色"
    "000080:深蓝"
    "800000:深红"
    "008000:深绿"
)

# 计算偏移量（屏幕中心对齐）
calc_offsets() {
    OFF_X=$(( (SCREEN_W - GAME_W) / 2 ))
    OFF_Y=$(( (SCREEN_H - GAME_H) / 2 ))
}

# 选择背景色
select_bg_color() {
    echo -e "\n${CYAN}=============================================${RESET}"
    echo -e "${BLUE}          选择背景颜色${RESET}"
    echo -e "${CYAN}=============================================${RESET}"
    
    local i=1
    for preset in "${BG_COLOR_PRESETS[@]}"; do
        local hex="${preset%%:*}"
        local name="${preset##*:}"
        echo -e "${YELLOW}[${i}] ${name} (#${hex})${RESET}"
        ((i++))
    done
    echo -e "${YELLOW}[${i}] 自定义 (输入16进制颜色)${RESET}"
    
    local max_opt=$i
    read -p "$(echo -e "${WHITE}请选择背景颜色 [1-${max_opt}]: ${RESET}")" COLOR_CHOICE
    
    if [ "${COLOR_CHOICE}" -ge 1 ] 2>/dev/null && [ "${COLOR_CHOICE}" -lt "${max_opt}" ] 2>/dev/null; then
        local idx=$((COLOR_CHOICE - 1))
        local preset="${BG_COLOR_PRESETS[$idx]}"
        BG_COLOR_HEX="${preset%%:*}"
        local name="${preset##*:}"
        echo -e "${GREEN}[√] 已选择背景色: ${name} (#${BG_COLOR_HEX})${RESET}"
    elif [ "${COLOR_CHOICE}" = "${max_opt}" ]; then
        read -p "$(echo -e "${WHITE}请输入16进制颜色值 (如 FF0000): ${RESET}")" CUSTOM_COLOR
        # 去掉可能的 # 前缀，转为大写
        CUSTOM_COLOR=$(echo "${CUSTOM_COLOR}" | sed 's/^#//' | tr '[:lower:]' '[:upper:]')
        # 校验是否为有效6位16进制颜色
        if echo "${CUSTOM_COLOR}" | grep -qE '^[0-9A-F]{6}$'; then
            BG_COLOR_HEX="${CUSTOM_COLOR}"
            echo -e "${GREEN}[√] 已选择自定义背景色: #${BG_COLOR_HEX}${RESET}"
        else
            echo -e "${RED}[错误] 无效的颜色值，使用默认白色${RESET}"
            BG_COLOR_HEX="FFFFFF"
        fi
    else
        echo -e "${RED}[错误] 无效选择，使用默认白色${RESET}"
        BG_COLOR_HEX="FFFFFF"
    fi
}

# 选择分辨率
select_resolution() {
    echo -e "\n${CYAN}=============================================${RESET}"
    echo -e "${BLUE}          选择游戏分辨率${RESET}"
    echo -e "${CYAN}=============================================${RESET}"
    
    local i=1
    for res in "${RESOLUTIONS[@]}"; do
        echo -e "${YELLOW}[${i}] ${res}${RESET}"
        ((i++))
    done
    
    read -p "$(echo -e "${WHITE}请选择分辨率 [1-${#RESOLUTIONS[@]}]: ${RESET}")" RES_CHOICE
    
    case "${RES_CHOICE}" in
        1)
            GAME_W=176
            GAME_H=208
            ;;
        2)
            GAME_W=176
            GAME_H=220
            ;;
        3)
            GAME_W=208
            GAME_H=208
            ;;
        4)
            GAME_W=128
            GAME_H=160
            ;;
        *)
            echo -e "${RED}[错误] 无效选择，使用默认分辨率 176x208${RESET}"
            GAME_W=176
            GAME_H=208
            ;;
    esac
    
    # 计算偏移量
    calc_offsets
    
    echo -e "${GREEN}[√] 已选择分辨率: ${GAME_W}x${GAME_H}, 偏移: (${OFF_X}, ${OFF_Y})${RESET}"
}

# 基础版插桩代码（paint → paint_ext + 新paint = 游戏下层 + 遮罩上层）
# 用 setClip 裁剪游戏绘制区域 + translate 偏移，确保游戏只在中央区域绘制
GENERATE_HOOK_BASIC() {
cat > ResizeHook.java << HOOKEOF
import org.objectweb.asm.*;
import java.io.*;

public class ResizeHook {
    private static final int OFF_X = ${OFF_X};
    private static final int OFF_Y = ${OFF_Y};
    private static final int SCREEN_W = ${SCREEN_W};
    private static final int SCREEN_H = ${SCREEN_H};
    private static final int GAME_W = ${GAME_W};
    private static final int GAME_H = ${GAME_H};
    private static final int BG_COLOR = 0x${BG_COLOR_HEX};

    public static void main(String[] args) throws IOException {
        String classPath = args[0];
        File file = new File(classPath);
        byte[] bytes = java.nio.file.Files.readAllBytes(file.toPath());

        ClassReader cr = new ClassReader(bytes);
        ClassWriter cw = new ClassWriter(cr, ClassWriter.COMPUTE_MAXS);
        ClassVisitor cv = new ClassVisitor(Opcodes.ASM4, cw) {
            boolean hooked = false;
            int paintAccess = Opcodes.ACC_PUBLIC;

            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
                if ("paint".equals(name) && "(Ljavax/microedition/lcdui/Graphics;)V".equals(desc)) {
                    if (!hooked) {
                        hooked = true;
                        paintAccess = access;
                        MethodVisitor mvExt = super.visitMethod(access, "paint_ext", desc, signature, exceptions);
                        return mvExt;
                    }
                }
                return super.visitMethod(access, name, desc, signature, exceptions);
            }

            @Override
            public void visitEnd() {
                if (!hooked) {
                    super.visitEnd();
                    return;
                }

                MethodVisitor mvPaint = cw.visitMethod(
                    paintAccess, "paint",
                    "(Ljavax/microedition/lcdui/Graphics;)V", null, null);
                mvPaint.visitCode();

                // 保存原始 clip: slot 2=x, 3=y, 4=w, 5=h
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipX", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 2);

                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipY", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 3);

                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipWidth", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 4);

                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipHeight", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 5);

                // g.translate(OFF_X, OFF_Y)
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_X);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_Y);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "translate", "(II)V");

                // g.setClip(0, 0, GAME_W, GAME_H)  限制游戏只能画在游戏区域内
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, GAME_W);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, GAME_H);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "setClip", "(IIII)V");

                // paint_ext(g)  游戏在下层绘制
                mvPaint.visitVarInsn(Opcodes.ALOAD, 0);
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    cr.getClassName(), "paint_ext",
                    "(Ljavax/microedition/lcdui/Graphics;)V");

                // g.translate(-OFF_X, -OFF_Y)  恢复坐标
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, -OFF_X);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, -OFF_Y);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "translate", "(II)V");

                // 恢复原始 clip
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 2);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 3);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 4);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 5);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "setClip", "(IIII)V");

                // ===== 遮罩边框（画在游戏上层，四个 fillRect 围住中央游戏区域）=====

                // g.setColor(BG_COLOR)
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitLdcInsn(BG_COLOR);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "setColor", "(I)V");

                // 上方: 0,0, SCREEN_W, OFF_Y
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, SCREEN_W);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_Y);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "fillRect", "(IIII)V");

                // 下方: 0, OFF_Y+GAME_H, SCREEN_W, SCREEN_H-OFF_Y-GAME_H
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_Y + GAME_H);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, SCREEN_W);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, SCREEN_H - OFF_Y - GAME_H);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "fillRect", "(IIII)V");

                // 左边: 0, OFF_Y, OFF_X, GAME_H
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_Y);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_X);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, GAME_H);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "fillRect", "(IIII)V");

                // 右边: OFF_X+GAME_W, OFF_Y, SCREEN_W-OFF_X-GAME_W, GAME_H
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_X + GAME_W);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_Y);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, SCREEN_W - OFF_X - GAME_W);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, GAME_H);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "fillRect", "(IIII)V");

                mvPaint.visitInsn(Opcodes.RETURN);
                mvPaint.visitMaxs(5, 6);
                mvPaint.visitEnd();

                super.visitEnd();
            }
        };
        // SKIP_FRAMES: 不保留原始 CLDC StackMap（避免旧 ASM 解析崩溃）
        // COMPUTE_MAXS: 不生成 StackMapTable（类无帧=VM 走完整验证）
        cr.accept(cv, ClassReader.SKIP_FRAMES);

        try (FileOutputStream fos = new FileOutputStream(file)) {
            fos.write(cw.toByteArray());
        }
    }
}
HOOKEOF
}

# 背景图版插桩代码（paint → paint_ext + 新paint = 游戏下层 + 背景图遮罩上层）
# 用 setClip 裁剪游戏绘制区域 + translate 偏移
GENERATE_HOOK_BG() {
cat > ResizeHook.java << HOOKEOF
import org.objectweb.asm.*;
import java.io.*;

public class ResizeHook {
    private static final int OFF_X = ${OFF_X};
    private static final int OFF_Y = ${OFF_Y};
    private static final int SCREEN_W = ${SCREEN_W};
    private static final int SCREEN_H = ${SCREEN_H};
    private static final int GAME_W = ${GAME_W};
    private static final int GAME_H = ${GAME_H};

    public static void main(String[] args) throws IOException {
        String classPath = args[0];
        File file = new File(classPath);
        byte[] bytes = java.nio.file.Files.readAllBytes(file.toPath());

        ClassReader cr = new ClassReader(bytes);
        ClassWriter cw = new ClassWriter(cr, ClassWriter.COMPUTE_MAXS);
        ClassVisitor cv = new ClassVisitor(Opcodes.ASM4, cw) {
            boolean hooked = false;
            int paintAccess = Opcodes.ACC_PUBLIC;

            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String signature, String[] exceptions) {
                if ("paint".equals(name) && "(Ljavax/microedition/lcdui/Graphics;)V".equals(desc)) {
                    if (!hooked) {
                        hooked = true;
                        paintAccess = access;
                        MethodVisitor mvExt = super.visitMethod(access, "paint_ext", desc, signature, exceptions);
                        return mvExt;
                    }
                }
                return super.visitMethod(access, name, desc, signature, exceptions);
            }

            @Override
            public void visitEnd() {
                if (!hooked) {
                    super.visitEnd();
                    return;
                }

                MethodVisitor mvPaint = cw.visitMethod(
                    paintAccess, "paint",
                    "(Ljavax/microedition/lcdui/Graphics;)V", null, null);
                mvPaint.visitCode();

                // 保存原始 clip: slot 2=x, 3=y, 4=w, 5=h
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipX", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 2);

                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipY", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 3);

                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipWidth", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 4);

                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "getClipHeight", "()I");
                mvPaint.visitVarInsn(Opcodes.ISTORE, 5);

                // g.translate(OFF_X, OFF_Y)
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_X);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, OFF_Y);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "translate", "(II)V");

                // g.setClip(0, 0, GAME_W, GAME_H)  限制游戏只能画在游戏区域内
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitInsn(Opcodes.ICONST_0);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, GAME_W);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, GAME_H);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "setClip", "(IIII)V");

                // paint_ext(g)  游戏在下层
                mvPaint.visitVarInsn(Opcodes.ALOAD, 0);
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    cr.getClassName(), "paint_ext",
                    "(Ljavax/microedition/lcdui/Graphics;)V");

                // g.translate(-OFF_X, -OFF_Y)
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, -OFF_X);
                mvPaint.visitIntInsn(Opcodes.SIPUSH, -OFF_Y);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "translate", "(II)V");

                // 恢复原始 clip
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 2);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 3);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 4);
                mvPaint.visitVarInsn(Opcodes.ILOAD, 5);
                mvPaint.visitMethodInsn(Opcodes.INVOKEVIRTUAL,
                    "javax/microedition/lcdui/Graphics",
                    "setClip", "(IIII)V");

                // ===== 背景图遮罩（画在游戏上层，bg.png 中间透明四周有图案）=====
                // 使用 ResizeBgHelper 静态类，Image 只加载一次，避免每帧 I/O 解码

                // ResizeBgHelper.drawBg(g)
                mvPaint.visitVarInsn(Opcodes.ALOAD, 1);
                mvPaint.visitMethodInsn(Opcodes.INVOKESTATIC,
                    "ResizeBgHelper", "drawBg",
                    "(Ljavax/microedition/lcdui/Graphics;)V");

                mvPaint.visitInsn(Opcodes.RETURN);
                mvPaint.visitMaxs(1, 6);
                mvPaint.visitEnd();

                super.visitEnd();
            }
        };
        // SKIP_FRAMES: 不保留原始 CLDC StackMap（避免旧 ASM 解析崩溃）
        // COMPUTE_MAXS: 不生成 StackMapTable（类无帧=VM 走完整验证）
        cr.accept(cv, ClassReader.SKIP_FRAMES);

        try (FileOutputStream fos = new FileOutputStream(file)) {
            fos.write(cw.toByteArray());
        }
    }
}
HOOKEOF
}

# 清理函数（ResizeHook + 内嵌 class 不再需要 ResizeBgHelper/Patcher/StripFrames）
CLEANUP_HOOK() {
    rm -f ResizeHook*.java ResizeHook*.class 2>/dev/null || true
}

# 依赖校验（cldcapi11.jar + midpapi20.jar 编译时必需）
if [ ! -f "${ASM_JAR}" ]; then
    echo -e "${RED}[错误] 缺少 ${ASM_JAR}，请先执行 ./install.sh${RESET}"
    exit 1
fi
if [ ! -f "${CLDC_JAR}" ]; then
    echo -e "${RED}[错误] 缺少 ${CLDC_JAR}（CLDC 1.1 标准库），请先执行 ./install.sh${RESET}"
    exit 1
fi
if [ ! -f "${MIDP_LIB}" ]; then
    echo -e "${RED}[错误] 缺少 ${MIDP_LIB}（MIDP 2.0 标准库），请先执行 ./install.sh${RESET}"
    exit 1
fi

# 构建 classpath（OpenJDK 21 + ASM 4.0 + CLDC 1.1 + MIDP 2.0）
CP_ALL="${ASM_JAR}:${CLDC_JAR}:${MIDP_LIB}"
echo -e "${GREEN}[√] J2ME 编译环境: OpenJDK 21 + ASM 4.0 + CLDC 1.1 + MIDP 2.0 (ResizeBgHelper 内嵌免编译)${RESET}"

# 启动时清理残留文件
CLEANUP_HOOK

# 显示标题和分辨率选择
echo -e "${CYAN}=============================================${RESET}"
echo -e "${BLUE}        [···]J2ME 游戏画面适配工具[···]${RESET}"
echo -e "${CYAN}=============================================${RESET}"

# 先选择分辨率
select_resolution

# 显示模式选择
echo -e "\n${YELLOW}[1] 基础版 - 画面偏移 + 纯色背景${RESET}"
echo -e "${YELLOW}[2] 背景图版 - 画面偏移 + 背景图片${RESET}"
read -p "$(echo -e "${WHITE}请选择处理模式 [1/2]: ${RESET}")" MODE

# 模式选择处理
case "${MODE}" in
    1)
        HOOK_MODE="basic"
        echo -e "${GREEN}[√] 已选择：基础版${RESET}"
        # 基础版选择背景色
        select_bg_color
        ;;
    2)
        HOOK_MODE="bg"
        echo -e "${GREEN}[√] 已选择：背景图版${RESET}"
        # 背景图模式：内嵌 ResizeBgHelper.class 无需 J2ME 标准库编译
        # 依赖校验已在前面完成，此处不再重复
        ;;
    *)
        echo -e "${RED}[错误] 无效选择${RESET}"
        exit 1
        ;;
esac

# 输入JAR路径
read -p "$(echo -e "${YELLOW}\n请输入原始 JAR 文件路径: ${RESET}")" SRC_JAR

# 校验源文件：存在性 + 扩展名 + 压缩包合法性
if [ ! -f "${SRC_JAR}" ]; then
    echo -e "${RED}[错误] 文件不存在: ${SRC_JAR}${RESET}"
    exit 1
fi

# 检查扩展名是否为 .jar（不区分大小写）
SRC_EXT=$(echo "${SRC_JAR}" | grep -oi '\.jar$' || true)
if [ -z "${SRC_EXT}" ]; then
    echo -e "${RED}[错误] 不是 JAR 文件（扩展名应为 .jar）: ${SRC_JAR}${RESET}"
    exit 1
fi

# 检查是否为有效的 ZIP/JAR 格式
if ! unzip -tq "${SRC_JAR}" 2>/dev/null; then
    echo -e "${RED}[错误] 文件不是有效的 JAR（ZIP 格式）: ${SRC_JAR}${RESET}"
    exit 1
fi

echo -e "${GREEN}[√] JAR 文件校验通过${RESET}"

# 如果是背景图版，输入背景图片路径
if [ "${HOOK_MODE}" = "bg" ]; then
    read -p "$(echo -e "${YELLOW}请输入背景图片路径: ${RESET}")" BG_IMG_SRC
    if [ ! -f "${BG_IMG_SRC}" ]; then
        echo -e "${RED}[错误] 背景图片不存在: ${BG_IMG_SRC}${RESET}"
        exit 1
    fi
    # 检查是否为常见图片格式
    IMG_EXT=$(echo "${BG_IMG_SRC}" | grep -oiE '\.(png|jpg|jpeg|bmp|gif)$' || true)
    if [ -z "${IMG_EXT}" ]; then
        echo -e "${RED}[错误] 背景图片格式不支持（需 .png/.jpg/.bmp/.gif）: ${BG_IMG_SRC}${RESET}"
        exit 1
    fi
    # 防止把 JAR 文件误当作背景图
    if [ "${BG_IMG_SRC}" = "${SRC_JAR}" ]; then
        echo -e "${RED}[错误] 背景图片不能与 JAR 文件相同${RESET}"
        exit 1
    fi
fi

# 解析输出路径
SRC_DIR=$(dirname "${SRC_JAR}")
SRC_NAME=$(basename "${SRC_JAR}" .jar)
FINAL_JAR="${SRC_DIR}/${SRC_NAME}_Resize.jar"

# 显示配置信息
echo -e "\n${CYAN}[源JAR]    ${SRC_JAR}${RESET}"
if [ "${HOOK_MODE}" = "bg" ]; then
    echo -e "${CYAN}[背景图]   ${BG_IMG_SRC}${RESET}"
fi
echo -e "${CYAN}[输出]     ${FINAL_JAR}${RESET}"

# 清理旧临时文件
rm -rf "${TMP_DIR}" "${TMP_PACK}"
CLEANUP_HOOK
mkdir -p "${TMP_DIR}"

# 步骤1: 解压JAR
echo -e "\n${YELLOW}[1/5] 解压文件到临时目录${RESET}"
unzip -q "${SRC_JAR}" -d "${TMP_DIR}"

# 修复MANIFEST.MF的BOM问题
if [ -f "${TMP_DIR}/META-INF/MANIFEST.MF" ]; then
    BOM_CLEAN="${TMP_DIR}/META-INF/MANIFEST.MF.bom"
    mv "${TMP_DIR}/META-INF/MANIFEST.MF" "${BOM_CLEAN}"
    sed '1s/^\xEF\xBB\xBF//' "${BOM_CLEAN}" > "${TMP_DIR}/META-INF/MANIFEST.MF"
    rm -f "${BOM_CLEAN}"
    echo -e "      ${GREEN}[√] MANIFEST.MF BOM已清除${RESET}"
fi

# 计算总步骤数（内嵌 class 免编译/免 StripFrames/免 Patcher/免 preverify）
if [ "${HOOK_MODE}" = "bg" ]; then
    TOTAL_STEPS=5   # 解压+背景图+生成+编译+插桩+打包
else
    TOTAL_STEPS=5   # 解压+生成+编译+插桩+打包
fi

# 步骤2: 背景图处理（仅背景图版）
    if [ "${HOOK_MODE}" = "bg" ]; then
        echo -e "${YELLOW}[2/${TOTAL_STEPS}] 处理背景图片 (${SCREEN_W}x${SCREEN_H}, 中间挖空)${RESET}"
        TMP_BG="${TMP_DIR}/${BG_IMG_NAME}"
        GAME_X=${OFF_X}
        GAME_Y=${OFF_Y}
        TMP_BG_RAW="${TMP_DIR}/bg_raw.png"
        TMP_MASK="${TMP_DIR}/mask.png"
        TMP_BG_TMP="${TMP_DIR}/bg_tmp.png"

        # 步骤1: 处理原图到目标屏幕尺寸
        magick "${BG_IMG_SRC}" \
               -resize ${SCREEN_W}x${SCREEN_H}^ \
               -gravity center \
               -extent ${SCREEN_W}x${SCREEN_H} \
               PNG32:"${TMP_BG_RAW}"
        
        # 步骤2: 创建透明画布
        magick -size ${SCREEN_W}x${SCREEN_H} xc:transparent PNG32:"${TMP_BG_TMP}"
        
        # 步骤3: 裁剪并保存每一块到临时文件
        TMP_TOP="${TMP_DIR}/bg_top.png"
        TMP_BOTTOM="${TMP_DIR}/bg_bottom.png"
        TMP_LEFT="${TMP_DIR}/bg_left.png"
        TMP_RIGHT="${TMP_DIR}/bg_right.png"
        
        # 上边: SCREEN_W x GAME_Y
        magick "${TMP_BG_RAW}" -crop ${SCREEN_W}x${GAME_Y}+0+0 +repage PNG32:"${TMP_TOP}"
        # 下边: SCREEN_W x (SCREEN_H - GAME_Y - GAME_H)
        BOTTOM_H=$((SCREEN_H - GAME_Y - GAME_H))
        magick "${TMP_BG_RAW}" -crop ${SCREEN_W}x${BOTTOM_H}+0+$((GAME_Y+GAME_H)) +repage PNG32:"${TMP_BOTTOM}"
        # 左边: GAME_X x GAME_H
        magick "${TMP_BG_RAW}" -crop ${GAME_X}x${GAME_H}+0+${GAME_Y} +repage PNG32:"${TMP_LEFT}"
        # 右边: (SCREEN_W - GAME_X - GAME_W) x GAME_H
        RIGHT_W=$((SCREEN_W - GAME_X - GAME_W))
        magick "${TMP_BG_RAW}" -crop ${RIGHT_W}x${GAME_H}+$((GAME_X+GAME_W))+${GAME_Y} +repage PNG32:"${TMP_RIGHT}"
        
        # 步骤4: 依次粘贴各块到透明画布（使用绝对坐标）
        # 上边: SCREEN_W x GAME_Y @ (0,0)
        magick "${TMP_BG_TMP}" "${TMP_TOP}" -geometry +0+0 -compose over -composite PNG32:"${TMP_BG_TMP}"
        # 下边: SCREEN_W x BOTTOM_H @ (0, GAME_Y+GAME_H)
        magick "${TMP_BG_TMP}" "${TMP_BOTTOM}" -geometry +0+$((GAME_Y+GAME_H)) -compose over -composite PNG32:"${TMP_BG_TMP}"
        # 左边: GAME_X x GAME_H @ (0, GAME_Y)
        magick "${TMP_BG_TMP}" "${TMP_LEFT}" -geometry +0+${GAME_Y} -compose over -composite PNG32:"${TMP_BG_TMP}"
        # 右边: RIGHT_W x GAME_H @ (GAME_X+GAME_W, GAME_Y)
        magick "${TMP_BG_TMP}" "${TMP_RIGHT}" -geometry +$((GAME_X+GAME_W))+${GAME_Y} -compose over -composite PNG32:"${TMP_BG_TMP}"
        
        # 清理临时文件
        rm -f "${TMP_BG_RAW}" "${TMP_TOP}" "${TMP_BOTTOM}" "${TMP_LEFT}" "${TMP_RIGHT}"

        # 显示图片信息和压缩（保持透明度）
        FILE_SIZE=$(stat -c%s "${TMP_BG_TMP}" 2>/dev/null || stat -f%z "${TMP_BG_TMP}" 2>/dev/null)
        echo -e "      ${GREEN}[√] 背景尺寸: ${SCREEN_W}x${SCREEN_H}, 挖空: ${GAME_W}x${GAME_H}@(${GAME_X},${GAME_Y})${RESET}"
    
    if [ "${FILE_SIZE}" -gt 15360 ]; then
        echo -e "      ${YELLOW}原始大小: $((FILE_SIZE / 1024))k, 开始压缩...${RESET}"
        
        # 策略1: PNG32最大压缩
        magick "${TMP_BG_TMP}" -define png:compression-level=9 PNG32:"${TMP_BG}"
        FILE_SIZE=$(stat -c%s "${TMP_BG}" 2>/dev/null || stat -f%z "${TMP_BG}" 2>/dev/null)
        
        # 策略2: PNG8颜色量化（保持透明度）
        if [ "${FILE_SIZE}" -gt 15360 ]; then
            magick "${TMP_BG_TMP}" -colors 64 -define png:compression-level=9 PNG8:"${TMP_BG}"
            FILE_SIZE=$(stat -c%s "${TMP_BG}" 2>/dev/null || stat -f%z "${TMP_BG}" 2>/dev/null)
        fi
        
        # 策略3: 更低颜色数
        if [ "${FILE_SIZE}" -gt 15360 ]; then
            magick "${TMP_BG_TMP}" -colors 32 -define png:compression-level=9 PNG8:"${TMP_BG}"
            FILE_SIZE=$(stat -c%s "${TMP_BG}" 2>/dev/null || stat -f%z "${TMP_BG}" 2>/dev/null)
        fi
        
        rm -f "${TMP_BG_TMP}"
        echo -e "      ${GREEN}[√] 压缩后大小: $((FILE_SIZE / 1024))k (目标 <15k)${RESET}"
    else
        cp "${TMP_BG_TMP}" "${TMP_BG}"
        rm -f "${TMP_BG_TMP}"
    fi
    
    # 设置步骤编号（背景图版）
    GENERATE_STEP=3
    COMPILE_STEP=4
    HOOK_STEP=5
    PACK_STEP=6
else
    # 设置步骤编号（基础版）
    GENERATE_STEP=2
    COMPILE_STEP=3
    HOOK_STEP=4
    PACK_STEP=5
fi

# 步骤N: 生成插桩代码
echo -e "${YELLOW}[${GENERATE_STEP}/${TOTAL_STEPS}] 生成插桩代码${RESET}"
if [ "${HOOK_MODE}" = "bg" ]; then
    GENERATE_HOOK_BG
    echo -e "      ${GREEN}[√] ResizeHook.java 生成成功 (ResizeBgHelper.class 内嵌免编译)${RESET}"
else
    GENERATE_HOOK_BASIC
    echo -e "      ${GREEN}[√] ResizeHook.java 生成成功${RESET}"
fi

# 步骤N: 编译插桩代码（含 CLDC/MIDP 标准库确保 J2ME 类引用完整）
echo -e "${YELLOW}[${COMPILE_STEP}/${TOTAL_STEPS}] 编译插桩代码${RESET}"
# ResizeHook 运行在宿主机（工具），--release 8 保证 JDK 8/17/21 均兼容
javac -encoding UTF-8 --release 8 -cp "${CP_ALL}" ResizeHook.java
if [ "${HOOK_MODE}" = "bg" ]; then
    # ★ 内嵌预验证 ResizeBgHelper.class（base64）→ 免 JDK 编译/StripFrames/Patcher
    #   JDK 1.6.0_45 编译, target 1.4, Halo preverify.exe 处理 | v48.0 | CLDC StackMap
    echo "${RESIZE_BG_HELPER_B64}" | base64 -d > ResizeBgHelper.class
    echo -e "      [√] ResizeBgHelper.class 已就绪 (v48.0, CLDC StackMap, 免编译)"
fi
echo -e "      ${GREEN}[√] 编译成功${RESET}"

# 步骤N: 执行字节码插桩（COMPUTE_MAXS + SKIP_FRAMES → 输出无栈帧）
echo -e "${YELLOW}[${HOOK_STEP}/${TOTAL_STEPS}] 执行字节码插桩${RESET}"
find "${TMP_DIR}" -name "*.class" | while read -r cls; do
    java -cp ".:${CP_ALL}" ResizeHook "${cls}"
done

# 背景图版：注入内嵌预验证 ResizeBgHelper.class（base64 解码，免编译免处理）
if [ "${HOOK_MODE}" = "bg" ]; then
    echo "${RESIZE_BG_HELPER_B64}" | base64 -d > "${TMP_DIR}/ResizeBgHelper.class"
    echo -e "      ${GREEN}[√] ResizeBgHelper.class 已注入 (v48.0, CLDC StackMap, 内嵌免编译)${RESET}"
fi

# 步骤N: 移动到目标路径
echo -e "${YELLOW}[${PACK_STEP}/${TOTAL_STEPS}] 打包并移动至目标路径${RESET}"

# ★ 内嵌 ResizeBgHelper.class 策略说明:
#   - v48.0 CLDC StackMap 属性，Halo preverify.exe 处理过
#   - KEmulator / kemnnx64 / 老顽童: CLDC StackMap 可直接通过字节码验证 ✓
#   - 不需要 javac 编译 / StripFrames / ClassVersionPatcher / ProGuard / preverify

cd "${TMP_DIR}"
jar cfm "../${TMP_PACK}" META-INF/MANIFEST.MF .
cd ..
mv -f "${TMP_PACK}" "${FINAL_JAR}"

# 全局清理（兜底）
rm -rf "${TMP_DIR}"
CLEANUP_HOOK

# 显示完成信息
echo -e "\n${CYAN}=============================================${RESET}"
echo -e "${GREEN}✅ 处理完成！${RESET}"
echo -e "${WHITE}成品路径: ${BLUE}${FINAL_JAR}${RESET}"
echo -e "${CYAN}=============================================${RESET}"