# Systems Index: 三段破空

> **Status**: Draft
> **Created**: 2026-05-09
> **Last Updated**: 2026-05-09
> **Source Concept**: design/gdd/game-concept.md
> **Review Mode**: Solo
> **Director Gates**: TD-SYSTEM-BOUNDARY, PR-SCOPE, CD-SYSTEMS skipped — Solo mode, 2026-05-09

---

## Overview

三段破空需要的系统范围很窄：一个 Web 可玩的 Godot 2D 训练场，玩家用剑士在单个木桩上验证“地面三连 → 挑空 → 空中追击 → 收尾”的手感。系统设计优先服务四个支柱：刀刀有重量、连段短而完整、木桩也是表演对象、训练场优先。MVP 不做关卡、敌人 AI、成长、装备或复杂资源，只设计能支撑移动、攻击、命中反馈、木桩状态、combo 记录和快速重试的最小系统。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input & Control Mapping | Core | MVP | Designed | design/gdd/input-control-mapping.md | — |
| 2 | Player Movement Controller | Core | MVP | Designed | design/gdd/player-movement-controller.md | Input & Control Mapping |
| 3 | Combat State Machine | Gameplay | MVP | Designed | design/gdd/combat-state-machine.md | Input & Control Mapping, Player Movement Controller |
| 4 | Attack Data & Timing | Gameplay | MVP | Designed | design/gdd/attack-data-timing.md | Combat State Machine |
| 5 | Hit Detection & Hit Resolution | Gameplay | MVP | Designed | design/gdd/hit-detection-hit-resolution.md | Combat State Machine, Attack Data & Timing |
| 6 | Training Dummy State System | Gameplay | MVP | Not Started | — | Hit Detection & Hit Resolution |
| 7 | Launch & Air Juggle System | Gameplay | MVP | Not Started | — | Training Dummy State System, Attack Data & Timing |
| 8 | Hit Feedback System | Presentation | MVP | Not Started | — | Hit Detection & Hit Resolution, Training Dummy State System |
| 9 | Combo Counter & Training Metrics | UI | MVP | Not Started | — | Hit Detection & Hit Resolution, Launch & Air Juggle System |
| 10 | Training Room Reset Flow | Core | MVP | Not Started | — | Player Movement Controller, Training Dummy State System, Combo Counter & Training Metrics |
| 11 | Camera & Screen Shake | Presentation | MVP | Not Started | — | Hit Feedback System, Player Movement Controller |
| 12 | Pixel Art Rendering & Import Standards | Core | Vertical Slice | Not Started | design/art/art-bible.md | — |
| 13 | Slash VFX & Hit Spark Assets | Presentation | Vertical Slice | Not Started | — | Hit Feedback System, Pixel Art Rendering & Import Standards |
| 14 | Training HUD Visual Pass | UI | Vertical Slice | Not Started | — | Combo Counter & Training Metrics, design/art/art-bible.md |
| 15 | Basic SFX Playback | Audio | Vertical Slice | Not Started | — | Hit Detection & Hit Resolution, Hit Feedback System |
| 16 | Web Export & Browser Performance | Meta | Vertical Slice | Not Started | — | Input & Control Mapping, Pixel Art Rendering & Import Standards |
| 17 | Tuning Sandbox Parameters | Core | Vertical Slice | Not Started | — | Attack Data & Timing, Hit Feedback System, Launch & Air Juggle System |
| 18 | Accessibility & Comfort Options | Meta | Alpha | Not Started | — | Camera & Screen Shake, Training HUD Visual Pass, Basic SFX Playback |
| 19 | Playtest Capture & Evaluation | Meta | Alpha | Not Started | — | Combo Counter & Training Metrics, Web Export & Browser Performance |
| 20 | Expanded Enemy / Stage Prototype | Gameplay | Full Vision | Not Started | — | MVP combat systems approved |

---

## Categories

