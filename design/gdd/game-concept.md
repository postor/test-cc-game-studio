# Game Concept: 三段破空

*Created: 2026-05-09*
*Status: Draft*

---

## Elevator Pitch

一个 Godot Web 横版 2D 像素动作训练场 demo，玩家操控剑士练习“地面三连 → 挑空 → 空中追击 → 收尾”的短连段。目标不是完整关卡，而是验证重打击、浮空追击、命中反馈是否足够爽。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 横版 2D 动作训练场 / Beat-'em-up combat prototype |
| **Platform** | Web / Browser |
| **Target Audience** | 喜欢街机动作、连段练习、打击反馈的动作玩家 |
| **Player Count** | Single-player |
| **Session Length** | 5–15 分钟 |
| **Monetization** | None yet |
| **Estimated Scope** | Small (2–6 weeks, solo first-game demo) |
| **Comparable Titles** | 神剑伏魔录、街机清版动作、动作游戏训练场模式 |

---

## Core Fantasy

玩家像街机武侠高手一样，用短而有力的剑招把木桩打进硬直、挑空并追击。核心幻想不是探索世界或刷装备，而是“每一刀都重，每一次命中都清楚，每一次完整连段都像自己变强了”。

---

## Unique Hook

像《神剑伏魔录》的横版剑斗打击感，AND ALSO 把范围压到一个木桩训练场，只打磨一条完整连段：地面三连 → 挑空 → 空中追击 → 收尾。

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 1 | 命中停顿、屏幕震动、闪白、刀光、受击位移、清晰像素特效 |
| **Challenge** | 2 | 固定连段练习、浮空时机、输入节奏、最高 combo |
| **Fantasy** | 3 | 复古武侠剑士训练感，短连段像街机高手表演 |
| **Expression** | 4 | 玩家通过连段稳定度和节奏表达技巧 |
| **Submission** | 5 | 低压力反复训练，快速重试 |
| **Narrative** | N/A | 不做剧情 |
| **Fellowship** | N/A | 不做社交 |
| **Discovery** | N/A | 不做探索 |

### Key Dynamics (Emergent player behaviors)

玩家会反复尝试把木桩稳定打入浮空，调整输入节奏，追求更完整、更顺、更重的连段表现。成功标准是玩家愿意在一个训练场里重复攻击木桩 5 分钟，只为了让一套连段更稳定、更爽。

### Core Mechanics (Systems we build)

1. 横版移动与跳跃。
2. 剑士攻击状态机：轻斩 1、轻斩 2、轻斩 3、挑空、空中斩。
3. 木桩受击状态：硬直、击退、浮空、落地、重置。
4. 打击反馈系统：hitstop、screen shake、hit flash、slash VFX、hit spark。
5. Combo counter 与训练场重置。

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | 玩家可自由练习、重置、尝试节奏，但 demo 不强调分支选择 | Minimal |
| **Competence** | 玩家从乱按到稳定打出完整连段，能清楚感到技术成长 | Core |
| **Relatedness** | demo 不做角色关系、NPC、社交 | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — 通过完整连段、最高 combo、稳定执行获得目标感。
- [ ] **Explorers** — 不作为主要目标；没有探索内容。
- [ ] **Socializers** — 不作为目标；单人训练场。
- [x] **Killers/Competitors** — 轻量吸引喜欢动作掌握和分数挑战的玩家，但不做 PvP。

### Flow State Design

- **Onboarding curve**: 玩家先学移动和轻斩三连，再学挑空和空中追击。
- **Difficulty scaling**: 第一版不靠数值变难，靠连段稳定度、输入窗口和浮空时机形成技巧曲线。
- **Feedback clarity**: combo counter、木桩浮空轨迹、命中闪白、顿帧和震屏让玩家知道是否打中了、连上了。
- **Recovery from failure**: 失败不惩罚；木桩落地后可立刻重试，重置键立即恢复训练状态。

---

## Core Loop

### Moment-to-Moment (30 seconds)

玩家接近木桩，打出轻斩 1、轻斩 2、轻斩 3，确认命中反馈后使用挑空把木桩打起，再用跳跃或空中斩追击，最后让木桩落地并重置下一轮。每次命中都必须有短暂停顿、闪白、击退和音画反馈。

### Short-Term (5-15 minutes)

