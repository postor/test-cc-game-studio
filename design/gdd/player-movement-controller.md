# Player Movement Controller

> **Status**: Designed
> **Author**: Codex
> **Last Updated**: 2026-05-09
> **Last Verified**: 2026-05-09
> **Implements Pillar**: 连段短而完整; 训练场优先
> **Creative Director Review (CD-GDD-ALIGN)**: Skipped — Solo mode, 2026-05-09

## Summary

Player Movement Controller defines how the sword fighter moves, faces, jumps, lands, and stays positioned for the training dummy combo. It consumes the named input actions from Input & Control Mapping and turns them into readable 2D arcade movement that supports ground attacks, launcher setup, and air chase without becoming a platforming system.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Input & Control Mapping`

## Overview

The movement system lets the player walk left and right on a flat training floor, jump to chase a launched dummy, face the correct direction, and recover quickly after landing. It exists to put the player in the right place for the sword combo, not to create traversal challenge. Movement should feel crisp enough for repeated practice while leaving weight, commitment, and impact to attack timing and hit feedback.

## Player Fantasy

The player should feel like a disciplined martial artist controlling spacing in a practice room: step in, slash, launch, hop after the target, strike again, land, reset. The fantasy is not acrobatic platform mastery; it is reliable positioning for a clean combo. If the player misses the dummy, they should understand whether they were too far away, jumped too late, or attacked at the wrong time.

## Detailed Design

### Core Rules

1. Movement is 2D side-view horizontal movement on a single flat combat lane.
2. The player can move left and right while grounded unless a downstream combat state explicitly locks movement.
3. The player can jump from grounded state when `jump` is pressed.
4. The player can move horizontally in air with reduced control.
5. The player cannot double jump in MVP.
6. The player cannot crouch, dash, wall jump, climb, ledge grab, or interact with slopes in MVP.
7. Facing direction updates from horizontal movement while not locked by combat.
8. Attack states may temporarily lock facing direction; movement exposes facing direction but does not decide combat locks.
9. Landing returns the player to grounded movement immediately unless a later combat/animation GDD defines landing recovery.
10. The system reports player grounded/airborne state for Combat State Machine and air attack eligibility.
11. The system must support browser-friendly responsiveness at 60 FPS.
12. All movement values are tuning knobs, not hardcoded implementation constants.

### Movement Actions

| Input Action | Movement Response | Notes |
|--------------|------------------|-------|
| `move_left` / `move_right` held | Applies horizontal intent. | Opposing inputs produce neutral intent per Input & Control Mapping. |
| `jump` pressed while grounded | Starts jump. | Jump consumes one press event; no auto-repeat. |
| `jump` pressed while airborne | No movement effect. | Future air options must be designed separately. |
| `reset_training` | Movement state resets via Training Room Reset Flow. | Movement does not own reset target positions. |
| `pause` | Movement processing halts via pause state. | Input & Control Mapping owns pause priority. |

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Grounded Idle | Player is on floor and horizontal intent is 0 | Horizontal intent, jump, combat lock, reset | Velocity x approaches 0 quickly; facing remains last non-neutral direction. |
| Grounded Move | Player is on floor and horizontal intent is nonzero | Horizontal intent returns 0, jump, combat lock, reset | Velocity x approaches target run speed; facing updates to movement direction. |
| Jump Start | `jump` accepted from grounded state | Initial jump velocity applied | Short transitional state for response and animation; may be 0-3 frames. |
| Airborne Rising | Vertical velocity is upward | Vertical velocity reaches 0 or downward | Horizontal air control applies; air attack eligibility is true if combat allows. |
| Airborne Falling | Player is not grounded and vertical velocity is downward | Floor contact | Horizontal air control applies; landing is prepared. |
| Landing | Floor contact after airborne state | Landing response frames complete | Returns to Grounded Idle or Grounded Move based on horizontal intent. |
| Movement Locked | Combat or reset flow requests movement lock | Lock is released | Movement ignores horizontal intent but may preserve or damp velocity as specified by the locking system. |

### Facing Rules

1. Facing direction is either left or right.
2. Facing defaults to right when the training scene starts.
3. While grounded or airborne and not facing-locked, any nonzero horizontal intent updates facing.
4. While combat-facing lock is active, facing remains fixed until combat releases the lock.
5. If movement is reset, facing resets according to Training Room Reset Flow; provisional default is facing right toward the dummy.

### Floor and Bounds Rules

1. MVP training floor is flat.
2. The movement system assumes one floor height in the training room.
3. Stage bounds prevent leaving the intended combat space.
4. Hitting a horizontal bound clamps position and clears movement in that direction.
5. There are no pits, slopes, one-way platforms, moving platforms, ladders, or hazards in MVP.

### Interactions with Other Systems

| System | Data Flow | Responsibility Split |
|--------|-----------|----------------------|
| Input & Control Mapping | Provides `horizontal_intent` and `jump` press events | Input owns action mapping; movement owns physical response. |
| Combat State Machine | Reads grounded/airborne/facing; may request movement and facing locks | Combat owns attack state constraints; movement obeys lock requests. |
| Attack Data & Timing | Defines attack windows that may alter movement | Timing owns exact lock/cancel frames; movement applies them. |
| Launch & Air Juggle System | Depends on player air positioning for chase | Juggle owns dummy motion; movement owns player jump/chase capability. |
| Hit Feedback System | May trigger hitstop that freezes movement briefly | Feedback owns hitstop duration; movement must resume cleanly after pause/freeze. |
| Camera & Screen Shake | Follows player position and may frame player/dummy pair | Camera owns framing; movement exposes position. |
| Training Room Reset Flow | Sets player position, velocity, facing, and grounded state | Reset owns target state; movement applies clean state reset. |

## Formulas

### Ground Horizontal Velocity

The `ground_velocity_x` formula is defined as:

`ground_velocity_x = move_toward(current_velocity_x, horizontal_intent * ground_max_speed, ground_acceleration * delta_seconds)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_velocity_x` | `Vx` | float | -1000 to 1000 px/s | Current horizontal velocity. |
| `horizontal_intent` | `I` | float | -1.0 to 1.0 | Input value from Input & Control Mapping. |
| `ground_max_speed` | `Sg` | float | 120-320 px/s | Maximum ground speed. |
| `ground_acceleration` | `Ag` | float | 800-3000 px/s² | Rate of speed change on ground. |
| `delta_seconds` | `dt` | float | 0.0-0.05 | Physics frame delta. |

**Output Range:** `-ground_max_speed` to `ground_max_speed` under normal play.  
**Example:** With `I = 1`, `Sg = 220`, `Ag = 1800`, and `dt = 0.0166`, velocity moves toward 220 by about 29.9 px/s per frame.

### Ground Friction Velocity

The `ground_friction_velocity_x` formula is defined as:

`ground_friction_velocity_x = move_toward(current_velocity_x, 0, ground_deceleration * delta_seconds)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_velocity_x` | `Vx` | float | -1000 to 1000 px/s | Current horizontal velocity. |
| `ground_deceleration` | `Dg` | float | 1200-4000 px/s² | Rate of stopping when no horizontal input exists. |
| `delta_seconds` | `dt` | float | 0.0-0.05 | Physics frame delta. |

**Output Range:** Moves toward 0 without overshoot.  
**Example:** With `Vx = 220`, `Dg = 2400`, and `dt = 0.0166`, velocity reduces by about 39.8 px/s per frame.

### Jump Initial Velocity

The `jump_initial_velocity_y` formula is defined as:

`jump_initial_velocity_y = -sqrt(2 * gravity_strength * target_jump_height)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `gravity_strength` | `G` | float | 700-1800 px/s² | Downward acceleration magnitude. |
| `target_jump_height` | `H` | float | 70-180 px | Approximate maximum jump height. |

