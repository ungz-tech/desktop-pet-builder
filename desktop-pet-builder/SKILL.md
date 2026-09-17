---
name: desktop-pet-builder
license: PolyForm-Noncommercial-1.0.0
description: Build or improve customizable desktop pets with transparent windows, expressive animation, personalities, multi-pet interactions, and gentle break reminders. Use for creating an actual desktop companion app or extending one; includes a macOS Swift/AppKit starter. Not for merely drawing a mascot or configuring an existing unrelated pet product.
---

# 治愈系桌面宠物

把用户喜欢的角色变成能留在桌面、回应点击、记住陪伴、彼此互动的伙伴。交付可运行应用和可继续修改的源代码。使用用户的语言沟通。

本分享版采用 [PolyForm Noncommercial 1.0.0](LICENSE)，分发时须保留许可和 [署名声明](NOTICE)。商用需另行取得授权；生成项目或应用包含本模板代码时，也应附带这两份文件。

## 先沿用用户已经作出的选择

检查当前项目和已有素材。确定操作系统、角色数量/组合、外形、称呼、提醒偏好；只询问会阻碍实现且无法从上下文得知的事项。其余做出合理选择并说明。不要把示例中的名字、性别、动漫角色或亲密表达套到所有用户身上。

已有应用优先增量修改；保留位置、大小、亲近度、提醒开关和用户已选形象。默认理解“再增加互动”为继续完成现有应用，而不是只列点子。

## 根据当前任务读取资料

- 创建或扩展角色素材：读 [角色与动画素材](references/art-and-animation.md)。图像工具可用时使用当前环境的图像生成/编辑能力及其适用指引；不要假设固定工具名或 API 密钥。缺少图像能力时沿用用户素材、完成代码可做的部分，并明确素材缺口。
- 设计性格、双宠剧情、使用时间变化：读 [行为与陪伴](references/behavior.md)。表中的时长是可调整设计示例。
- macOS 实现、点击穿透、隐藏找回或拆分组合：读 [原生实现](references/macos.md)。Windows/Linux 任务沿用行为设计，按用户平台实现窗口层；不要交付不能在目标系统运行的 Mac 包。
- 构建、测试、替换旧版本、分享：读 [验证与交付](references/validation.md)。

## 把“可爱”落实为可观察的行为

静止时少量呼吸、眨眼或姿态变化；点击立即回应；每个角色有不同节奏。多角色互动有开始、互相回应和结束归位。优先保留身体体积、落脚点和角色特征。

宠物用简短的话直接对用户说话。默认自动互动安静播放，手动互动再说话；不持续输出剧情旁白。用户要求黏人、安静或不同风格时，以用户选择为准。

点击后开心可以短暂优先；休息提醒有更高优先级；拖动、隐藏和退出能可靠中断动作。没回应时可以短暂担心或小别扭，然后自行恢复，不因用户忙碌持续惩罚亲近度。

## 新建 macOS 项目

若现有工程已可用，不必换成模板。新项目可运行：

```sh
python3 "<本技能目录>/scripts/scaffold.py" \
  --output "<工作目录>/my-desktop-pets" \
  --app-name "桌面伙伴" --nickname "朋友" \
  --pet "橘猫" --pet "小黄狗"
```

脚本只创建新目录；拒绝覆盖现有项目。它生成独立 bundle ID、可编辑配置、原生窗口与菜单、点击/双宠位移动作、提醒、位置与亲近度存储、构建脚本和自检。

**这是可运行的基础模板，不是已经完成的宠物成品。** 未放入 PNG 时显示有标签的原生占位图形。制作角色素材后，按配置文件中的状态图片路径接入，再依用户要求扩展姿态帧、双宠剧情和使用时长状态。不要把占位图交作用户要求的角色形象。模板不包含任何固定角色的成品图片，也不依赖原作者的电脑目录。

```sh
cd "<生成的项目>"
python3 build.py
"dist/桌面伙伴.app/Contents/MacOS/DesktopPets" --self-test
"dist/桌面伙伴.app/Contents/MacOS/DesktopPets" --smoke-test
```

构建需要 macOS 和 Apple Command Line Tools。图像制作工具只在制作素材时需要；完成后的本地应用无需调用语言模型 API 才能播放这些互动。

## 完成标准

检查原生运行、真实正常启动与保存设置，不能只以编译成功为完成。按任务范围验证新增动作/状态；仅修改文字等低影响事项不必扩展测试范围。

展示或提供实际渲染的代表画面；交付应用、源码、素材说明与简短使用方法。讲清“怎么打开、怎么互动、隐藏后在哪里找、怎么退出”。区分已实测、模拟时间验证和未验证的平台。分享包使用相对路径，不包含用户状态、个人称呼、密钥或本机记录。