玩家反复练习一条固定连段，目标从“能打出来”变成“打得稳定、打得满、打得重”。训练目标可以是最高 combo、最大伤害、最长浮空时间或完整连段成功率。

### Session-Level (30-120 minutes)

本 demo 的实际 session 预期是 5–15 分钟，不追求 30–120 分钟内容量。自然停点是玩家成功打出完整连段，或刷新最高 combo 后退出。

### Long-Term Progression

Demo 内不做角色升级、装备、技能树。长期成长来自玩家对输入节奏、浮空高度、命中窗口的掌握。若未来扩展，可增加新招式、敌人、短关卡和评分系统。

### Retention Hooks

- **Curiosity**: 暂不依赖内容发现。
- **Investment**: 暂不依赖永久进度。
- **Social**: 暂不做社交。
- **Mastery**: 更稳定连段、更高 combo、更顺的浮空追击。

---

## Game Pillars

### Pillar 1: 刀刀有重量

每次命中都必须通过顿帧、震屏、闪白、击退体现“打中了”。

*Design test*: 如果在“更快响应”和“更强命中感”之间取舍，优先保留命中重量。

### Pillar 2: 连段短而完整

Demo 只服务一条核心连段：地面三连 → 挑空 → 空中追击 → 收尾。

*Design test*: 如果一个新招式不能增强这条连段，就不加入。

### Pillar 3: 木桩也是表演对象

木桩不是静态血条，必须有明确受击、浮空、落地、重置状态。

*Design test*: 如果打击反馈只发生在玩家身上，而木桩不“演”，就不合格。

### Pillar 4: 训练场优先

不做关卡、不做剧情、不做复杂敌人，只验证手感。

*Design test*: 如果功能不能帮助玩家练连段或感受打击，就延期。

### Anti-Pillars (What This Game Is NOT)

- **NOT 完整关卡**: 完整关卡会稀释打击感打磨时间。
- **NOT 敌人 AI**: 第一版目标是命中反馈，不是战斗策略。
- **NOT 装备/升级**: Demo 的成长来自玩家操作，不来自数值堆叠。
- **NOT 大量招式**: 5 个动作足够验证核心手感。
- **NOT 复杂资源条**: 资源管理会干扰第一版连段验证。

---

## Visual Identity Anchor

**Direction**: Retro wuxia pixel

**One-line visual rule**: 复古武侠像素场景保持克制，刀光、命中闪白和打击特效必须最亮、最清楚。

**Supporting visual principles**:

1. **暗场亮刀** — 背景用低饱和石砖、木桩、布帘；剑光和命中特效使用高亮色。  
   *Design test*: 如果背景抢过刀光，降低背景对比度。
2. **读招优先** — 玩家姿势、剑轨迹、木桩受击方向必须一眼看清。  
   *Design test*: 如果美术细节影响判断命中时机，删细节。
3. **像素少而有劲** — 少帧动画可以接受，但关键帧、受击帧、残影必须有冲击力。  
   *Design test*: 如果增加帧数不增强打击感，就不优先做。

**Color philosophy**: 背景偏暗、低饱和；角色和木桩中等对比；刀光、hit spark、闪白为最高亮度层。

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| 神剑伏魔录 | 横版武侠动作、剑斗打击感、街机味 | 不复刻完整关卡和角色规模，只做训练场手感验证 | 明确打击感参考方向 |
| 街机清版动作 | 短招式、命中反馈、节奏清楚 | 不做群敌清场，先做单木桩 | 控制范围，保护核心手感 |
| 动作游戏训练场 | 重复练习、combo feedback、快速重试 | 用极简内容验证核心循环 | 符合几周 demo 目标 |

**Non-game inspirations**: 武侠练功房、木桩训练、石砖场地、布帘、短促鼓点和金属剑击声。

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16–40 |
| **Gaming experience** | Mid-core action players; also suitable for beginners learning action feel |
| **Time availability** | 5–15 分钟短 session |
| **Platform preference** | Browser demo, PC keyboard first |
| **Current games they play** | 横版动作、街机清版、动作训练场类内容 |
| **What they're looking for** | 少内容但高反馈的剑斗连段手感 |
| **What would turn them away** | 没有关卡、剧情、成长系统；只想练手感的人才会喜欢 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot，适合 2D 像素、快速原型和 Web 导出；后续仍需 `/setup-engine` 正式配置版本和标准 |
| **Key Technical Challenges** | 命中停顿不破坏输入手感；浮空物理可控；Web input latency；震屏和像素画面清晰度 |
| **Art Style** | Retro wuxia pixel |
| **Art Pipeline Complexity** | Low to Medium：先用占位块和简单像素特效，后续替换角色帧 |
| **Audio Needs** | Moderate：剑击、命中、挑空、落地、收刀音效会显著影响打击感 |
| **Networking** | None |
| **Content Volume** | 1 room, 1 player, 1 dummy, 5 attacks, 5–15 minutes of practice |
| **Procedural Systems** | None |

