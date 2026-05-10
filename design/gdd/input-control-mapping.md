# Input & Control Mapping

> **Status**: Designed
> **Author**: Codex
> **Last Updated**: 2026-05-09
> **Last Verified**: 2026-05-09
> **Implements Pillar**: 训练场优先; 连段短而完整
> **Creative Director Review (CD-GDD-ALIGN)**: Skipped — Solo mode, 2026-05-09

## Summary

Input & Control Mapping defines the player-facing action vocabulary for the training prototype: movement, jump, light attack, launcher, air slash, reset, and pause. It exists so every downstream movement, combat, combo, UI, and Web export system reads the same named actions instead of hardcoded keys.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None`

## Overview

This system maps physical inputs from keyboard, optional gamepad, and optional touch fallback into a small set of named gameplay actions. The player should be able to move left/right, jump, perform the core sword combo, launch the dummy, chase in the air, reset the training state, and pause without thinking about device-specific bindings. The GDD describes the behavior and action contract; the later architecture work decides the exact Godot InputMap implementation details.

## Player Fantasy

The player fantasy is invisible responsiveness: the player feels like the sword fighter obeys intent immediately, and any dropped combo feels like a timing mistake rather than input confusion. This system supports the fantasy of becoming more competent through repeated practice by making the control vocabulary small, stable, and readable.

For this game, inputs should feel closer to a classic arcade action game than a simulation. Controls are crisp and binary, with deliberate attack commitment handled by combat timing rather than by sluggish input recognition.

## Detailed Design

### Core Rules

1. The game uses named actions as the only design-facing input contract.
2. Keyboard is the primary MVP input method.
3. Gamepad and touch are compatibility targets, not required to reach parity in the first playable prototype.
4. Directional movement supports left and right only for MVP gameplay.
5. Vertical input is not a movement axis in MVP; jump, launcher, and air slash are separate actions.
6. Attack inputs are intentionally few:
   - `light_attack` advances the ground combo and performs air slash when airborne.
   - `launcher` performs the dedicated ground launcher when allowed by combat state.
7. Reset is a first-class training action and must be available from active play without opening a menu.
8. Pause is a system action and must not be consumed by combat, movement, or UI widgets during active play.
9. Input mapping must never depend on visible keyboard labels in combat logic; displayed hints read from the action contract.
10. The system reports action intent; it does not decide whether an action is valid in the current combat or movement state.

### Named Actions

| Action | Primary Keyboard | Optional Gamepad | Optional Touch | Type | Owner |
|--------|------------------|------------------|----------------|------|-------|
| `move_left` | `A` / Left Arrow | D-pad Left / Left Stick Left | Left virtual button | Held | Input & Control Mapping |
| `move_right` | `D` / Right Arrow | D-pad Right / Left Stick Right | Right virtual button | Held | Input & Control Mapping |
| `jump` | `Space` | South face button | Jump button | Pressed | Input & Control Mapping |
| `light_attack` | `J` | West face button | Attack button | Pressed | Input & Control Mapping |
| `launcher` | `K` | North face button | Launcher button | Pressed | Input & Control Mapping |
| `reset_training` | `R` | Select / Back | Reset button | Pressed | Input & Control Mapping |
| `pause` | `Esc` | Start | Pause button | Pressed | Input & Control Mapping |

Keyboard arrows duplicate `A` and `D` so a first-time player can discover movement quickly. The action keys `J` and `K` keep the right hand near attack controls and leave `Space` as the jump standard for browser players.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Active Gameplay Input | Training scene is running and not paused | Pause action, browser focus loss, modal UI opens | Gameplay actions are reported to movement/combat/reset systems. |
| Paused / Menu Input | Pause menu is opened | Resume or reset to training | Gameplay actions are ignored except menu navigation and confirm/cancel. |
| Focus Lost | Browser tab, canvas, or window loses focus | Focus returns and player confirms/resumes | Held inputs are cleared; pressed actions must not fire retroactively. |
| Rebinding Disabled | MVP default | Future options UI exists | Controls use fixed default mappings. |
| Touch Fallback Active | Touch device detected or player enables touch controls | Touch controls disabled or non-touch input resumes | Touch buttons emit the same named actions without changing gameplay logic. |

### Input Consumption Rules

1. Movement reads held state each physics frame.
2. Jump, light attack, launcher, reset, and pause are edge-triggered actions.
3. If pause and any gameplay action occur on the same frame, pause wins.
4. If reset and attack occur on the same frame, reset wins because it is a training control.
5. If both `move_left` and `move_right` are held, horizontal intent is neutral.
6. The input system does not buffer combat actions. Buffering belongs to Combat State Machine or Attack Data & Timing.
7. The input system exposes enough event timing for downstream systems to implement input buffer windows later.

### Interactions with Other Systems

| System | Data Flow | Responsibility Split |
|--------|-----------|----------------------|
| Player Movement Controller | Consumes `move_left`, `move_right`, and `jump` intent | Input owns action names; movement owns acceleration, jump validity, and motion response. |
| Combat State Machine | Consumes `light_attack` and `launcher` press events | Input owns physical mapping; combat owns valid/invalid action windows. |
| Attack Data & Timing | May define buffer windows for action presses | Timing owns buffer duration; input only provides press timestamps or just-pressed events. |
| Training Room Reset Flow | Consumes `reset_training` | Reset flow owns what resets and when; input only exposes the command. |
| Combo Counter & Training Metrics | May observe reset and action attempts | Metrics can count attempts, but must not own input validation. |
| Training HUD Visual Pass | Displays control hints | HUD reads action labels from the action contract, not from hardcoded prose. |
| Web Export & Browser Performance | Tests keyboard, gamepad, focus, and latency behavior | Export validation owns browser-specific test matrix. |

## Formulas

### Horizontal Intent Formula

The `horizontal_intent` formula is defined as:

`horizontal_intent = right_strength - left_strength`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `right_strength` | `R` | float | 0.0-1.0 | Strength of `move_right`; keyboard is 0 or 1, analog stick may be continuous. |
| `left_strength` | `L` | float | 0.0-1.0 | Strength of `move_left`; keyboard is 0 or 1, analog stick may be continuous. |

**Output Range:** -1.0 to 1.0. Negative means left, positive means right, 0 means neutral.  
**Example:** If `A` and `D` are both held, `R = 1.0`, `L = 1.0`, so `horizontal_intent = 0.0`.

### Input Latency Budget

The `max_visible_response_frame` formula is defined as:

`max_visible_response_frame = ceil(max_input_response_ms / frame_ms)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `max_input_response_ms` | `M` | float | 16.6-66.7 | Maximum acceptable time before visible response. |
| `frame_ms` | `F` | float | 16.6 at 60 FPS | Target frame duration from technical preferences. |

