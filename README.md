# iai Skill

Claude Code skill for **iai (爱 AI)** — Longbridge's internal one-click deploy platform. 让 Claude 在对话里直接帮你把当前项目打包、上传、构建、部署到平台。

## 安装

```bash
rm -rf ~/iai-skill && \
  git clone https://github.com/almightyYantao/it-iai-skill.git ~/iai-skill && \
  bash ~/iai-skill/install.sh install
```

幂等，已装的直接重跑就是升级。安装器会：

1. 检查 `bash / curl / jq / tar / zstd / git` 都装了
2. 在 `~/.claude/skills/iai` 创建 symlink → Claude Code 自动认出来
3. 引导你填 API URL 和 Deploy Token，写到 `~/.vibedeploy/`
4. 用 `/healthz` 和 `/v1/whoami` 试一下能不能联通

## 用法

在 Claude Code 里跟它说：

- `部署一下` / `deploy +push` —— 把当前目录推上去
- `看下状态` / `deploy +status` —— 查项目 URL + 部署进度
- `给我看日志` / `deploy +logs -f` —— 跟构建/运行日志
- `列出我的项目` / `deploy +list`

完整命令清单和实施细节在 [SKILL.md](SKILL.md)。

## 改项目名 / 开 HTTPS / 加自定义域名

这些都走 **Admin UI**（项目详情页对应面板），Skill 里没有对应命令。直接问 Claude "怎么改 X" 它会引导你去后台。

## 关联仓库

- 平台主仓（control-plane / build-service / Web UI / 部署脚本）：[almightyYantao/it-iai](https://github.com/almightyYantao/it-iai)
- 本仓只装 **Skill**，业务方拉这一个就够用，不用拉平台代码

## 卸载

```bash
bash ~/iai-skill/install.sh uninstall
```

移除 Claude Code 那边的 symlink；`~/.vibedeploy/` 下的配置和 token 留着（手动 `rm -rf` 才彻底清干净）。
