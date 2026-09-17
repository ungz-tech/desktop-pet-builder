# 治愈系桌面宠物 · Desktop Pet Builder

让 AI 帮你制作属于自己的桌面伙伴：可爱的形象、有性格的陪伴、自然的小动作、宠物之间的互动，以及温柔的休息提醒。

这是一个可复用的 Codex Skill，附 macOS 原生源码模板。你可以选择橘猫、小狗或喜欢的角色，自定义它们的称呼、性格和陪伴方式。

## 使用许可：非商用分享

本项目采用 **[PolyForm Noncommercial 1.0.0](LICENSE)**。可为非商业目的使用、修改和分享，分发时须保留许可及 [NOTICE](NOTICE) 署名声明。

收费售卖、使用本模板提供商业付费定制，或将项目材料用于商业产品，需要另行取得授权。具体范围和例外以许可原文为准。详见 [中文授权说明](授权说明.md)；商业授权意向可通过 [Issues](https://github.com/ungz-tech/desktop-pet-builder/issues) 联系。

署名：**ungz-tech**。这是附带非商用限制的源码分享项目。

## 下载与开始

1. [下载完整 Skill 分享包](downloads/desktop-pet-builder.zip?raw=true)，然后解压。
2. 将完整的 `desktop-pet-builder` 文件夹交给 Codex，并说：

   > 请检查并安装这个 desktop-pet-builder skill，保留所有 references、scripts 和 assets 文件。

3. 安装后，复制这段话开始：

   > 请使用 $desktop-pet-builder，给我做一个 Mac 桌面宠物组合：一只橘猫和一只小狗。小小的、治愈可爱；点击会撒娇，它们会互相玩耍、依偎和打盹，每小时温柔地提醒我休息。角色外形和称呼由我来选，请完成到能在桌面运行。

详细步骤见 [开始使用](开始使用.md)，测试范围见 [验证说明](验证说明.md)。

## 可以用它制作什么

- 小巧的透明桌面窗口，支持点击、拖动、调整大小、隐藏和找回。
- 因性格和互动而变化的表情、动作与状态。
- 多只宠物之间的玩耍、依偎、打闹和共同休息。
- 随使用时间变化的陪伴状态，以及可暂停、可稍后的休息提醒。
- 独立的宠物组合与可保存的偏好设置。

以上是 Skill 指导 AI 完成的制作方向。附带模板提供基础窗口、状态切换、简单点击动作、一起玩、提醒与保存；精细图集、复杂剧情和持续使用状态需要 AI 根据需求继续制作并验证。

## 包含内容

| 位置 | 内容 |
| --- | --- |
| `desktop-pet-builder/SKILL.md` | 给 AI 的制作流程 |
| `desktop-pet-builder/references/` | 美术、动画、行为、macOS 实现与验证方法 |
| `desktop-pet-builder/scripts/scaffold.py` | 生成独立项目的脚本 |
| `desktop-pet-builder/assets/macos-starter/` | Swift/AppKit 基础源码模板 |
| `downloads/desktop-pet-builder.zip` | 已清理个人信息的完整分享包 |

## 使用条件

制作 Mac 应用需要 macOS、Apple Command Line Tools，以及能够访问项目文件和执行代码的 AI 环境。创建角色形象需要图像生成工具或自行提供的透明 PNG；模板缺少图片时会显示占位图。

本仓库不附带角色成品图、私人配置或安装即运行的桌面应用。Windows/Linux 可复用设计方法，当前没有对应平台的原生模板。

## 分享包隐私处理

分享内容经过逐文件检查，清理了原始文件修改时间、具体设备与系统版本信息。ZIP 使用固定占位时间，不包含个人目录、账号配置、测试日志或隐藏文件；文档中的路径是通用安装示例。

分享包 SHA-256：

```text
018277a72a05710776a84dd1ec14a4d8f439f8eb324f492a4be354a5971051ff
```
