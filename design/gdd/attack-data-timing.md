# Attack Data & Timing

> **Status**: Designed
> **Author**: Codex
> **Last Updated**: 2026-05-09
> **Last Verified**: 2026-05-09
> **Implements Pillar**: 刀刀有重量; 连段短而完整
> **Creative Director Review (CD-GDD-ALIGN)**: Skipped — Solo mode, 2026-05-09

## Summary

Attack Data & Timing defines the frame data, chain windows, input buffers, movement locks, facing locks, and per-attack tuning values for the MVP sword route. It gives Combat State Machine concrete timing values while leaving hitbox geometry and hit outcomes to Hit Detection & Hit Resolution.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Combat State Machine`

## Overview

This system turns the combat state names into playable timing data. Each attack has startup, active, recovery, chain window, movement lock, facing lock, and response targets measured at 60 FPS. The default values are intentionally prototype-friendly: fast enough for keyboard play in browser, structured enough to make Slash 3 and Launcher feel heavier, and explicit enough that hitstop, input buffering, and animation can be tuned without rewriting state logic.

## Player Fantasy

The player should feel a steady training rhythm: quick first cut, confident second cut, heavier third cut, committed upward launcher, then a short air slash to finish. Timing should reward clean presses while staying forgiving enough that a new player can complete the basic route after a few attempts. The sword fighter should never feel like they are waiting for the game to recognize input.

## Detailed Design

### Core Rules

1. All attack timing is authored in frames at 60 FPS.
2. Attack timings must also be expressible in seconds for implementation.
3. Combat State Machine owns state transitions; this system owns the timing values those transitions read.
4. Hit Detection & Hit Resolution owns hitbox shape, collision, and hit result.
5. Animation art must align to timing data, not the other way around.
6. Active frames identify when an attack can produce a hit event.
7. Startup frames must begin with visible feedback within the input response budget.
8. Recovery frames define commitment and chain opportunity.
9. Chain windows freeze during hitstop.
10. Input buffers collect valid next-action inputs shortly before a chain window opens.
11. Buffering is limited to the next legal route action, not arbitrary action storage.
12. Holding `light_attack` does not repeatedly advance the combo.
13. Movement and facing locks are data-driven per attack phase.
14. Attack data must support debug display of current frame, phase, active window, and chain window.
15. All default numbers are first-pass prototype values and must be tuned through playtesting.

### Attack Frame Data

At 60 FPS, 1 frame is approximately 16.67 ms.

| Attack | Startup | Active | Recovery | Total | Chain Window | Buffer Before Window | Movement Lock | Facing Lock | Route Step |
|--------|---------|--------|----------|-------|--------------|----------------------|---------------|-------------|------------|
| Light Slash 1 | 4f | 3f | 10f | 17f | Recovery f2-f8 | 5f | Soft through startup/active; partial recovery | Full attack | 1 |
| Light Slash 2 | 5f | 3f | 11f | 19f | Recovery f2-f9 | 5f | Soft through startup/active; partial recovery | Full attack | 2 |
| Light Slash 3 | 7f | 4f | 14f | 25f | Recovery f3-f11 | 6f | Harder through startup/active; partial recovery | Full attack | 3 |
| Launcher | 8f | 4f | 16f | 28f | None for ground route; air chase handled later | 4f for optional jump/air setup | Hard startup/active; partial recovery | Full attack | 4 |
| Air Slash | 5f | 4f | 14f | 23f | None in MVP | 0f | Air drift damped | Full attack | 5 |

### Phase Definitions

| Phase | Includes | Can Hit? | Can Accept Chain? | Can Accept Buffer? |
|-------|----------|----------|-------------------|--------------------|
| Startup | Frames before active | No | No | Yes, if next action has a buffer definition and current route step allows it |
| Active | Frames where attack may hit | Yes | No | Yes, for upcoming chain if buffer window overlaps |
| Recovery before chain window | Recovery frames before chain opens | No | No | Yes |
| Recovery chain window | Recovery frames listed in attack data | No | Yes | Yes |
| Recovery after chain window | Recovery frames after chain closes | No | No | No |

### Chain Rules

1. `Light Slash 1` chains to `Light Slash 2` through `chain_light_1_to_2`.
2. `Light Slash 2` chains to `Light Slash 3` through `chain_light_2_to_3`.
3. `Light Slash 3` chains to `Launcher` through `chain_light_3_to_launcher`.
4. Neutral `Launcher` does not require a chain window if Combat State Machine allows neutral launcher.
5. `Air Slash` is entered from airborne state and does not chain further in MVP.
6. A buffered valid input is consumed on the first frame of its legal chain window.
7. If multiple valid buffered inputs exist, route-priority input wins:
   - Slash 1 route expects `light_attack`;
   - Slash 2 route expects `light_attack`;
   - Slash 3 route expects `launcher`.
8. Invalid inputs are not buffered.

### Buffer Rules

| Situation | Buffer Behavior |
|-----------|-----------------|
| Player presses next legal route input shortly before chain window | Store the input for the listed buffer duration. |
| Chain window opens while valid input is buffered | Consume the input and transition immediately. |
| Buffer expires before chain window opens | Drop the buffered input. |
| Player holds the input across the window | Count only the original press event; do not repeat. |
| Player presses the wrong action | Ignore for route chaining; optional debug log only. |
| Hitstop begins while buffer is active | Buffer timer freezes with combat timer. |
| Pause begins while buffer is active | Buffer timer freezes; input is not consumed until resume. |
| Reset begins while buffer is active | Clear buffer. |

### Movement and Facing Lock Data

| Attack | Startup Movement | Active Movement | Recovery Movement | Facing |
|--------|------------------|-----------------|-------------------|--------|
| Light Slash 1 | Soft lock: retain 35% x velocity | Soft lock: retain 25% x velocity | Partial release: retain 60% x control | Locked until recovery ends or chain starts |
| Light Slash 2 | Soft lock: retain 30% x velocity | Soft lock: retain 20% x velocity | Partial release: retain 55% x control | Locked until recovery ends or chain starts |
| Light Slash 3 | Harder lock: retain 15% x velocity | Harder lock: retain 10% x velocity | Partial release: retain 40% x control | Locked until recovery ends or launcher starts |
| Launcher | Hard lock: x velocity 0 | Hard lock: x velocity 0 | Partial release: retain 35% x control | Locked until recovery ends |
| Air Slash | Air drift damped: retain 60% x velocity | Air drift damped: retain 45% x velocity | Air drift returns to 70% control | Locked until recovery ends or landing resolves |

### Interactions with Other Systems

| System | Data Flow | Responsibility Split |
|--------|-----------|----------------------|
| Combat State Machine | Reads attack phase durations, chain windows, buffers, locks | Combat owns transition rules; timing owns frame values. |
| Input & Control Mapping | Provides press events and response budgets | Input owns action events; timing owns buffer duration after press. |
| Player Movement Controller | Applies lock percentages and facing locks | Movement owns velocity; timing owns per-phase modifiers. |
| Hit Detection & Hit Resolution | Reads active frames and attack IDs | Hit detection owns hitbox geometry and hit results. |
| Launch & Air Juggle System | Reads launcher timing and air slash windows | Juggle owns dummy trajectory; timing owns when attack events occur. |
| Hit Feedback System | Freezes timers during hitstop | Feedback owns hitstop length; timing owns freeze behavior. |
| Combo Counter & Training Metrics | Observes route step timing and drops | Metrics owns display and scoring. |

## Formulas

### Frame to Seconds

The `frame_seconds` formula is defined as:

`frame_seconds = frame_count / target_fps`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `frame_count` | `F` | int | 0-120 | Number of authored frames. |
| `target_fps` | `R` | int | 60 | Target gameplay frame rate. |

**Output Range:** 0.0 to 2.0 seconds for normal attack timings.  
**Example:** `5 / 60 = 0.0833` seconds.

### Attack Total Frames

The `attack_total_frames` formula is defined as:

`attack_total_frames = startup_frames + active_frames + recovery_frames`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `startup_frames` | `S` | int | 1-20 | Frames before hit can occur. |
| `active_frames` | `A` | int | 1-12 | Frames where hit detection may be active. |
| `recovery_frames` | `R` | int | 1-40 | Frames before returning to neutral or chained state. |

**Output Range:** 3 to 72 frames under normal tuning.  
**Example:** Light Slash 1 uses `4 + 3 + 10 = 17` total frames.

### Chain Window Duration

The `chain_window_duration_frames` formula is defined as:

`chain_window_duration_frames = chain_window_end_frame - chain_window_start_frame + 1`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `chain_window_start_frame` | `Ws` | int | 1-40 | First recovery-relative frame that accepts chain input. |
| `chain_window_end_frame` | `We` | int | 1-40 | Last recovery-relative frame that accepts chain input. |

**Output Range:** 1 to 40 frames.  
**Example:** Light Slash 1 recovery f2-f8 has duration `8 - 2 + 1 = 7` frames.

### Buffered Input Validity

The `buffered_input_valid` formula is defined as:

`buffered_input_valid = input_age_frames <= buffer_duration_frames && buffered_action == expected_next_action`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `input_age_frames` | `Ia` | int | 0-60 | Frames since input was pressed, excluding frozen hitstop/pause frames. |
| `buffer_duration_frames` | `Bd` | int | 0-12 | Allowed buffer duration for this action. |
| `buffered_action` | `Ba` | enum | action names | Action stored in buffer. |
| `expected_next_action` | `Ea` | enum | action names | Legal next action for current route step. |

**Output Range:** Boolean.  
**Example:** If `input_age_frames = 3`, `buffer_duration_frames = 5`, and both actions are `light_attack`, buffer is valid.

### Movement Lock Velocity

The `locked_velocity_x` formula is defined as:

`locked_velocity_x = current_velocity_x * movement_retention_ratio`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_velocity_x` | `Vx` | float | -1000 to 1000 px/s | Movement velocity before lock modifier. |
| `movement_retention_ratio` | `K` | float | 0.0-1.0 | Percentage of velocity/control retained during the attack phase. |

