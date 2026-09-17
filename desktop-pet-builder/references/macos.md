# macOS 原生实现

## 模板范围

assets/macos-starter 是 Swift/AppKit 的小型基础应用。scaffold.py 将它复制为独立项目；build.py 构建当前机器架构的 .app，不需要第三方 Python 包。基础能力：多透明窗口、状态 PNG、点击/一起玩、拖动保存、尺寸菜单、找回、提醒开关、稍后/休息按钮、亲近度和隔离测试。

未内置：精细图集播放器、真实转身、完整双宠剧情、基于输入空闲的五阶段表现。根据任务按其他参考资料扩展，不能把指南覆盖的功能说成模板已经实现。

## PNG 与配置

scaffold 生成 config.json，包含 app_name、bundle_id、nickname、scale、reminder_minutes、reminders_enabled 和 pets。每只角色有稳定 id、显示名、sway/bounce 点击风格，以及 calm/happy/sleepy/concerned 四种状态的 PNG 文件名。

状态图片放 Resources。模板要求这些图片使用同样的透明画布尺寸、同一身体比例与底线；否则先做统一锚点的图集加载器。缺少某状态回退 calm；完全缺图时显示明确写着“素材占位”的诊断图形。

## 窗口、命中与找回

采用无边框、非激活、透明 NSPanel：isOpaque=false、backgroundColor=.clear、hasShadow=false、浮动层级。启用用户需要的空间/全屏陪伴，但不要抢走当前输入焦点。LSUIElement=true 可让应用以菜单栏伙伴运行。

透明像素穿透至底下的桌面，身体仍可点击。每一帧的命中位置必须与渲染位置一致：逆向去除位移、缩放、旋转、镜像，再采样实际帧的 alpha。拖动时保持接收鼠标，避免穿透导致拖到一半丢失。

永远留一个可发现的入口：菜单栏显示/隐藏、恢复屏幕位置、退出。重新打开已运行的应用可调用 applicationShouldHandleReopen 来显示。屏幕断开、缩放、换分辨率后，用 visibleFrame 重新约束位置，包括负坐标副屏。

## 生命周期与存储

正常运行使用 UserDefaults.standard，系统按 bundle ID 隔离。不要用当前应用自己的 bundle ID 创建 UserDefaults(suiteName:) 并强制解包；这条路径可能返回 nil，且测试专用 suite 不会暴露该正常启动崩溃。

原生 smoke test 使用独立测试 suite；结束只清理该测试域。正常启动与 smoke test 都要验证。不要为了测试清空用户默认域。

游戏/动画采用单调时钟；整点提醒用明确的下次到期时间。菜单打开、手动动作、提醒、隐藏、拖动都必须维护中断状态。跟踪闭包和定时器生命周期，减少动态效果时去掉循环位移。

简单使用时长估算可使用 CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: UInt32.max)!)，但先核对目标 SDK 并实测返回值。不需要安装全局键盘内容监听。处理 sleep/wake、screen sleep/wake 和用户会话切换。

## 更新与发布

先在新 bundle 路径构建/验证，再退出目标旧版，备份旧 bundle，整体替换。不要把独立人物资源直接叠拷进旧合并包，遗留资源会混入发布物。只重启任务涉及的应用，不影响其他组合。

本地 ad-hoc 签名仅供本机构建验证，不等于 Developer ID 签名/公证。向他人分发预编译 Mac 应用时明确架构和系统版本；需要广泛分发时依正常签名、公证流程完成。不要以关闭 Gatekeeper 作为安装步骤。

用户说出现奇怪箭头/光晕时，先区分宠物画面、系统指针和自动化工具覆盖层。不要盲删角色素材，也不要把结束某个本机工具进程写成每个项目都执行的固定步骤。