**Output Range:** -313 to -805 px/s under normal values. Negative means upward in Godot 2D coordinates.  
**Example:** With `G = 1100` and `H = 110`, `jump_initial_velocity_y = -491.9 px/s`.

### Air Horizontal Velocity

The `air_velocity_x` formula is defined as:

`air_velocity_x = move_toward(current_velocity_x, horizontal_intent * air_max_speed, air_acceleration * delta_seconds)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_velocity_x` | `Vx` | float | -1000 to 1000 px/s | Current horizontal velocity. |
| `horizontal_intent` | `I` | float | -1.0 to 1.0 | Input value from Input & Control Mapping. |
| `air_max_speed` | `Sa` | float | 100-280 px/s | Maximum horizontal speed while airborne. |
| `air_acceleration` | `Aa` | float | 400-1800 px/s² | Rate of horizontal adjustment in air. |
| `delta_seconds` | `dt` | float | 0.0-0.05 | Physics frame delta. |

**Output Range:** `-air_max_speed` to `air_max_speed` under normal play.  
**Example:** With `I = 1`, `Sa = 190`, `Aa = 900`, and `dt = 0.0166`, velocity moves toward 190 by about 14.9 px/s per frame.

### Fall Velocity

The `fall_velocity_y` formula is defined as:

`fall_velocity_y = min(current_velocity_y + gravity_strength * delta_seconds, max_fall_speed)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_velocity_y` | `Vy` | float | -1000 to 1600 px/s | Current vertical velocity. |
| `gravity_strength` | `G` | float | 700-1800 px/s² | Downward acceleration magnitude. |
| `delta_seconds` | `dt` | float | 0.0-0.05 | Physics frame delta. |
| `max_fall_speed` | `Fmax` | float | 500-1200 px/s | Terminal downward velocity. |