**Output Range:** -1000 to 1000 px/s, usually reduced toward 0.  
**Example:** `Vx = 220`, `K = 0.25`, output is 55 px/s during a soft active lock.

### Hitstop-Aware Timer

The `timing_timer_advance` formula is defined as:

`timing_timer_advance = 1 frame if gameplay_timer_active else 0 frames`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `gameplay_timer_active` | `G` | bool | true/false | False during hitstop, pause, and reset suspension. |

**Output Range:** 0 or 1 authored frame per 60 FPS tick.  
**Example:** During a 4-frame hitstop, attack phase timers and chain buffers advance by 0 frames for 4 ticks.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player presses next chain input 1-5 frames before chain window | Buffer stores and consumes it on the first legal chain frame. | Makes rhythm fair without auto-combo. |
| Player presses next chain input too early | Buffer expires; no chain occurs unless pressed again. | Prevents mashing from bypassing timing. |
| Player holds `light_attack` through a chain window | Only the initial press can buffer; hold does not repeat. | Matches Input GDD. |
| Hitstop begins during active frames | Active frame timer freezes and resumes after hitstop. | Hitstop should not shorten hit windows. |
| Hitstop begins during chain window | Chain and buffer timers freeze. | Prevents hitstop from eating timing. |
| Pause begins during any attack phase | All timing and buffers freeze. | Pause should be deterministic. |
| Reset begins during any attack phase | Attack timing and buffers clear. | Reset overrides combat. |
| Player lands during Air Slash Startup or Active | Air Slash timing continues by default; landing recovery is not inserted by this system. | Matches Combat State Machine provisional rule. |
| Frame rate hitches in Web export | Implementation should use authored frame progression or clamped delta so attack phases do not skip multiple critical windows. | Browser builds can stutter. |
| Animation length differs from frame data | Frame data wins; animation must be retimed or event markers adjusted. | Gameplay timing is source of truth. |
| Hitbox art suggests a longer slash than active frames | Hit detection follows active frames, not full VFX duration. | Preserves consistency. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Combat State Machine | This depends on Combat State Machine | Supplies timing data for named states and transitions. |
| Input & Control Mapping | This depends on Input | Receives press events and must respect no-hold-repeat behavior. |
| Player Movement Controller | This depends on Movement | Sends movement retention and facing lock data. |
| Hit Detection & Hit Resolution | Depends on this | Reads active frames and attack IDs to enable hit checks. |
| Launch & Air Juggle System | Depends on this | Reads launcher and air slash timing to tune juggle windows. |
| Hit Feedback System | Depends on this | Freezes timers and may vary hitstop by attack. |
| Combo Counter & Training Metrics | Depends on this | Uses route timing and drop events for metrics. |
| Slash VFX & Hit Spark Assets | Depends on this | Aligns VFX frame timing to startup/active/recovery. |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `light_1_startup_frames` | 4 | 2-8 | More readable but slower opener. | Snappier but may lose anticipation. |
| `light_1_active_frames` | 3 | 2-6 | Easier hit timing. | Stricter hit timing. |
| `light_1_recovery_frames` | 10 | 6-18 | More commitment. | Faster chain/return. |
| `light_2_startup_frames` | 5 | 3-9 | More rhythm separation. | Faster combo. |
| `light_2_recovery_frames` | 11 | 7-20 | More commitment. | More forgiving rapid chain. |
| `light_3_startup_frames` | 7 | 4-12 | Heavier third hit. | Less punctuation. |
| `light_3_recovery_frames` | 14 | 8-24 | More weight before launcher. | Faster launcher flow. |
| `launcher_startup_frames` | 8 | 5-14 | More readable upward strike. | Faster launch access. |
| `launcher_recovery_frames` | 16 | 8-28 | More commitment. | Faster chase setup. |
| `air_slash_startup_frames` | 5 | 3-10 | More readable air attack. | Easier chase hit. |
| `air_slash_recovery_frames` | 14 | 8-24 | More commitment after air hit. | Faster landing/next action. |
| `chain_buffer_frames_light` | 5 | 0-10 | More forgiving chaining. | Stricter timing. |
| `chain_buffer_frames_launcher` | 6 | 0-12 | Easier transition into launcher. | Requires more precise launcher input. |
| `movement_retention_light_active` | 0.25 | 0.0-0.6 | More drift during slashes. | More planted attacks. |
| `movement_retention_launcher_active` | 0.0 | 0.0-0.3 | Allows correction during launcher. | Stronger commitment. |
| `air_slash_drift_retention_active` | 0.45 | 0.2-0.8 | More air steering during slash. | More committed air slash. |

