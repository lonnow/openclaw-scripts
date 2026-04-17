#!/bin/bash
# OpenClaw Workspace 自动备份脚本
# 每天北京时间 22:00 执行

cd /Users/longclaw/.openclaw/workspace

# 检查是否有改动
git diff --quiet --cached
staged=$?
git diff --quiet
unstaged=$?
git status --porcelain | grep -q . 
has_changes=$?

if [ $has_changes -eq 0 ] || [ $staged -ne 0 ] || [ $unstaged -ne 0 ]; then
    git add -A
    git commit -m "Auto-backup $(date '+%Y-%m-%d %H:%M:%S')"
    git push
    echo "[$(date)] Backup completed"
else
    echo "[$(date)] No changes to backup"
fi
