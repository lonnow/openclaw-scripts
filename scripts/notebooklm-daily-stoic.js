#!/usr/bin/env node
/**
 * NotebookLM 每日斯多葛自动化脚本
 * 
 * 功能：
 * 1. 连接 Chrome 调试端口
 * 2. 打开「每日斯多葛」notebook
 * 3. 输入整理指令
 * 4. 等待 AI 生成内容
 * 5. 保存到 Obsidian
 * 
 * 使用前提：
 * - Chrome 已启动并开启调试端口：
 *   /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --user-data-dir=/tmp/my-chrome-data
 * - 或者 Chrome 进程还在跑（端口 9222 仍然监听）
 */

const { chromium } = require('/Users/longclaw/.npm-global/lib/node_modules/playwright');

const CONFIG = {
  notebookId: '74ab4198-b2f8-46b1-ad57-aee64d2d7c3a',  // 每日斯多葛 notebook ID
  notebookUrl: `https://notebooklm.google.com/notebook/74ab4198-b2f8-46b1-ad57-aee64d2d7c3a`,
  cdpUrl: 'http://127.0.0.1:9222',
  obsidianPath: '/Users/longclaw/Library/CloudStorage/OneDrive-个人/longclawshare/obsidian_air/01-project（项目）/06-读书-每日斯多葛',
  instruction: `以《The Daily Stoic》4月16日的内容为基础整理：
1、引言部分对照原书的翻译，如引言出处是《沉思录》优先使用梁秋实译文。
2、仅对以下两类词汇，在中文后用括号补充英文原词：
2.1、中文直译容易产生歧义或解释不清的术语；
2.2、对具备基础英语能力的人，直接看英文更准确、更易理解的表达。
3、根据该日期的内容，生成一句简短"行动口号"，或参考《十二道最爱的难题：一位诺贝尔奖得主获取知识的方法》生成一个简洁的开放式问题"今日思考"。
4、生成内容时不追求逐句翻译，引言、daily stoic解析、今日思考/行动口号的逻辑一致，语境符合中国人的习惯，可以结合当下的社会热点将内容改写得更生动一些。
5、在内容后方再加上《The Daily Stoic》当天的英文原文以及逐行翻译。
6、以《每日斯多葛日签模板》为模板用Markdown格式呈现内容。`
};

async function run() {
  console.log('🚀 启动 NotebookLM 自动化...');
  
  // 1. 连接 Chrome
  console.log('📡 连接 Chrome 调试端口...');
  const browser = await chromium.connectOverCDP(CONFIG.cdpUrl);
  const ctx = browser.contexts()[0];
  const page = ctx.pages()[0];
  
  // 2. 导航到每日斯多葛
  console.log('📂 打开每日斯多葛 notebook...');
  await page.goto(CONFIG.notebookUrl);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(3000);
  console.log('   页面标题:', await page.title());
  
  // 3. 找到输入框并输入指令
  console.log('⌨️ 输入整理指令...');
  const textarea = page.locator('textarea').filter({ hasText: '' }).first();
  await textarea.click();
  await textarea.fill(CONFIG.instruction);
  await page.waitForTimeout(1000);
  
  // 4. 点击提交
  console.log('📤 提交指令...');
  const submitBtn = page.locator('button[aria-label="提交"]').last();
  await submitBtn.click();
  
  // 5. 等待生成（可能需要 1-2 分钟）
  console.log('⏳ 等待 NotebookLM 生成内容（约 30-60 秒）...');
  await page.waitForTimeout(45000);
  
  // 6. 获取生成的内容
  console.log('📄 提取生成内容...');
  const responseText = await page.evaluate(() => document.body.innerText);
  require('fs').writeFileSync('/tmp/notebooklm-raw-response.txt', responseText);
  
  // 7. 提取 Markdown 部分（通常在两个 "---" 之间）
  const mdMatch = responseText.match(/---[\s\S]*?---[\s\S]*?---/);
  let markdown = mdMatch ? mdMatch[0] : responseText;
  
  // 8. 生成文件名（需要根据实际日期动态生成）
  const today = new Date();
  const month = String(today.getMonth() + 1);
  const day = String(today.getDate());
  const dateStr = `${month}月${day}日`;
  
  // 从内容中提取标题
  const titleMatch = markdown.match(/# 《每日斯多葛》[^#]+/);
  const title = titleMatch ? titleMatch[0].replace('# ', '').trim() : `《每日斯多葛》${dateStr}`;
  const filename = `${title}.md`;
  
  // 9. 保存到 Obsidian
  const filepath = `${CONFIG.obsidianPath}/${filename}`;
  require('fs').writeFileSync(filepath, markdown);
  console.log(`✅ 已保存到: ${filepath}`);
  
  await browser.close();
  console.log('🎉 完成！');
}

run().catch(err => {
  console.error('❌ 错误:', err.message);
  process.exit(1);
});