## Visual/Audio Requirements

Timing must align with visible attack poses and VFX. The art bible's “短动画也要有关键帧重量” rule is mandatory here.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Startup begins | Character changes pose within input response budget. | Swing prep sound optional. | High |
| Active frame begins | Sword slash VFX reaches hit area. | Swing or impact-ready accent. | High |
| Hit frame connects | VFX/hit spark triggered by Hit Feedback, not this system. | Hit SFX owned by feedback/audio. | High |
| Chain window open | Hidden in player build; debug overlay may show frame/window. | None. | Medium |
| Recovery begins | Character settles or follows through. | Optional cloth/weapon tail. | Medium |
| Route drops | No direct VFX in MVP; metrics/UI may display combo drop. | Optional UI sound later. | Low |

## Game Feel

### Feel Reference

The target timing is a short arcade weapon combo: the first two hits are quick and confidence-building, the third hit adds weight, and the launcher creates a deliberate “now go up” punctuation. It should not feel like a long fighting-game combo trial with strict one-frame links.

### Input Responsiveness

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|--------------------------|-------|
| Light Slash 1 | 50.0 ms | 3 frames | Visible startup must begin by frame 3. |
| Light Slash 2 | 50.0 ms | 3 frames | Buffered input may make it start immediately at chain window. |
| Light Slash 3 | 50.0 ms | 3 frames | Heavier but still responsive. |
| Launcher | 50.0 ms | 3 frames | Startup can be 8f, but pose response must appear early. |
| Air Slash | 50.0 ms | 3 frames | Must be usable during chase. |

