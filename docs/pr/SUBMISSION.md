# 提交说明 Submission handoff

这是一份可审阅的 V1.4.5 源码与草稿 PR 材料。它不是已经发送到 GitHub 的 PR，也不是已经移植到最新 1.4.x 的版本。

## 包内文件

- 完整源码 ZIP：用于查看或在独立目录中构建；包含上游资源及原 LICENSE，不含 .git、生产密钥、客户模型和缓存。
- Git 补丁系列：基于精确 V1.4.5 提交，供 git am 应用；运动差异可单独审阅。
- 中英文 PR 正文与上游适配说明。
- 中英文使用说明、构建测试指南、格式与入口文档、中英文运动差异报告。
- SHA256 清单与本次实际验证记录。

## 在自己的 fork 中准备分支

```powershell
git clone https://github.com/YOUR_ACCOUNT/PNGTuber-Remix.git
cd PNGTuber-Remix
git remote add upstream https://github.com/MudkipWorld/PNGTuber-Remix.git
git fetch upstream --tags
git switch -c feature/protected-model-v145 6b093894e33d804368367a0e98e1dc3722e4909b
# 将路径改为解压后的补丁目录；按文件名顺序应用。
Get-ChildItem 'C:/PR-Package/patches/*.patch' | Sort-Object Name | ForEach-Object { git am $_.FullName; if ($LASTEXITCODE -ne 0) { throw 'Resolve patch failure before continuing' } }
```

按 docs/protected/build-and-test.md 生成自己的密钥并运行测试。不要把私密 BuildKeys.gd、.pngRemix 工程、保护模型、个人设置或构建日志加入提交。

## 推送及创建草稿 PR

核对分支与文件后，再执行以下步骤。这里仅提供命令，准备流程没有执行推送。

```powershell
git push -u origin feature/protected-model-v145
# 直接使用 docs/pr/PR-BODY.en.md 作为正文。
gh pr create --repo MudkipWorld/PNGTuber-Remix --base 1.4.x --head YOUR_ACCOUNT:feature/protected-model-v145 --draft --title 'Add experimental protected model export and playback for V1.4.5' --body-file docs/pr/PR-BODY.en.md
```

当前默认分支已有明显变化，可能产生合并冲突或功能不兼容。先以草稿讨论基线、运动行为和保护方案；维护者确认目标分支后再完成移植与重测。不要用完整源码 ZIP 覆盖上游新分支。标签不能直接作为 PR 目标分支。

## English summary

Apply the ordered patches to the exact V1.4.5 commit on your fork, generate private build keys, and run the documented tests. Review the complete diff before pushing. Open a draft PR against the maintainer-approved branch; the observed default is 1.4.x and requires forward-port work. The preparation workflow does not publish, grant commercial redistribution rights, or include production keys. See PR-BODY.en.md and UPSTREAM-INTEGRATION.md for the submission text and integration limits.
