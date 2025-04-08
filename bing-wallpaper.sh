#!/bin/bash

# 定义壁纸保存路径和文件名
SCRIPT_PATH=$(realpath $0)
WALLPAPER_DIR="$HOME/Pictures/BingWallpapers"
WALLPAPER_FILE="$WALLPAPER_DIR/bing_wallpaper_$(date +%Y%m%d).jpg"
BLURRED_FILE="$WALLPAPER_DIR/bing_wallpaper_$(date +%Y%m%d)_blurred.jpg"
MAX_WALLPAPERS=8  # 设置保留的最大壁纸数量
SWAYLOCK_CONFIG="$HOME/.config/swaylock/config"
DEFAULT_SWAYLOCK_CONFIG="/etc/swaylock/config"
SWAY_CONFIG="$HOME/.config/sway/config"
DEFAULT_SWAY_CONFIG="$HOME/etc/sway/config"

# 创建壁纸目录（如果不存在）
mkdir -p "$WALLPAPER_DIR"

# 获取 Bing 每日壁纸 URL
BING_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
IMAGE_URL=$(curl -s "$BING_URL" | jq -r '.images[0].url' | sed 's/^/https:\/\/www.bing.com/')

# 下载壁纸（如果当天壁纸不存在）
if [ ! -f "$WALLPAPER_FILE" ]; then
    curl -s -o "$WALLPAPER_FILE" "$IMAGE_URL"
fi

# 生成模糊版本
if [ ! -f "$BLURRED_FILE" ]; then
    convert "$WALLPAPER_FILE" -blur 0x8 "$BLURRED_FILE"
fi