**Output Range:** Up to `max_fall_speed`.  
**Example:** With `Vy = 300`, `G = 1100`, `dt = 0.0166`, velocity becomes about 318.3 px/s.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Jump is pressed while airborne | No new jump occurs. | MVP does not include double jump. |
| Jump is pressed on the same frame as landing | Treat as a normal grounded jump if the landing state has been entered before input resolution. | Keeps repeated jumps responsive. |
| Player hits a horizontal training-room bound | Position clamps to the bound and velocity in that direction becomes 0. | Prevents camera or combat space issues. |
| Both left and right are held | Movement receives `horizontal_intent = 0` and decelerates. | Input GDD defines neutral opposing input. |
| Hitstop freezes gameplay while player is moving | Movement velocity is preserved and resumes after hitstop. | Hitstop should feel like impact, not input loss. |
| Reset occurs while airborne | Reset flow sets grounded state, position, velocity, and facing. | Training reset must be reliable from any state. |
| Combat locks movement while velocity is nonzero | Lock behavior follows the combat lock type: hard lock sets x velocity to 0, soft lock damps velocity. | Attack timing must control commitment. |
| Browser frame hitches above expected delta | Movement clamps or safely handles large delta so the player does not tunnel past bounds. | Web builds can stutter. |
| Player lands while holding movement | Landing exits into Grounded Move, not Grounded Idle. | Maintains responsive control. |
| Player starts an air attack near jump apex | Movement remains airborne; combat may apply action-specific drift or lock in its own GDD. | Keeps ownership clear. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Input & Control Mapping | This depends on Input | Consumes `horizontal_intent` and `jump` press events. |
| Combat State Machine | Combat depends on this | Reads grounded/airborne/facing; can request movement/facing locks. |
| Attack Data & Timing | This depends on future attack timing | Receives movement lock windows and any attack drift modifiers. |
| Launch & Air Juggle System | Juggle depends on this | Player jump and air control must allow air chase. |
| Hit Feedback System | This depends on feedback | Hitstop may freeze movement and resume it. |
| Camera & Screen Shake | Camera depends on this | Camera follows or frames player position. |
| Training Room Reset Flow | Reset depends on this | Reset sets player position, velocity, facing, and grounded state. |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `ground_max_speed` | 220 px/s | 120-320 px/s | Faster spacing, easier chase setup, risk of overshooting dummy. | More deliberate spacing, can feel sluggish. |
| `ground_acceleration` | 1800 px/s² | 800-3000 px/s² | Snappier starts. | Heavier starts, higher risk of unresponsive feel. |
| `ground_deceleration` | 2400 px/s² | 1200-4000 px/s² | Faster stops, more arcade precision. | More slide, less reliable positioning. |
| `target_jump_height` | 110 px | 70-180 px | Easier air chase, risk of too much hang time. | Lower chase window, more grounded feel. |
| `gravity_strength` | 1100 px/s² | 700-1800 px/s² | Faster fall, heavier feel. | Floatier jump, easier air timing. |
| `max_fall_speed` | 850 px/s | 500-1200 px/s | Faster landing recovery, harsher air timing. | Softer fall, more float. |
| `air_max_speed` | 190 px/s | 100-280 px/s | More air correction. | More committed jumps. |
| `air_acceleration` | 900 px/s² | 400-1800 px/s² | Faster air steering. | More deliberate air drift. |
| `landing_recovery_frames` | 0 frames | 0-6 frames | More weight but can interrupt training flow. | More responsive repeated attempts. |
| `stage_left_bound` / `stage_right_bound` | Defined by training room layout | Room-specific | Larger practice space. | Tighter spacing practice. |