| Category | Description | Systems Used Here |
|----------|-------------|-------------------|
| **Core** | Foundation systems everything depends on | Input, movement, reset flow, rendering/import standards, tuning parameters |
| **Gameplay** | The systems that make the game fun | Combat state machine, attack timing, hit detection, dummy states, launch/juggle |
| **Presentation** | Feedback systems that make hits feel heavy | Hit feedback, camera shake, slash VFX, hit sparks |
| **UI** | Player-facing training information | Combo counter, metrics, training HUD |
| **Audio** | Sound systems that support impact clarity | Basic SFX playback |
| **Meta** | Platform, testing, comfort, and validation support | Web export, accessibility options, playtest capture |

Progression, economy, persistence, and narrative categories are intentionally excluded from MVP scope.

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required to test whether one short combo feels good on one dummy | First playable prototype | Design FIRST |
| **Vertical Slice** | Presentation and browser polish needed for a shareable demo | Web demo / vertical slice | Design SECOND |
| **Alpha** | Validation and comfort features after the core feel works | Playtest-ready build | Design THIRD |
| **Full Vision** | Scope expansion only if the training demo proves the hypothesis | Future demo | Design only after MVP validation |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Input & Control Mapping** — every action starts here; Web keyboard response is a core risk.
2. **Pixel Art Rendering & Import Standards** — constrains assets and visual clarity for Godot/Web.

### Core Layer (depends on foundation)

1. **Player Movement Controller** — depends on Input & Control Mapping.
2. **Combat State Machine** — depends on Input & Control Mapping and Player Movement Controller.
3. **Attack Data & Timing** — depends on Combat State Machine.
4. **Training Room Reset Flow** — depends on player, dummy, and metrics once those exist.
5. **Tuning Sandbox Parameters** — depends on timing, feedback, and juggle variables being defined.

### Feature Layer (depends on core)

1. **Hit Detection & Hit Resolution** — depends on Combat State Machine and Attack Data & Timing.
2. **Training Dummy State System** — depends on Hit Detection & Hit Resolution.
3. **Launch & Air Juggle System** — depends on Training Dummy State System and Attack Data & Timing.

### Presentation Layer (depends on features)

1. **Hit Feedback System** — depends on Hit Detection & Hit Resolution and Training Dummy State System.
2. **Camera & Screen Shake** — depends on Hit Feedback System and Player Movement Controller.
3. **Slash VFX & Hit Spark Assets** — depends on Hit Feedback System and Pixel Art Rendering & Import Standards.
4. **Basic SFX Playback** — depends on Hit Detection & Hit Resolution and Hit Feedback System.
5. **Training HUD Visual Pass** — depends on Combo Counter & Training Metrics and the art bible.

### Polish / Validation Layer (depends on everything)