### Animation Feel Targets

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| Light Slash 1 | 4 | 3 | 10 | Fast opener | Route entry. |
| Light Slash 2 | 5 | 3 | 11 | Rhythmic second beat | Distinct arc. |
| Light Slash 3 | 7 | 4 | 14 | Heavier punctuation | Sets launcher window. |
| Launcher | 8 | 4 | 16 | Committed upward break | Must read vertical. |
| Air Slash | 5 | 4 | 14 | Chase finisher | Must connect in air route. |

### Impact Moments

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Chain buffer forgiveness | 66.7-100 ms | Allows slightly early next input before window. | Yes |
| Active frame visibility | 50-66.7 ms | Sword VFX should overlap active frames. | Yes |
| Launcher commitment | 466.7 ms total default | Full launcher action has clear commitment. | Yes |
| Air slash commitment | 383.3 ms total default | Short air finisher, not repeatable in MVP. | Yes |

### Weight and Responsiveness Profile

- **Weight**: Light Slash 1 and 2 are quick; Slash 3 and Launcher are visibly heavier.
- **Player control**: Players can buffer intended next steps, but cannot cancel freely.
- **Snap quality**: Chain transitions should snap cleanly when the buffer is valid.
- **Acceleration model**: Attack timing is discrete frame data at 60 FPS.
- **Failure texture**: Failed chains should feel like early/late inputs, not random drops.

### Feel Acceptance Criteria

- [ ] A new player can complete `J, J, J, K` after learning the rhythm.
- [ ] Mashing `J` alone does not perform launcher.
- [ ] Pressing the next route input slightly early feels forgiving.
- [ ] Holding `J` does not auto-complete the ground chain.
- [ ] Launcher feels heavier than the light slashes but not sluggish.
- [ ] Air slash can be performed during a normal jump-chase window.

