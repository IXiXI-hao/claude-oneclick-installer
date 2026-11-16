# Claude Code 一键安装（DeepSeek 端点）

给 Windows 电脑准备的 Claude Code 安装包：双击运行，粘贴自己的 DeepSeek API Key，即可开始使用。无需 Node.js，无需管理员权限。

## 下载

[下载完整安装包](https://github.com/IXiXI-hao/claude-oneclick-installer/releases/latest)

> 仓库里只有脚本和预置配置。`claude.exe`（224MB）超过 GitHub 单文件 100MB 限制，因此放在 Release 附件中。

## 系统要求

- Windows 10 / 11，64 位（x64）
- 一个 DeepSeek API Key

## 三步安装

1. 下载 `Claude-OneClick-Installer.zip` 并解压到任意文件夹（不要在压缩包里直接运行）。
2. 双击 `一键安装.bat`。
3. 按提示粘贴 DeepSeek API Key，回车。

看到「全部完成」后，桌面会出现两个图标：

| 图标 | 用途 |
| --- | --- |
| Claude | 日常使用，双击直接对话 |
| CC Switch | 可视化修改 Key、切换供应商 |

## 获取 DeepSeek API Key

1. 打开 https://platform.deepseek.com/api_keys
2. 登录后创建一个 API Key（`sk-` 开头）
3. 复制并粘贴到安装程序的提示处

## 安装程序做了什么

| 内容 | 位置 |
| --- | --- |
| Claude Code | `%USERPROFILE%\.localin\claude.exe` |
| Claude 配置 | `%USERPROFILE%\.claude\settings.json` |
| CC Switch | `%LOCALAPPDATA%\Programs\CC Switch\cc-switch.exe` |
| CC Switch 配置 | `%USERPROFILE%\.cc-switch\` |

写入的配置包括：

- `ANTHROPIC_BASE_URL = https://api.deepseek.com/anthropic`
- `ANTHROPIC_AUTH_TOKEN = 你的 Key`
- 模型统一为 `deepseek-flash`

脚本不会上传任何数据，Key 只保存在本机。

## 更换 Key / 供应商

双击桌面 **CC Switch**：

1. 选中 **DeepSeek**
2. 点编辑，把 Key 换成新的
3. 点启用

也可以直接重新运行 `一键安装.bat` 输入新 Key，其他配置会保留。

## 常见问题

**双击后 Windows 提示「Windows 已保护你的电脑」**

点「更多信息」→「仍要运行」。

**提示 Key 格式不对**

Key 必须以 `sk-` 开头，DeepSeek 的 Key 一般是 35 位。

**Claude 报 401 / Authentication Fails**

Key 无效、被删除或没有额度。去 DeepSeek 平台确认，然后在 CC Switch 里换 Key。

**第一次打开 Claude 问是否信任文件夹**

选 Yes。

**CC Switch 双击没反应**

Windows 10 可能缺少 WebView2 运行时，安装一次 Microsoft Edge WebView2 Runtime 即可；Windows 11 通常自带。

**想换模型**

编辑 `%USERPROFILE%\.claude\settings.json` 里的 `ANTHROPIC_MODEL` 等字段，或在 CC Switch 的供应商配置中修改。

## 仓库结构

```
一键安装.bat       双击入口
setup.ps1          安装逻辑
seed/cc-switch.db  CC Switch 预置数据库（仅 DeepSeek，占位 Key）
seed/settings.json CC Switch 设备设置
```

完整安装包见 [Releases](https://github.com/IXiXI-hao/claude-oneclick-installer/releases)。

## 说明

- 本项目只是把 Claude Code 配置到 DeepSeek 的 Anthropic 兼容端点，不包含 Anthropic 账号或订阅。
- 请只使用自己的 API Key。
