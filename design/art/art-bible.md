# Art Bible: 三段破空

## Document Status
- **Version**: 1.0
- **Last Updated**: 2026-05-09
- **Owned By**: art-director
- **Status**: Draft
- **Review Mode**: Solo
- **Art Director Sign-Off (AD-ART-BIBLE)**: Skipped — Solo mode, 2026-05-09

## Visual Identity Statement

**One-line rule**: 暗场亮刀，少像素打出重拳感。

三段破空的画面必须让玩家第一眼看见剑士姿态、剑光轨迹、木桩受击方向和命中特效。场景是克制的复古武侠练功房，承担气氛但不抢读招；最高亮度永远留给刀光、hit spark、闪白和关键 UI 反馈。

### Supporting Principles

1. **命中优先于装饰** — 如果背景纹理、道具或角色细节影响判断命中时机，删减装饰并保留受击信息。
2. **木桩必须会表演** — 木桩的倾斜、压缩、位移、浮空轨迹和落地尘必须像第二个主角一样清楚。
3. **短动画也要有关键帧重量** — 帧数可以少，但预备、命中、收招、受击这几帧必须轮廓明确、节奏锋利。

## Mood & Atmosphere

| Game State | Mood Target | Lighting Character | Visual Carriers | Energy |
| ---------- | ----------- | ------------------ | --------------- | ------ |
| Training Idle | 安静、可重复、低压力 | 冷灰石砖底色，局部暖光落在训练区 | 石砖地面、木桩、布帘、微弱尘粒 | Measured |
| Ground Combo | 集中、节奏清楚 | 背景维持低对比，剑光和命中闪白突然拉亮 | 横向剑轨、短 hit spark、木桩微倾 | Sharp |
| Launcher / Air Chase | 上升、破空、技术感 | 竖向亮色轨迹增强空间高度 | 挑空弧线、木桩上抛残影、脚下尘 | Rising |
| Combo Success | 爽快、确认、想再来一次 | 金白色短促高亮，随后快速回落 | Combo 数字弹跳、收刀闪、落地尘 | Punchy |
| Reset / Failure | 不惩罚、快速恢复 | 亮度回到训练 Idle，不使用失败红屏 | 木桩复位残影、轻微尘线 | Calm |
| Menus / HUD | 克制、武馆器具感 | 低饱和深色底，米白文字，高亮仅用于当前选择 | 细线边框、纸签/木牌感小面板 | Quiet |

## Shape Language

### Character Silhouette

剑士使用清晰的三角动势：头部和躯干保持小块面，剑与披挂形成长斜线。读招的第一优先级是武器方向，其次是身体重心，最后才是服饰细节。

### Dummy Silhouette

木桩以竖直圆柱和横向短木臂构成，静止时稳定，受击时明显偏转。浮空状态要打破竖直稳定感，让玩家不用看数值也能判断它已进入可追击窗口。

### Environment Geometry

场景以水平地面线、竖向梁柱、矩形石砖为主，形成稳定练功房。可动与可交互对象使用更高对比轮廓，背景道具保持低饱和、低边缘锐度。

### UI Shape Grammar

HUD 使用紧凑矩形、短横线、数字和小图标，像训练记录而不是华丽卷轴。UI 不模拟复杂纸张或木牌，以免在 Web 小窗口中牺牲可读性。

## Color System

### Primary Palette

| Name | Hex | Usage |
| ---- | --- | ----- |
| Ink Black | `#141414` | 最深背景、文字阴影、像素描边 |
| Stone Gray | `#4A4D4A` | 石砖、墙面、低饱和环境主体 |
| Aged Wood | `#7A5436` | 木桩、梁柱、训练器具 |
| Cloth Red | `#8E2F2D` | 布帘、少量武侠场景点色，不作为危险唯一提示 |
| Sword White | `#F4F0DC` | 刀光核心、命中闪白、主文字 |
| Spark Gold | `#F2B84B` | hit spark、combo 成功、当前选中 |
| Air Cyan | `#6EC6C4` | 挑空轨迹、空中追击提示、可追击窗口 |

### Semantic Color Usage

| Semantic Role | Color | Backup Cue |
| ------------- | ----- | ---------- |
| Hit confirmed | Sword White + Spark Gold | hitstop、火花形状、短音效 |
| Launcher / juggle window | Air Cyan | 上升箭形轨迹、木桩浮空姿态 |
| Current combo / success | Spark Gold | 数字弹跳、轻微缩放、确认音 |
| Reset / neutral | Stone Gray + Aged Wood | 木桩回正动画、尘线消散 |
| Warning / dropped combo | Cloth Red sparingly | 数字断裂、低音提示，不只依赖红色 |

### Colorblind Safety

红色不得单独表达失败或危险；必须配合形状变化、音效或动画。金色与青色的语义差异也必须有形状备份：金色用爆点和数字反馈，青色用弧线和上升方向。

## Character Design Direction

### Player Character

剑士是复古武侠训练者，不追求复杂服饰。可使用深色衣身、浅色袖口或腰带、亮剑刃形成读招层级。角色在 1x 像素视图下也必须看出面朝方向、剑的位置和当前动作重心。

### Animation Targets

- Idle: 小幅呼吸，不晃动剑尖到影响读招。
- Ground slashes: 每招 3 个核心阶段，预备、命中、收招；命中帧轮廓必须最大。
- Launcher: 明显下沉蓄力后向上斜切，剑轨垂直分量强。
- Air slash: 身体压缩成斜向剪影，剑光覆盖空中追击范围。
- Recovery: 收招要短，让玩家感觉可快速重试。

### LOD Philosophy

近景游戏镜头下保留轮廓和关键帧，不追求服饰细纹。任何细节如果在 Web 浏览器缩放后变成噪点，就合并为更大的色块。