---

## Risks and Open Questions

### Design Risks

- 打击反馈不足会让 demo 立刻失去吸引力。
- 连段太短可能缺少深度；连段太复杂又会超出首作 scope。
- 固定木桩训练可能只吸引小众动作手感玩家。

### Technical Risks

- Hitstop、screen shake、input buffering、animation timing 需要精调。
- Web 导出可能带来输入延迟或性能差异。
- 浮空和击退若用纯物理可能不稳定，需要可控状态逻辑。

### Market Risks

- 训练场 demo 不是完整商品，市场验证意义有限。
- 复古横版动作有明确受众，但 demo 内容太少时难以传播。

### Scope Risks

- 很容易想加敌人、关卡、Boss、更多招式，导致核心手感没打磨完。
- 像素美术如果追求完整角色动画，会拉长周期。

### Open Questions

- 命中停顿多长最爽？通过可调参数和手感测试回答。
- 浮空高度、重力、击退速度如何设定？通过训练场调参回答。
- 是否需要输入缓冲或取消窗口？通过玩家能否稳定连段回答。
- Web 版本是否够跟手？通过浏览器导出测试回答。

---

## MVP Definition

**Core hypothesis**: 玩家会愿意在一个木桩训练场中反复练习 5 分钟以上，只因为“地面三连 → 挑空 → 空中追击”的重打击反馈足够爽。

**Required for MVP**:
1. 玩家可左右移动、跳跃、攻击。
2. 轻斩三连可稳定衔接。
3. 挑空可将木桩打入可控浮空状态。
4. 空中斩可命中浮空木桩。
5. 木桩有受击、浮空、落地、重置状态。
6. 命中反馈包含 hitstop、screen shake、flash、knockback。
7. Combo counter 显示连击结果。

**Explicitly NOT in MVP**:
- 完整关卡。
- 敌人 AI。
- Boss。
- 装备、升级、技能树。
- 多角色。
- 复杂资源系统。

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 training room, 1 player, 1 dummy | Movement, ground combo, launcher, air slash, hit feedback, combo counter | 2–3 weeks |
| **Vertical Slice** | Same room with improved presentation | Pixel placeholders, sword slash VFX, hit sparks, basic SFX, Web export | 4–6 weeks |
| **Alpha** | 1 short stage, 2 enemy types | Basic enemy behavior, score/rank, improved animation | 2–3 months |
| **Full Vision** | Short retro wuxia action demo | Stage flow, mini-boss, more moves, polish pass | 3–6 months, solo |

---

## Next Steps

- [x] Run `/setup-engine` to configure the engine and populate version-aware reference docs.
- [x] Run `/art-bible` to create the visual identity specification — do this BEFORE writing GDDs. The art bible gates asset production and shapes technical architecture decisions (rendering, VFX, UI systems).
- [ ] Use `/design-review design/gdd/game-concept.md` to validate concept completeness before going downstream.
- [ ] Discuss vision with the `creative-director` agent for pillar refinement.
- [x] Decompose the concept into individual systems with `/map-systems` — maps dependencies, assigns priorities, and creates the systems index.
- [ ] Author per-system GDDs with `/design-system` — guided, section-by-section GDD writing for each system identified in step 4.
- [ ] Plan the technical architecture with `/create-architecture` — produces the master architecture blueprint and Required ADR list.
- [ ] Record key architectural decisions with `/architecture-decision (×N)` — write one ADR per decision in the Required ADR list from `/create-architecture`.
- [ ] Validate readiness to advance with `/gate-check` — phase gate before committing to production.
- [ ] Prototype the riskiest system with `/prototype core-combat-feel` — validate the core loop before full implementation.
- [ ] Run `/playtest-report` after the prototype to validate the core hypothesis.
- [ ] If validated, plan the first sprint with `/sprint-plan new`.