1. **Combo Counter & Training Metrics** — wraps hit and juggle results for player feedback; designed after hit resolution contracts are clear.
2. **Web Export & Browser Performance** — depends on input and rendering constraints.
3. **Accessibility & Comfort Options** — depends on camera, HUD, and audio decisions.
4. **Playtest Capture & Evaluation** — depends on metrics and browser build.
5. **Expanded Enemy / Stage Prototype** — blocked until MVP combat is validated.

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Input & Control Mapping | MVP | Foundation | game-designer, godot-specialist | S |
| 2 | Player Movement Controller | MVP | Core | game-designer, gameplay-programmer | M |
| 3 | Combat State Machine | MVP | Core | systems-designer, gameplay-programmer | L |
| 4 | Attack Data & Timing | MVP | Core | systems-designer, gameplay-programmer | M |
| 5 | Hit Detection & Hit Resolution | MVP | Feature | gameplay-programmer, godot-gdscript-specialist | L |
| 6 | Training Dummy State System | MVP | Feature | game-designer, gameplay-programmer | M |
| 7 | Launch & Air Juggle System | MVP | Feature | systems-designer, gameplay-programmer | L |
| 8 | Hit Feedback System | MVP | Presentation | technical-artist, gameplay-programmer | L |
| 9 | Combo Counter & Training Metrics | MVP | Polish / UI | ux-designer, ui-programmer | M |
| 10 | Training Room Reset Flow | MVP | Core | game-designer, gameplay-programmer | S |
| 11 | Camera & Screen Shake | MVP | Presentation | technical-artist, godot-specialist | S |
| 12 | Pixel Art Rendering & Import Standards | Vertical Slice | Foundation | art-director, technical-artist | S |
| 13 | Slash VFX & Hit Spark Assets | Vertical Slice | Presentation | technical-artist, art-director | M |
| 14 | Training HUD Visual Pass | Vertical Slice | Presentation | ux-designer, art-director | M |
| 15 | Basic SFX Playback | Vertical Slice | Presentation | sound-designer, godot-specialist | S |
| 16 | Web Export & Browser Performance | Vertical Slice | Polish / Validation | devops-engineer, performance-analyst | M |
| 17 | Tuning Sandbox Parameters | Vertical Slice | Core | systems-designer, gameplay-programmer | M |
| 18 | Accessibility & Comfort Options | Alpha | Polish | accessibility-specialist, ux-designer | M |
| 19 | Playtest Capture & Evaluation | Alpha | Validation | producer, qa-lead | M |
| 20 | Expanded Enemy / Stage Prototype | Full Vision | Feature | game-designer, gameplay-programmer | L |

Effort estimates: S = 1 focused design session, M = 2-3 sessions, L = 4+ sessions.

---

## Circular Dependencies

- **None found.**

Potential coupling to watch: Hit Feedback, Camera Shake, Combo Metrics, and Hit Resolution all want to react to the same hit events. Resolve this with a clear hit event contract in the Hit Detection & Hit Resolution GDD, then let presentation/UI systems subscribe to that contract.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Combat State Machine | Design / Technical | If startup, active, recovery, and buffer windows are vague, the combo will feel inconsistent. | Design explicit timing tables before implementation; prototype with debug overlays. |
| Hit Detection & Hit Resolution | Technical | Hitstop and collision timing can desync from animation or input, especially in Web builds. | Keep hit events deterministic and log each hit frame during prototype testing. |
| Launch & Air Juggle System | Design / Technical | Pure physics may produce unstable float arcs; over-scripted motion may feel fake. | Use controllable state logic with tunable gravity, launch velocity, hit decay, and landing rules. |
| Hit Feedback System | Design | The whole concept fails if hits lack weight or obscure readability. | Prototype hitstop, flash, shake, VFX, and dummy displacement as tunable parameters early. |
| Web Export & Browser Performance | Technical | Browser latency or rendering settings may make the game feel less responsive than editor testing. | Test exported Web builds early, not after the prototype is complete. |

---

## Deferred / Out of Scope

- Enemy AI
- Full stages
- Boss fights
- Equipment, upgrades, skill trees
- Multiple player characters
- Narrative systems
- Economy or inventory
- Multiplayer / networking

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 20 |
| Design docs started | 5 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 5/11 |
| Vertical Slice systems designed | 0/6 |

---

## Next Steps

- [ ] Review and approve this systems enumeration.
- [x] Design MVP-tier systems first, starting with `/design-system input-control-mapping`.
- [x] Next MVP GDD: `/design-system player-movement-controller`.
- [x] Next MVP GDD: `/design-system combat-state-machine`.
- [x] Next MVP GDD: `/design-system attack-data-timing`.
- [x] Next MVP GDD: `/design-system hit-detection-hit-resolution`.
- [ ] Next MVP GDD: `/design-system training-dummy-state-system`.
- [ ] Run `/design-review` on each completed GDD.
- [ ] Prototype the highest-risk system early with `/prototype core-combat-feel`.
- [ ] Run `/gate-check pre-production` when MVP systems are designed.