## UI Requirements

No player-facing UI is required for attack timing in MVP. Debug UI is strongly recommended during prototype tuning.

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Current attack name | Debug overlay | Per state change | Development build only. |
| Current phase and frame | Debug overlay | Per frame | Development build only. |
| Chain window status | Debug overlay | Per frame during recovery | Development build only. |
| Buffered input and age | Debug overlay | Per frame while buffered | Development build only. |
| Route step | Debug overlay or combo HUD later | On accepted action | Development first; player HUD later owned by metrics. |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|------------|-----------------------------|--------|
| Supplies timing for combat states | `design/gdd/combat-state-machine.md` | Named states, transitions, chain windows | Data dependency |
| Consumes press events and no-hold-repeat rule | `design/gdd/input-control-mapping.md` | `light_attack`, `launcher`, buffer ownership | Rule dependency |
| Sends movement/facing lock values | `design/gdd/player-movement-controller.md` | Movement lock and facing lock behavior | Data dependency |
| Defines active frames for hit checks | `design/gdd/hit-detection-hit-resolution.md` | Future hitbox active timing | Data dependency |
| Provides launcher and air slash timing | `design/gdd/launch-air-juggle-system.md` | Future launch/chase tuning | Data dependency |
| Timers freeze during hitstop | `design/gdd/hit-feedback-system.md` | Future hitstop behavior | Rule dependency |
| Debug/route progress may feed metrics | `design/gdd/combo-counter-training-metrics.md` | Future route and combo tracking | Data dependency |

## Acceptance Criteria

- [ ] **GIVEN** Light Slash 1 starts, **WHEN** 4 startup frames complete, **THEN** its active phase begins.
- [ ] **GIVEN** Light Slash 1 is in recovery frames 2-8, **WHEN** `light_attack` is pressed or buffered, **THEN** the state machine may transition to Light Slash 2.
- [ ] **GIVEN** Light Slash 2 is in recovery frames 2-9, **WHEN** `light_attack` is pressed or buffered, **THEN** the state machine may transition to Light Slash 3.
- [ ] **GIVEN** Light Slash 3 is in recovery frames 3-11, **WHEN** `launcher` is pressed or buffered, **THEN** the state machine may transition to Launcher.
- [ ] **GIVEN** a valid chain input is pressed 5 frames before its chain window, **WHEN** the window opens, **THEN** the buffered input is consumed.
- [ ] **GIVEN** a valid chain input is pressed earlier than its buffer duration, **WHEN** the chain window opens, **THEN** the input has expired and is not consumed.
- [ ] **GIVEN** `light_attack` is held from Light Slash 1 through recovery, **WHEN** the chain window opens, **THEN** no auto-repeat chain occurs unless a fresh press event was buffered.
- [ ] **GIVEN** hitstop begins during any attack phase, **WHEN** hitstop is active, **THEN** phase frame counters and buffer age do not advance.
- [ ] **GIVEN** pause begins during any attack phase, **WHEN** pause is active, **THEN** phase frame counters and buffer age do not advance.
- [ ] **GIVEN** reset begins during any attack phase, **WHEN** reset is active, **THEN** all attack timing and buffers clear.
- [ ] **GIVEN** Launcher enters Active, **WHEN** active frames are running, **THEN** Hit Detection can query launcher attack identity for exactly 4 authored frames excluding hitstop.
- [ ] **GIVEN** Air Slash enters Active, **WHEN** active frames are running, **THEN** Hit Detection can query air slash attack identity for exactly 4 authored frames excluding hitstop.
- [ ] Performance: timing update and buffer checks should be negligible within the 16.6 ms frame budget.
- [ ] No implementation may hardcode frame data in state transition logic; frame data must come from attack data resources or equivalent tunable data.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Should chain windows eventually start during active frames for more forgiveness? | systems-designer | After first playable combo test | Provisional: recovery-only windows. |
| Should Air Slash have a small landing cancel if it touches ground during recovery? | gameplay-programmer | During implementation prototype | Provisional: no landing cancel in this GDD. |
| Should neutral Launcher use the same frame data as chained Launcher? | game-designer | After first combat prototype | Provisional: same timing for simplicity. |
| Should hit-confirm alter chain windows later? | systems-designer | During Combo Metrics or Hit Resolution GDD | Provisional: chain route is input/state based, not hit-confirm based. |
| Should slash timing be retuned around final pixel animation frame counts? | art-director / gameplay-programmer | Before vertical slice art pass | Provisional: gameplay timing remains source of truth. |