## Environment Design Language

训练场是室内或半室内武馆空间：石砖地、木桩、梁柱、布帘、墙上简化兵器架。背景只讲一个信息：这是专门为练招存在的地方。

### Texture Rules

- 石砖：低饱和、低对比、块面清楚，不使用高频裂纹。
- 木材：保留 1-2 档明暗，强化木桩受击变形，不强调写实纹理。
- 布帘：作为红色点缀，面积受控，不出现在剑光背后。
- 地面接触点：必须支持脚步、落地、木桩复位尘效。

### Prop Density

默认稀疏。可见区域内的装饰道具不得超过 3 类，且不得贴近角色和木桩主交互空间。训练区中央要干净，让连段轨迹完整可见。

## UI/HUD Visual Direction

HUD 要服务练习，不做复杂菜单表演。第一屏应直接进入训练场，显示必要状态：combo、最高 combo、当前输入提示或重置提示。

### Typography

优先使用清晰像素字体或等宽数字字体。数字可比标签更大，但不能遮挡角色与木桩。中文 UI 必须选择可读性高的像素风或无衬线字体，避免过度书法化。

### HUD Layout

- Combo counter: 靠上方或上侧偏中，短促弹跳，命中时亮金。
- Best combo: 小尺寸固定位置，低对比显示。
- Input hints: 只在训练初期或暂停层显示，不常驻遮挡战斗区。
- Reset prompt: 低调固定在角落，不能抢过 combo 反馈。

### Interaction Visuals

按钮和选中态使用细边框、金色短线和小图标。不要用大面积发光卡片；训练场画面应保持主导。

## VFX Standards

### Hit Feedback

每次有效命中至少包含三层反馈：短 hitstop、木桩受击位移或倾斜、1 个高亮 hit spark。强命中可以增加屏幕微震和更长剑轨，但不能影响后续输入读取。

### Slash VFX

剑光使用 2-4 帧高亮像素弧线，核心 Sword White，边缘可带 Spark Gold 或 Air Cyan。地面斩以横向弧线为主，挑空斩以斜上弧线为主，空中斩以压缩的斜向弧线为主。

### Particles

粒子数量少、生命周期短、方向明确。命中火花向受击方向喷出，落地尘贴地扩散，浮空追击可使用少量青色残影表示高度和时间窗口。

### Screen Effects

屏幕震动必须可调，默认轻量。闪白只作用于命中对象或局部特效，不做全屏频闪。Web 版本要避免高频闪烁和过量半透明叠加。

## Asset Production Standards

### Naming Convention

Use lowercase snake_case:

`[category]_[subject]_[action_or_variant]_[size].[ext]`

Examples:
- `char_swordsman_slash_01.png`
- `dummy_wood_hit_air.png`
- `vfx_slash_launcher_32.png`
- `ui_combo_digit_gold.png`

### Texture Standards

| Category | Suggested Size | Format | Notes |
| -------- | -------------- | ------ | ----- |
| Player sprites | 64x64 to 128x128 per frame | PNG | Transparent background, nearest filtering |
| Dummy sprites | 64x64 to 128x128 per frame | PNG | Separate idle, hit, airborne, landing poses |
| Environment tiles | 16x16 or 32x32 tiles | PNG | Modular tileset, low contrast |
| VFX sprites | 32x32 to 128x128 | PNG | Short flipbooks, additive only when tested |
| UI icons | 16x16 to 64x64 | PNG or SVG source exported to PNG | Must remain readable at browser scale |

### Import Settings

- Pixel assets use nearest filtering.
- Disable mipmaps for pixel UI and sprites unless a specific export test proves otherwise.
- Keep source files separate from imported runtime assets.
- Use Godot resource UIDs and avoid hardcoded asset paths in gameplay scripts where possible.

### Animation Standards

- Target gameplay animation playback at 12 FPS style timing, with Godot controlling gameplay hit frames explicitly.
- Hitboxes must be authored from gameplay timing, not inferred from sword art alone.
- Every attack animation needs documented startup, active, recovery, and cancel/buffer windows in the relevant GDD.

## Accessibility

- Never use color alone for combat state, combo success, or dropped combo.
- UI text must remain readable in a 1280x720 browser viewport.
- Avoid full-screen flashes and rapid repeated flashes.
- Provide screen shake intensity as a tunable setting once options UI exists.
- Any touch fallback must use large, stable controls that do not cover the player, dummy, or hit effects.

## Style Prohibitions

- No busy parallax background behind the combat lane.
- No high-detail painterly sprites mixed with low-detail pixel placeholders.
- No UI panels that cover the core training space during active play.
- No blood/gore emphasis; this is a martial training demo, not a damage spectacle.
- No color palette dominated by only red/brown wood tones; cool stone and bright sword colors must balance the scene.
- No new visual feature unless it improves hit clarity, combo readability, or training flow.

## Reference Direction

| Reference | Medium | What We're Taking | What We Avoid |
| --------- | ------ | ----------------- | ------------- |
| 神剑伏魔录 | Arcade game | 横版武侠剑斗的招式节奏、短促命中感、舞台感 | 不复制角色规模、关卡复杂度或大量敌人 |
| Classic arcade beat-'em-ups | Games | 清楚的横向战斗平面、夸张受击姿态、快速重试 | 不做拥挤群战和满屏杂兵 |
| Fighting game training rooms | Games | Combo counter、输入练习、低干扰反馈布局 | 不使用现代科幻训练房视觉 |
| Traditional wuxia training hall | Film / cultural reference | 石砖、木桩、布帘、兵器架的低成本场景语言 | 不做写实复杂室内装饰 |
| Pixel action VFX | Pixel art technique | 少帧高亮剑轨、命中火花、残影 | 不做过度粒子化导致读招混乱 |