## Visual/Audio Requirements

Movement visuals should emphasize readability and training rhythm, not spectacle. The art bible's rules apply: the character silhouette and sword direction must remain clear.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Start moving | Immediate foot/torso shift in facing direction. | Optional light footstep, low priority. | Medium |
| Stop moving | Character settles quickly without sliding too far. | None required. | Medium |
| Jump start | Small compression or push-off frame within response budget. | Short cloth/foot push SFX optional. | High |
| Airborne | Readable airborne pose; sword and facing remain visible. | None required. | Medium |
| Landing | Small dust puff at feet, low brightness so it does not compete with hit VFX. | Soft landing SFX optional. | Medium |
| Hit horizontal bound | No special VFX in MVP. | None. | Low |

## Game Feel

### Feel Reference

Movement should feel like an arcade beat-'em-up training room: immediate horizontal control, a practical jump, and quick recovery. It should not feel like a precision platformer with complex jump tech, nor like a heavy action RPG with long movement commitment.

### Input Responsiveness

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|--------------------------|-------|
| Horizontal movement start | 33.3 ms | 2 frames target, 3 frames max | Must satisfy input GDD budget. |
| Horizontal stop | 50.0 ms | 3 frames | Player should not slide past dummy accidentally. |
| Jump start | 50.0 ms | 3 frames | May include one anticipation frame if still responsive. |
| Facing flip | 33.3 ms | 2 frames target, 3 frames max | Must happen before next unblocked attack startup. |
| Landing control return | 50.0 ms | 3 frames | Landing should not slow training loop. |

### Animation Feel Targets

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| Run / step loop | 0-2 response frames | Continuous | 0-3 stop frames | Crisp positioning | Placeholder sprites acceptable. |
| Jump start | 0-3 frames | N/A | N/A | Immediate push-off | Supports air chase. |
| Airborne rising/falling | N/A | Continuous | N/A | Readable height and facing | Keep sword silhouette clear. |
| Landing | 0 frames gameplay recovery | 1-4 visual frames | 0 default | Fast repeat attempts | Recovery can be revisited after playtest. |

### Impact Moments

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Jump push-off | 50-100 ms visual read | Small compression and dust, if art exists. | Yes |
| Landing dust | 100-180 ms | Small low-contrast dust at feet. | Yes |
| Movement stop | 0-50 ms | Quick settle; no slide exaggeration. | Yes |

### Weight and Responsiveness Profile

- **Weight**: Light-to-medium. Movement should not feel weightless, but responsiveness beats realism.
- **Player control**: High outside attacks; combat states can deliberately reduce control.
- **Snap quality**: Crisp starts and stops with a tiny amount of smoothing.
- **Acceleration model**: Fast arcade acceleration, faster deceleration.
- **Failure texture**: If the player misses the dummy due to spacing, the miss should be readable from distance and facing, not from ambiguous movement drift.

### Feel Acceptance Criteria

