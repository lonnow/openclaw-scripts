#!/bin/bash
# 每日新股新债提醒脚本
# 北京时间 9:40 执行

RECIPIENT_ID="ou_7c3f7e916d9441aabd141edb8a84ae66"
TODAY=$(date +%Y-%m-%d)

fetch_and_send_report() {
    TODAY_DATE=$(date +%Y-%m-%d)
    # 构造日期筛选，使用变量注入避免复杂转义
    FILTER="(TRADE_DATE%3E%3D%27${TODAY_DATE}%27)"
    
    DATA=$(curl -s "https://datacenter-web.eastmoney.com/api/data/v1/get?reportName=RPT_IPO_CALENDAR&columns=SECURITY_CODE,SECURITY_NAME_ABBR,TRADE_DATE,DATE_TYPE,SECURITY_TYPE&pageNumber=1&pageSize=50&sortTypes=1&sortColumns=TRADE_DATE&filter=${FILTER}&source=WEB&client=WEB")
    
    # 提取 data 数组（简单位置估算）
    ROWS=$(echo "$DATA" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    items = d.get('result', {}).get('data', [])
    today = '$(date +%Y-%m-%d)'
    stocks = []
    bonds = []
    for item in items:
        td = item.get('TRADE_DATE', '')[:10]
        if td != today:
            continue
        code = item.get('SECURITY_CODE', '')
        name = item.get('SECURITY_NAME_ABBR', '')
        dtype = item.get('DATE_TYPE', '')
        stype = item.get('SECURITY_TYPE', '')
        if stype == '0':
            stocks.append(f'{code} {name} - {dtype}')
        else:
            bonds.append(f'{code} {name} - {dtype}')
    
    report = f'📅 {today} 新股新债提醒\n\n'
    if stocks:
        report += '🆕 新股：\n' + '\n'.join(f'  • {s}' for s in stocks) + '\n\n'
    else:
        report += '🆕 新股：无\n\n'
    
    if bonds:
        report += '🆕 新债：\n' + '\n'.join(f'  • {b}' for b in bonds) + '\n\n'
    else:
        report += '🆕 新债：无\n\n'
    
    report += '⚠️ 港股数据请手动查看集思录'
    print(report)
except Exception as e:
    print(f'获取数据失败: {e}')
")
    
    echo "=== 发送报告 ==="
    echo "$ROWS"
    
    # 调用飞书消息接口
    curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" \
        -H "Authorization: Bearer $(cat /Users/longclaw/.openclaw/extensions/openclaw-lark/token 2>/dev/null || echo '')" \
        -H "Content-Type: application/json" \
        -d "{\"receive_id\":\"${RECIPIENT_ID}\",\"msg_type\":\"text\",\"content\":{\"text\":\"${ROWS}\"}}"
}

# 主循环：每分钟检查一次
while true; do
    HOUR=$(date +%H)
    MIN=$(date +%M)
    if [ "$HOUR" = "01" ] && [ "$MIN" = "40" ]; then
        echo "[$(date)] 执行新股新债提醒..."
        fetch_and_send_report
        sleep 60
    fi
    sleep 30
done