# 删除多余壁纸，仅保留最新的 8 张
# 使用 ls -t 按时间排序，列出所有 jpg 文件，跳过最新 8 个，删除其余的
mapfile -t OLD_FILES < <(ls -t "$WALLPAPER_DIR"/*.jpg 2>/dev/null | tail -n +$((MAX_WALLPAPERS + 1)))
if [ ${#OLD_FILES[@]} -gt 0 ]; then
    rm -f "${OLD_FILES[@]}"
fi

# 获取当前 swaybg 的 PID
OLD_PID=$(pidof swaybg)

# 启动新的 swaybg 实例
swaybg -i "$WALLPAPER_FILE" -m fill &

# 等待新实例加载完成
sleep 1

# 杀死旧实例（如果存在）
if [ -n "$OLD_PID" ]; then
    kill "$OLD_PID"
fi

# 处理 swaylock 配置文件
if [ -f "$SWAYLOCK_CONFIG" ]; then
    # 如果用户配置文件存在，直接修改 image= 行
    sed -i "s|^image=.*$|image=$BLURRED_FILE|" "$SWAYLOCK_CONFIG"
else
    # 如果用户配置文件不存在，从 /etc/swaylock/config 复制并修改
    if [ -f "$DEFAULT_SWAYLOCK_CONFIG" ]; then
        mkdir -p "$(dirname "$SWAYLOCK_CONFIG")"
        cp "$DEFAULT_SWAYLOCK_CONFIG" "$SWAYLOCK_CONFIG"
        sed -i "s|^image=.*$|image=$BLURRED_FILE|" "$SWAYLOCK_CONFIG"
    else
        # 如果 /etc/swaylock/config 也不存在，创建基本配置文件
        mkdir -p "$(dirname "$SWAYLOCK_CONFIG")"
        cat << EOF > $SWAYLOCK_CONFIG
# The defaults below could be overridden in \$XDG_CONFIG_HOME/swaylock/config
#  (~/.config/swaylock/config).
#
# Image path supports environment variables and shell expansions,
# e.g. image=\$HOME/Pictures/default.png
# image=/usr/share/backgrounds/default.png
image=$BLURRED_FILE
scaling=fill
EOF
    fi
fi

# 修改 ~/.config/sway/config 中的 output * bg 行
if [ -f "$SWAY_CONFIG" ]; then
    # 检查是否存在 output * bg 行并替换
    if grep -q "^output \* bg" "$SWAY_CONFIG"; then
        sed -i "s|^output \* bg .*|output * bg $WALLPAPER_FILE fill|" "$SWAY_CONFIG"
    else
        # 如果没有该行，追加到文件末尾
        echo "output * bg $WALLPAPER_FILE fill" >> "$SWAY_CONFIG"
    fi
else
    if [ -f "$DEFAULT_SWAY_CONFIG" ]; then
        mkdir -p "$(dirname "$SWAY_CONFIG")"
        cp "$DEFAULT_SWAY_CONFIG" "$SWAY_CONFIG"
        # 检查是否存在 output * bg 行并替换
        if grep -q "^output \* bg" "$SWAY_CONFIG"; then
            sed -i "s|^output \* bg .*|output * bg $WALLPAPER_FILE fill|" "$SWAY_CONFIG"
        else
            # 如果没有该行，追加到文件末尾
            echo "output * bg $WALLPAPER_FILE fill" >> "$SWAY_CONFIG"
        fi
    else
        mkdir -p "$(dirname "$SWAY_CONFIG")"
        echo "output * bg $WALLPAPER_FILE fill" > "$SWAY_CONFIG"
    fi
fi

# 设置systemd刷新定时器
REFRESH_DUE_H="24"
REFRESH_DUE_M="5"
TIMER_FILE="$HOME/.config/systemd/user/bing-wallpaper.timer"
TIMER_SERVICE="$HOME/.config/systemd/user/bing-wallpaper.service"

API_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1"
FULLSTARTDATE=$(curl -s "$API_URL" | grep -m 1 -o '"fullstartdate":"[^"]*"' | sed 's/"fullstartdate":"\(.*\)"/\1/')
# FULLSTARTDATE=$(curl -s "$API_URL" | awk -F'"' '{for (i=1; i<=NF; i++) if ($i=="fullstartdate") {print $(i+2); exit}}')

# 检查是否成功获取
if [ -z "$FULLSTARTDATE" ]; then
  echo "无法获取 fullstartdate，请检查网络或 API 是否可用。"
  exit 1
fi

FULLSTARTDATE_FMT=$(date -d "${FULLSTARTDATE:0:8} ${FULLSTARTDATE:8:2}:${FULLSTARTDATE:10:2}" "+%Y-%m-%d %H:%M UTC")
FULLSTARTDATE=$(TZ=$(timedatectl | grep "Time zone" | awk '{print $3}') date -d "$FULLSTARTDATE_FMT + $REFRESH_DUE_H hours $REFRESH_DUE_M minutes" "+%Y-%m-%d %H:%M:%S")

# 如果不存在定时器文件
if [ -f "TIMER_FILE" ]; then
    sed -i "s|^OnCalendar=.*$|OnCalendar=$FULLSTARTDATE|" "$TIMER_FILE"
else
    mkdir -p "$(dirname "$TIMER_FILE")"
    cat << EOF > $TIMER_FILE
[Unit]
Description=特定时间的定时任务示例

[Timer]
OnCalendar=$FULLSTARTDATE
AccuracySec=1s
Unit=bing-wallpaper.service

[Install]
WantedBy=timers.target
EOF
fi

# 如果不存在定时服务文件
if [ ! -f "$TIMER_SERVICE" ]; then
    mkdir -p "$(dirname "$TIMER_SERVICE")"
    cat << EOF > $TIMER_SERVICE
[Unit]
Description=特定时间的一次性任务示例
After=graphical-session.target

[Service]
ExecStart=$SCRIPT_PATH
Type=oneshot
RemainAfterExit=no
KillMode=process
EOF
fi

systemctl --user daemon-reload
if [ ! -f "$HOME/.config/systemd/user/timers.target.wants/bing-wallpaper.timer" ]; then
    systemctl --user enable bing-wallpaper.timer
fi
systemctl --user restart bing-wallpaper.timer
