# 角色与动画素材

## 先固定外形

用户已经认可的形象是基准；后续表情和动作沿用参考图。记录轮廓、主配色、脸部特征、左右眼/耳、衣服与道具、头身比。不要每加一个动作就重新设计角色。

先做少量姿态确认一致性，再扩展。用当前可用的图像生成工具制作透明 PNG；编辑时提供原图。保留原始输出和生成提示词。核对实际 RGBA 通道，棋盘格或白色并不等于透明。

可采用独立状态 PNG 或图集；不要把独立 PNG 的模板加载器直接当成图集播放器。

## 可复用的图集提示词骨架

按角色替换花括号内容，不直接作为最终提示词：

> Production desktop companion sprite atlas of {角色描述}. Match the supplied reference exactly: {固定外形特征}. {N} distinct full-body poses in {列数} columns and {行数} rows. Rounded forms, coherent soft shading, crisp readable silhouette at small desktop size. Same physical scale and ground line across all poses; seated poses remain shorter. Generous fully transparent gutters. Keep ears, tails, hands, shoes and every prop completely inside each frame. True RGBA transparent background, no text, labels, watermark, stage or cursor. Pose order: {逐帧明确描述}.

按角色需要选姿态：平静、眨眼、开心、害羞/撒娇、向左/右、招手、伸展、打盹、关心、专属动作。数量由剧情需要决定，不要求每次都生成 16 帧。

## 体积与运动

“纸片转圈”通常来自旋转整张正面图或把宽度压缩至零。需要真实转身感时采用前、侧、后及过渡视角，或在任务合适时采用三维模型。不要把 CSS/仿射翻转称为三维。

四足转圈可编排：起身 → 四足交替迈步与转头 → 绕一圈 → 落脚停稳 → 坐下。猫和狗可采用不同速度、尾巴节奏；身体比例不要跟着转向反复拉伸。跳跃要有轻微预备、离地和落地缓冲；尾巴动作与身体错开。

自动剧情不必移动真实窗口：在留足边距的画布内移动角色可避免覆盖其他内容。若真的移动窗口，结束/中断后归位，屏幕边界与用户拖动优先。

## 图集数据与锚点

生成图集的内容未必严格落在均匀格子。逐帧识别实际角色边界；检查道具、爱心等分离区域，不能只取最大连通块。记录像素矩形、躯干中心和落脚点，避免尾巴或剑的伸出让角色左右跳动。

示例元数据（具体 schema 随实现）：

```json
{"image":"atlas.png","frames":[
  {"id":"calm","rect":[40,30,180,230],"pivot":[125,252],"duration":0.8},
  {"id":"blink","rect":[310,30,180,230],"pivot":[395,252],"duration":0.12}
]}
```

这里 rect 为左上角 x/y/宽/高；pivot 为原图中的躯干落脚位置。明确坐标系，再换算到 AppKit 的左下原点。

统一角色尺度；禁止把每帧分别缩放到同样的外包围框。坐下会变矮，举手会变高，这是姿态本身的变化。

## 画面验收

渲染动作中段与切换点，检查前后朝向、身体比例、角色是否跳动、字幕和边缘是否裁切。小尺寸优先保证脸和轮廓清晰。按实际绘制坐标反算点击命中；道具、头发、尾巴随动画变化后也不能错位。减少动态效果时保留有意义的静态姿态。