- [ ] Player can repeatedly step into attack range without overshooting the dummy in normal tuning.
- [ ] Player can jump after a launched dummy with enough air control to attempt air slash.
- [ ] Movement never feels like a separate platforming challenge in the MVP room.
- [ ] Landing allows quick continuation or reset without noticeable downtime.
- [ ] Facing direction is visually clear before attack startup.

## UI Requirements

Movement has no persistent UI of its own. It contributes to UI only through optional control hints owned by Training HUD Visual Pass.

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Movement controls | Pause/help overlay or first-run hint | Static | Uses labels from Input & Control Mapping. |
| Debug movement values | Developer debug overlay only | Per frame | Optional during prototype tuning, not player-facing. |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|------------|-----------------------------|--------|
| Consumes `horizontal_intent` and `jump` | `design/gdd/input-control-mapping.md` | Named action contract and horizontal intent formula | Data dependency |
| Combat reads grounded/airborne/facing | `design/gdd/combat-state-machine.md` | Future combat state eligibility | Data dependency |
| Attack timing may lock movement | `design/gdd/attack-data-timing.md` | Future movement/facing lock windows | Ownership handoff |
| Air chase depends on jump and air control | `design/gdd/launch-air-juggle-system.md` | Future dummy launch and chase tuning | Rule dependency |
| Hitstop can freeze movement | `design/gdd/hit-feedback-system.md` | Future hitstop behavior | Rule dependency |
| Camera follows position | `design/gdd/camera-screen-shake.md` | Future framing and screen shake | Data dependency |
| Reset sets movement state | `design/gdd/training-room-reset-flow.md` | Future reset target state | State trigger |

## Acceptance Criteria

- [ ] **GIVEN** the player is grounded and active, **WHEN** `horizontal_intent > 0`, **THEN** player velocity moves toward `ground_max_speed`.
- [ ] **GIVEN** the player is grounded and active, **WHEN** `horizontal_intent < 0`, **THEN** player velocity moves toward `-ground_max_speed`.
- [ ] **GIVEN** the player is grounded and no horizontal input is active, **WHEN** physics updates, **THEN** velocity x moves toward 0 using `ground_deceleration`.
- [ ] **GIVEN** the player is grounded, **WHEN** `jump` is pressed, **THEN** the player enters Jump Start and receives `jump_initial_velocity_y`.
- [ ] **GIVEN** the player is airborne, **WHEN** `jump` is pressed, **THEN** no second jump occurs.
- [ ] **GIVEN** the player is airborne, **WHEN** horizontal input is held, **THEN** velocity x moves toward `air_max_speed` in that direction using air acceleration.
- [ ] **GIVEN** the player reaches the floor after airborne state, **WHEN** floor contact is detected, **THEN** the player enters Landing and then returns to grounded state.
- [ ] **GIVEN** the player is not facing-locked, **WHEN** horizontal intent changes direction, **THEN** facing updates within the response budget.
- [ ] **GIVEN** a combat state applies hard movement lock, **WHEN** horizontal input is held, **THEN** player movement does not change position until the lock releases.
- [ ] **GIVEN** hitstop starts while the player is moving, **WHEN** hitstop ends, **THEN** movement resumes without losing held input state.
- [ ] **GIVEN** reset flow triggers while the player is airborne, **WHEN** reset completes, **THEN** player position, velocity, grounded state, and facing match reset defaults.
- [ ] Performance: movement update must fit within the 16.6 ms frame budget and should be negligible in isolation.
- [ ] No implementation may hardcode movement values outside tunable data or exported configuration.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Should the player have any coyote time or jump input buffer? | game-designer | Before implementation story | Provisional: no coyote time needed for flat training room; revisit if jump chase feels unfair. |
| Should air control be high enough to correct bad launcher spacing? | systems-designer | During Launch & Air Juggle GDD | Provisional: moderate air control. |
| Should landing ever have recovery frames? | game-designer | After first combat feel prototype | Provisional: 0 gameplay recovery for fast training loop. |
| What exact room bounds should the player use? | level-designer | During Training Room Reset Flow or room layout spec | Provisional: room-specific values. |
