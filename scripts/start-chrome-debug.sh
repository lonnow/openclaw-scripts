#!/bin/bash
# Chrome 调试模式启动脚本
# 使用方法: ./start-chrome-debug.sh
# 或直接运行: chrome-debug

CHROME_APP="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
USER_DATA="/tmp/my-chrome-data"
PORT=9222

# 如果还没安装 chrome-devtools，用此方法启动：
# 1. 先确保 Chrome 完全退出
pkill -9 -f "Chrome" 2>/dev/null || true
sleep 2

# 2. 删除单例锁
rm -f ~/Library/Application\ Support/Google/Chrome/SingletonLock
rm -f ~/Library/Application\ Support/Google/Chrome/SingletonCookie
rm -f ~/Library/Application\ Support/Google/Chrome/SingletonSocket

# 3. 如果需要新 profile，先创建
mkdir -p "$USER_DATA"

# 4. 启动 Chrome
echo "🚀 启动 Chrome 调试模式 (端口 $PORT)..."
nohup "$CHROME_APP" \
  --remote-debugging-port=$PORT \
  --no-first-run \
  --no-default-browser-check \
  --user-data-dir="$USER_DATA" &>/tmp/chrome-debug.log &

sleep 5

# 5. 验证
if curl -s http://127.0.0.1:$PORT/json/version > /dev/null 2>&1; then
  echo "✅ Chrome 调试端口已启动: http://127.0.0.1:$PORT"
  echo "📝 现在可以运行: node notebooklm-daily-stoic.js"
else
  echo "❌ Chrome 启动失败，查看日志: cat /tmp/chrome-debug.log"
fi