**Output Range:** 1 to 4 frames under normal play.  
**Example:** For movement response target `M = 33.3` ms and `F = 16.6`, `ceil(33.3 / 16.6) = 3` frames.

### Same-Frame Priority Formula

The `input_priority` formula is defined as:

`input_priority = max(priority(action) for all actions pressed this frame)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `priority(action)` | `P` | int | 0-100 | Fixed priority assigned to each action category. |

**Output Range:** 0 to 100. Higher priority actions resolve first.  
**Example:** If `reset_training` priority is 90 and `light_attack` priority is 50, reset resolves before attack.

Priority values:

| Action Category | Priority |
|----------------|----------|
| Pause | 100 |
| Reset training | 90 |
| Menu confirm/cancel | 80 |
| Movement | 60 |
| Combat actions | 50 |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Both left and right are held | Horizontal intent becomes 0. | Prevents jitter and accidental drift. |
| Pause and attack are pressed on the same frame | Pause opens; attack is not forwarded to combat. | System commands must be reliable. |
| Reset and attack are pressed on the same frame | Reset triggers; attack is ignored for that frame. | Training reset should never be blocked by combat. |
| Browser focus is lost while movement is held | Held input state clears immediately. | Prevents character drift when tab focus changes. |
| Focus returns while a key is already held | No just-pressed event fires until the key is released and pressed again. | Prevents phantom jumps or attacks. |
| Gamepad disconnects during play | Game continues with keyboard input; no gameplay action is fired by disconnect. | Avoids accidental commands from device events. |
| Touch button and keyboard key trigger the same action in one frame | The action is treated as one press. | Prevents duplicate action attempts. |
| Browser captures a key such as `Space` or `Esc` | Game should still respond when canvas focus allows; Web export tests must verify capture behavior. | Browser platform can alter default key behavior. |
| Player holds attack | `light_attack` does not auto-repeat unless a downstream combat system explicitly supports repeat. | Combo timing should be intentional. |
| Analog stick rests slightly off center | Movement intent below deadzone is treated as 0. | Prevents controller drift. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Player Movement Controller | Depends on this | Consumes horizontal intent and jump press events. |
| Combat State Machine | Depends on this | Consumes attack and launcher press events. |
| Attack Data & Timing | Depends on this | Consumes action press timestamps for future buffer/cancel windows. |
| Training Room Reset Flow | Depends on this | Consumes reset command. |
| Combo Counter & Training Metrics | Depends on this | May observe action attempts and reset events. |
| Training HUD Visual Pass | Depends on this | Displays action labels and input hints. |
| Web Export & Browser Performance | Depends on this | Validates browser focus, keyboard capture, and gamepad behavior. |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `movement_response_budget_ms` | 33.3 ms | 16.6-50.0 ms | Allows more visible delay before movement is considered failing. | Makes responsiveness requirement stricter. |
| `attack_response_budget_ms` | 50.0 ms | 16.6-66.7 ms | Allows more delay before attack startup is visible. | Makes attack response stricter. |
| `gamepad_deadzone` | 0.20 | 0.10-0.35 | Reduces drift but can make sticks feel less sensitive. | Improves sensitivity but risks drift. |
| `touch_button_opacity` | 0.65 | 0.35-0.85 | Makes touch buttons easier to see but more visually intrusive. | Keeps screen clear but may reduce touch readability. |
| `touch_button_size_px_720p` | 96 px | 72-128 px | Easier to hit on mobile screens. | Less screen coverage but harder to press. |
| `reset_hold_required` | false | true/false | If true, prevents accidental reset but slows training flow. | If false, reset is faster but easier to trigger accidentally. |

## Visual/Audio Requirements

Input feedback should stay minimal. The player should notice the result of an input, not a separate input effect.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Movement input accepted | Character begins moving within response budget. | Footstep audio belongs to movement, not input. | High |
| Jump input accepted | Character enters jump startup immediately. | Jump SFX belongs to movement. | High |
| Attack input accepted | Attack startup pose or sword preparation appears within response budget. | Attack SFX belongs to combat. | High |
| Reset input accepted | Training reset visual belongs to reset flow. | Reset SFX optional, owned by reset flow. | Medium |
| Pause input accepted | Pause overlay appears and gameplay input stops. | UI confirm/pause SFX optional. | Medium |
| Touch controls visible | Semi-transparent controls that do not cover player, dummy, or hit VFX. | None. | Low |

## Game Feel

### Feel Reference

The target feel is classic arcade action responsiveness: movement and button presses should feel immediate, while commitment comes from attack animation rules rather than delayed input recognition. It should not feel like a physics-heavy platformer where the player waits for acceleration before the character obeys.

### Input Responsiveness

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|--------------------------|-------|
| Move left/right | 33.3 ms | 2 frames target, 3 frames max | Visible horizontal motion should begin quickly. |
| Jump | 50.0 ms | 3 frames | Jump startup may include one anticipation frame if movement still feels crisp. |
| Light attack | 50.0 ms | 3 frames | Visible startup pose or sword motion must begin. |
| Launcher | 50.0 ms | 3 frames | Launcher may have heavier startup, but response must be visible. |
| Reset training | 66.7 ms | 4 frames | Fast enough for repeated practice. |
| Pause | 33.3 ms | 2 frames target, 3 frames max | Pause must feel authoritative. |

### Animation Feel Targets

This input GDD does not own attack or movement frame data. It sets response budgets that downstream animation and combat GDDs must respect.

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| Movement start | 0-2 visible response frames | N/A | N/A | Crisp and readable | Owned by Player Movement Controller. |
| Jump start | 0-3 visible response frames | N/A | N/A | Immediate with slight body compression allowed | Owned by Player Movement Controller. |
| Attack start | 0-3 visible response frames | Defined later | Defined later | Snappy input, committed attack | Owned by Combat State Machine and Attack Data & Timing. |

### Impact Moments

Input does not create combat impact. It creates control confirmation.

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Input accepted | 0-50 ms | Downstream visible state change confirms the action. | Indirectly, through response budgets |
| Input rejected | 0 ms by default | No separate error effect during active combat. | Future optional debug overlay |
| Pause accepted | 0-33.3 ms | Pause overlay appears and input mode changes. | No |

### Weight and Responsiveness Profile

- **Weight**: Light and immediate at the input layer; weight is added by attack timing and hit feedback.
- **Player control**: High for movement and reset; combat actions become committed only after Combat State Machine accepts them.
- **Snap quality**: Crisp and binary for keyboard; analog stick values are reduced to clear horizontal intent.
- **Acceleration model**: Input intent starts instantly. Movement acceleration, if any, belongs to Player Movement Controller.
- **Failure texture**: A failed combo should read as mistimed combat input, not as a hidden binding, missing key, or sluggish input layer.

### Feel Acceptance Criteria

- [ ] Movement begins visibly within the response budget at target 60 FPS.
- [ ] Attack startup is visible within the response budget when combat state accepts the action.
- [ ] Held attack does not accidentally auto-advance the combo.
- [ ] Reset feels fast enough to support repeated training attempts.
- [ ] No playtester describes controls as unresponsive before combat timing is tuned.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Basic keyboard controls | Pause/help overlay or first-run hint | Static until bindings change | Shown during onboarding or pause, not constantly over combat. |
| Current input device hints | Optional HUD/help overlay | On input device change | Only if gamepad/touch support is enabled. |
| Reset prompt | Low-priority corner hint | Static | Visible in training mode until player has used reset once or if pause/help is open. |
| Touch buttons | Screen edges, outside player/dummy combat lane | Every frame while touch mode active | Touch fallback only. |
| Pause/menu focus | Pause menu | On focus changes | Must support Godot 4.6 separate mouse/touch and keyboard/gamepad focus behavior. |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|------------|-----------------------------|--------|
| Movement consumes `move_left`, `move_right`, `jump` | `design/gdd/player-movement-controller.md` | Future movement input contract | Data dependency |
| Combat consumes `light_attack`, `launcher` | `design/gdd/combat-state-machine.md` | Future combat action contract | Data dependency |
| Buffer windows are not owned here | `design/gdd/attack-data-timing.md` | Future action buffer/cancel timing | Ownership handoff |
| Reset consumes `reset_training` | `design/gdd/training-room-reset-flow.md` | Future reset command behavior | State trigger |
| HUD displays action labels | `design/gdd/training-hud-visual-pass.md` | Future control hint UI | Data dependency |
| Browser test matrix validates input behavior | `design/gdd/web-export-browser-performance.md` | Future Web input validation | Rule dependency |

## Acceptance Criteria

- [ ] **GIVEN** active gameplay, **WHEN** the player holds `A` or Left Arrow, **THEN** the system reports `horizontal_intent < 0`.
- [ ] **GIVEN** active gameplay, **WHEN** the player holds `D` or Right Arrow, **THEN** the system reports `horizontal_intent > 0`.
- [ ] **GIVEN** active gameplay, **WHEN** the player holds left and right together, **THEN** the system reports `horizontal_intent = 0`.
- [ ] **GIVEN** active gameplay, **WHEN** the player presses `Space`, **THEN** exactly one `jump` press event is emitted for that press.
- [ ] **GIVEN** active gameplay, **WHEN** the player holds `J`, **THEN** only the initial `light_attack` press event is emitted unless a future combat GDD explicitly supports repeat.
- [ ] **GIVEN** active gameplay, **WHEN** `Esc` and `J` are pressed on the same frame, **THEN** pause is processed and attack is not forwarded that frame.
- [ ] **GIVEN** active gameplay, **WHEN** `R` and `J` are pressed on the same frame, **THEN** reset is processed and attack is not forwarded that frame.
- [ ] **GIVEN** browser focus is lost while a movement key is held, **WHEN** focus returns, **THEN** the character does not continue moving from stale input.
- [ ] **GIVEN** a gamepad stick rests inside the deadzone, **WHEN** no other movement input is active, **THEN** horizontal intent remains 0.
- [ ] **GIVEN** touch fallback is enabled, **WHEN** a touch attack button and keyboard attack key are pressed in the same frame, **THEN** only one `light_attack` press event is reported.
- [ ] **GIVEN** Godot 4.6.2 Web export, **WHEN** pause/menu UI is navigated by keyboard/gamepad and mouse/touch, **THEN** focus visuals remain correct for both focus paths.
- [ ] Performance: input polling and mapping should be negligible within the 16.6 ms frame budget; any measurable overhead must be investigated during Web export profiling.
- [ ] No implementation may hardcode physical key names inside movement, combat, reset, or HUD gameplay logic.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Should `launcher` stay on a dedicated key (`K`) or become a directional attack input later? | game-designer | Before Combat State Machine GDD approval | Provisional: dedicated `K` for MVP clarity. |
| Should full rebinding exist in the Web demo? | producer / ux-designer | Before Vertical Slice UI work | Provisional: no rebinding in MVP. |
| Should touch controls be playable or only a fallback for menus/reset? | ux-designer | Before Web Export & Browser Performance GDD | Provisional: compatibility fallback, not tuned for first playable. |
| Should reset require hold-to-confirm once accidental reset risk is known? | qa-lead | After first internal playtest | Provisional: instant reset for training speed. |

