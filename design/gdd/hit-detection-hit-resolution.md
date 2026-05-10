# Hit Detection & Hit Resolution

> **Status**: Designed
> **Author**: Codex
> **Last Updated**: 2026-05-09
> **Last Verified**: 2026-05-09
> **Implements Pillar**: 刀刀有重量; 木桩也是表演对象
> **Creative Director Review (CD-GDD-ALIGN)**: Skipped — Solo mode, 2026-05-09

## Summary

Hit Detection & Hit Resolution defines how active attack frames check overlap with the training dummy, prevent duplicate hits, and emit a structured `HitEvent` for dummy state, launch/juggle, hit feedback, audio, and combo tracking. It owns hit confirmation, not damage spectacle or dummy behavior.

> **Quick reference** — Layer: `Feature` · Priority: `MVP` · Key deps: `Combat State Machine`, `Attack Data & Timing`

## Overview

This system turns an active sword attack into a clear hit or miss. During active frames from Attack Data & Timing, the current attack's hitbox checks against valid hurtboxes. If a valid target is found and has not already been hit by the same attack instance, the system emits one `HitEvent` containing attack identity, target identity, hit position, direction, hit type, and response tags. Other systems decide what to do with that event: the dummy enters hit/launch states, feedback plays hitstop/spark/shake, combo metrics increment, and audio may play.

## Player Fantasy

The player should feel that every visible sword contact is recognized and every whiff is understandable. A clean hit should immediately confirm “that connected,” while a miss should read as bad spacing, bad timing, or wrong state. The system supports the fantasy of weight by making hit events precise, deterministic, and rich enough for downstream systems to sell impact.

## Detailed Design

### Core Rules

1. Hit detection only runs during active frames defined by Attack Data & Timing.
2. Each active attack instance has a unique `attack_instance_id`.
3. A target can be hit at most once per `attack_instance_id`.
4. MVP supports one player attacker and one training dummy target.
5. MVP does not include player damage, enemy attacks, armor, block, parry, invulnerability, elemental damage, or hit reactions on multiple enemies.
6. Hit detection determines contact; hit resolution emits structured event data.
7. Hit resolution does not directly move the dummy, change combo count, play VFX, or apply hitstop.
8. Hitbox geometry is authored per attack and can differ per active frame.
9. Hurtbox geometry is owned by the target, starting with the training dummy.
10. Hit events must include enough data for dummy response, launch/juggle, hit feedback, sound, and combo metrics.
11. Active frame timing must not be shortened by hitstop.
12. Hit detection must be deterministic enough for repeatable tuning in a single-player Web prototype.
13. All hitbox and response values are tunable data, not hardcoded in combat state logic.

### Hitbox Defaults

Values are prototype defaults in pixels relative to the player origin and facing direction. Final values should be tuned with debug overlays.

| Attack | Shape | Offset X | Offset Y | Width | Height | Active Frames | Hit Type |
|--------|-------|----------|----------|-------|--------|---------------|----------|
| Light Slash 1 | Rectangle | 42 | -18 | 54 | 34 | 3f | light |
| Light Slash 2 | Rectangle | 48 | -22 | 62 | 38 | 3f | light |
| Light Slash 3 | Rectangle | 52 | -18 | 70 | 42 | 4f | heavy |
| Launcher | Rectangle | 40 | -54 | 58 | 86 | 4f | launcher |
| Air Slash | Rectangle | 44 | -20 | 64 | 46 | 4f | air |

Coordinate convention:
- Positive X means forward in facing direction.
- Negative Y means upward in Godot 2D screen coordinates.
- The player's facing direction mirrors the X offset and shape.

### HitEvent Contract

Every valid hit emits one `HitEvent`.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `hit_event_id` | string/int | Yes | Unique ID for this hit event. |
| `attack_instance_id` | string/int | Yes | Unique ID for the current attack instance. |
| `attacker_id` | string/int | Yes | Player entity ID for MVP. |
| `target_id` | string/int | Yes | Training dummy entity ID for MVP. |
| `attack_id` | enum/string | Yes | `light_slash_1`, `light_slash_2`, `light_slash_3`, `launcher`, `air_slash`. |
| `route_step` | int | Yes | 1-5 route position from Combat State Machine. |
| `hit_type` | enum | Yes | `light`, `heavy`, `launcher`, `air`. |
| `active_frame_index` | int | Yes | Which active frame produced the hit, 1-based. |
| `hit_position` | Vector2 | Yes | Approximate contact point in world coordinates. |
| `hit_direction` | Vector2 | Yes | Direction from attacker toward target or authored attack direction. |
| `facing` | enum | Yes | Attacker facing at hit time: `left` or `right`. |
| `response_tags` | Array[StringName] | Yes | Tags such as `hitstun`, `knockback`, `launch`, `air_hit`, `combo_increment`. |
| `base_hitstop_frames` | int | Yes | Suggested hitstop for feedback system. |
| `base_knockback_x` | float | Yes | Suggested horizontal response for dummy systems. |
| `base_knockback_y` | float | Yes | Suggested vertical response for launch/juggle systems. |
| `debug_source_frame` | int | Yes | Authored frame index for debug reproduction. |

### Default Hit Response Tags

| Attack | Response Tags | Suggested Hitstop | Knockback X | Knockback Y | Notes |
|--------|---------------|-------------------|-------------|-------------|-------|
| Light Slash 1 | `hitstun`, `knockback`, `combo_increment` | 3f | 40 px/s | 0 px/s | Small confirmation. |
| Light Slash 2 | `hitstun`, `knockback`, `combo_increment` | 3f | 50 px/s | 0 px/s | Slightly stronger. |
| Light Slash 3 | `hitstun`, `knockback`, `combo_increment`, `heavy_hit` | 4f | 70 px/s | 0 px/s | Punctuates ground route. |
| Launcher | `hitstun`, `launch`, `combo_increment`, `launcher_hit` | 5f | 35 px/s | -420 px/s | Sends dummy upward; exact launch owned by Launch & Air Juggle. |
| Air Slash | `hitstun`, `air_hit`, `combo_increment` | 4f | 60 px/s | -80 px/s | Keeps air hit readable without huge relaunch. |

### Resolution Flow

1. Combat State Machine enters an attack active phase.
2. Attack Data & Timing provides attack ID and active frame index.
3. Hit Detection resolves the authored hitbox for the current attack frame and facing.
4. The system queries valid target hurtboxes.
5. If no valid overlap exists, no event is emitted.
6. If overlap exists, the system checks whether this `target_id` has already been hit by this `attack_instance_id`.
7. If already hit, no duplicate event is emitted.
8. If not already hit, the system computes contact data and emits one `HitEvent`.
9. The target is added to the attack instance's hit registry.
10. Downstream systems consume the event independently.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Idle | No active attack frame | Attack active phase begins | No hit checks. |
| Attack Instance Active | Combat enters active phase for an attack | Active frames complete, reset, pause | Creates/uses `attack_instance_id`; evaluates hitboxes. |
| Hit Confirmed | Valid overlap found and target not yet hit by instance | HitEvent emitted | Adds target to per-instance hit registry. |
| Duplicate Suppressed | Overlap found but target already hit by instance | Active frame continues or ends | No extra event emitted. |
| Suspended | Hitstop or pause freezes timing | Freeze ends or reset occurs | No new hit checks while suspended unless implementation explicitly replays the same active frame safely. |
| Cleared | Attack active phase ends or reset occurs | Next active attack begins | Clears attack instance registry. |

### Interactions with Other Systems

| System | Data Flow | Responsibility Split |
|--------|-----------|----------------------|
| Combat State Machine | Provides current attack identity and active phase | Combat owns state identity; hit detection owns overlap/event. |
| Attack Data & Timing | Provides active frames and attack frame data | Timing owns frame windows; hit detection owns geometry and event output. |
| Player Movement Controller | Provides attacker position and facing | Movement owns transform/facing; hit detection uses them. |
| Training Dummy State System | Consumes `HitEvent` | Dummy owns hitstun, hurt, launch, land, reset states. |
| Launch & Air Juggle System | Consumes launcher/air hit fields | Juggle owns float arc and air-state tuning. |
| Hit Feedback System | Consumes hitstop, position, hit type | Feedback owns freeze, flash, shake, VFX. |
| Combo Counter & Training Metrics | Consumes `combo_increment` and attack identity | Combo owns counter and metrics. |
| Basic SFX Playback | Consumes hit type and position | Audio owns sound choice and playback. |

## Formulas

### Hitbox World Rect

The `hitbox_world_rect` formula is defined as:

`hitbox_world_rect = transform_local_rect(hitbox_local_rect, attacker_position, facing_sign)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `hitbox_local_rect` | `Hlocal` | Rect2 | authored pixels | Attack hitbox relative to player origin. |
| `attacker_position` | `P` | Vector2 | world space | Player position. |
| `facing_sign` | `F` | int | -1 or 1 | -1 for left, 1 for right. |

**Output Range:** One world-space rectangle per active frame.  
**Example:** A Light Slash 1 hitbox with offset x 42 becomes x + 42 when facing right and x - 42 when facing left.

### Hit Overlap

The `hit_overlap` formula is defined as:

`hit_overlap = hitbox_world_shape intersects target_hurtbox_world_shape`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `hitbox_world_shape` | `Hb` | Shape2D | valid shape | Current attack hitbox. |
| `target_hurtbox_world_shape` | `Hu` | Shape2D | valid shape | Target hurtbox. |

**Output Range:** Boolean.  
**Example:** If Launcher hitbox overlaps the dummy torso hurtbox on active frame 2, `hit_overlap = true`.

### Duplicate Hit Suppression

The `can_emit_hit` formula is defined as:

`can_emit_hit = hit_overlap && !hit_registry.contains(attack_instance_id, target_id)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `hit_overlap` | `O` | bool | true/false | Whether hitbox and hurtbox overlap. |
| `hit_registry` | `R` | set | attack-target pairs | Pairs already hit by this attack instance. |
| `attack_instance_id` | `A` | id | unique per attack | Current attack instance. |
| `target_id` | `T` | id | valid target id | Target being checked. |

**Output Range:** Boolean.  
**Example:** First overlap emits a hit; continued overlap on the next active frame does not emit another hit for the same target.

### Contact Point

The `hit_position` formula is defined as:

`hit_position = center(overlap_area(hitbox_world_shape, target_hurtbox_world_shape))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `hitbox_world_shape` | `Hb` | Shape2D | valid shape | Current attack hitbox. |
| `target_hurtbox_world_shape` | `Hu` | Shape2D | valid shape | Target hurtbox. |

**Output Range:** World-space Vector2. If exact overlap center is unavailable, use target hurtbox center biased toward attacker-facing edge.  
**Example:** A right-facing slash that clips the dummy left side reports a hit position near the dummy's left edge.

### Hit Direction

The `hit_direction` formula is defined as:

`hit_direction = normalize(Vector2(facing_sign, vertical_bias))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `facing_sign` | `F` | int | -1 or 1 | Attacker facing. |
| `vertical_bias` | `V` | float | -1.0 to 1.0 | Authored vertical influence for the attack. |

**Output Range:** Normalized Vector2.  
**Example:** Launcher uses a negative vertical bias so the direction points upward-forward.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Hitbox overlaps dummy for multiple active frames | Emit exactly one hit for that attack instance. | Prevents accidental multi-hit from one slash. |
| Two hitboxes from the same attack overlap the same target in one frame | Emit one hit using the highest-priority hitbox or first authored hitbox order. | Avoids duplicate events. |
| Hitbox and hurtbox touch only at an edge | Count as hit only if Godot collision/overlap reports true; tune hitboxes for clarity. | Avoids custom fuzzy logic in MVP. |
| Hitstop begins on the same frame as hit | Emit the hit event first, then downstream feedback may freeze time. | Consumers need the event to know why hitstop started. |
| Reset occurs during active frames | Clear attack instance and hit registry; no further hit events. | Reset overrides combat. |
| Pause occurs during active frames | Suspend checks until resume; do not emit hits while paused. | Pause should not alter combat state. |
| Dummy is already in airborne state when hit by Air Slash | Emit `air_hit`; Launch & Air Juggle decides response. | Juggle owns air behavior. |
| Dummy is grounded when hit by Launcher | Emit `launcher_hit`; dummy/juggle systems consume launch tags. | Keeps ownership clear. |
| Dummy hurtbox is disabled during reset | No hit is emitted. | Reset state should be stable. |
| Player and dummy overlap at attack start | Hit still requires active frame overlap. | Contact alone is not a hit. |
| Web frame hitch skips over active frames | Implementation must avoid skipping authored active checks; use frame-step or clamped progression. | Prevents missed hits from browser stutter. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Combat State Machine | This depends on Combat | Reads current attack identity and active phase. |
| Attack Data & Timing | This depends on Timing | Reads active frames, attack IDs, and authored frame data. |
| Player Movement Controller | This depends on Movement | Reads attacker position and facing. |
| Training Dummy State System | Depends on this | Consumes `HitEvent` for hitstun, knockback, launch, land, reset behavior. |
| Launch & Air Juggle System | Depends on this | Consumes `launcher` and `air_hit` events. |
| Hit Feedback System | Depends on this | Consumes hit position/type/hitstop fields. |
| Combo Counter & Training Metrics | Depends on this | Consumes hit confirmation and combo tags. |
| Basic SFX Playback | Depends on this | Consumes hit type and position for sound. |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `light_1_hitbox_width` | 54 px | 36-80 px | Easier first hit. | Stricter spacing. |
| `light_2_hitbox_width` | 62 px | 40-88 px | Easier continuation. | Stricter spacing. |
| `light_3_hitbox_width` | 70 px | 46-96 px | More reliable third hit. | More precise third hit. |
| `launcher_hitbox_height` | 86 px | 58-120 px | Easier launch contact. | More precise launcher. |
| `air_slash_hitbox_width` | 64 px | 40-96 px | Easier air chase hit. | More demanding air chase. |
| `hurtbox_leniency_px` | 0 px | 0-12 px | More forgiving contact if implemented as expansion. | More exact visual contact. |
| `duplicate_hit_policy` | once_per_attack_instance | fixed | Not tunable for MVP. | Not tunable for MVP. |
| `light_hitstop_frames` | 3f | 1-5f | Stronger light hit feel. | Faster flow. |
| `heavy_hitstop_frames` | 4f | 2-7f | Stronger third hit. | Faster flow. |
| `launcher_hitstop_frames` | 5f | 3-8f | Heavier launch impact. | Faster launch flow. |
| `air_hitstop_frames` | 4f | 2-6f | Stronger air contact. | Faster air route. |

## Visual/Audio Requirements

This system does not play VFX/audio directly, but its event data must support the art bible's “命中优先于装饰” rule.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Hitbox active | Debug overlay only in development. | None. | Medium |
| Hurtbox active | Debug overlay only in development. | None. | Medium |
| HitEvent emitted | Hit Feedback spawns spark/flash from `hit_position`. | Basic SFX uses `hit_type`. | High |
| Duplicate hit suppressed | Debug log/overlay optional. | None. | Low |
| Miss | No VFX by default; slash VFX still plays from attack animation. | Swing SFX may still play. | Medium |

## Game Feel

### Feel Reference

The target is clean arcade hit confirmation: if the sword visibly crosses the dummy during active frames, the hit should register; if it misses, the miss should be readable. It should not feel like a tiny fighting-game hurtbox puzzle in the MVP prototype.

### Input Responsiveness

Hit detection does not respond directly to input; it responds to attack active frames. It must preserve the response budgets defined by Input and Attack Timing by avoiding expensive checks or delayed event emission.

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|--------------------------|-------|
| HitEvent after overlap | Same frame as overlap | 1 frame | Event must emit on the active frame that detects overlap. |
| Feedback trigger after HitEvent | 16.6 ms target | 1 frame | Owned by Hit Feedback, enabled by immediate event. |

### Animation Feel Targets

Hitbox active frames should line up with the strongest visible sword frames from Attack Data & Timing.

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| Light Slash 1 | From Attack Data | 3 | From Attack Data | First hit is easy to confirm. | Hitbox modest but forgiving. |
| Light Slash 2 | From Attack Data | 3 | From Attack Data | Slightly wider continuation. | Helps short combo stability. |
| Light Slash 3 | From Attack Data | 4 | From Attack Data | Heavier, larger contact. | Supports route punctuation. |
| Launcher | From Attack Data | 4 | From Attack Data | Tall upward coverage. | Must hit dummy before launch response. |
| Air Slash | From Attack Data | 4 | From Attack Data | Forgiving air follow-up. | Supports chase fantasy. |

### Impact Moments

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| HitEvent emission | 0 ms delay | Structured event emitted immediately on valid overlap. | No |
| Duplicate suppression | Same active phase | Prevents repeated hit spam from one slash. | No |
| Contact point generation | Same frame | Provides spark/shake/audio anchor. | Yes, via fallback strategy |

### Weight and Responsiveness Profile

- **Weight**: Detection itself is neutral; event tags allow downstream systems to add weight.
- **Player control**: Fairness comes from readable hitboxes and immediate hit events.
- **Snap quality**: Hits are binary and same-frame.
- **Acceleration model**: Not applicable; active frame timing drives checks.
- **Failure texture**: Misses should be explainable by spacing, active timing, or target state.

### Feel Acceptance Criteria

- [ ] Light attacks feel forgiving enough to hit the dummy at intended close range.
- [ ] Launcher reliably hits a grounded dummy when used from the intended Slash 3 spacing.
- [ ] Air Slash can hit an airborne dummy during normal chase timing once juggle is tuned.
- [ ] No single slash produces duplicate combo increments on one dummy.
- [ ] Hit sparks can spawn at believable contact positions.

## UI Requirements

No player-facing UI is required. Debug visualization is required for development.

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Hitbox shape | Debug overlay | Per active frame | Development builds. |
| Hurtbox shape | Debug overlay | Per frame or toggle | Development builds. |
| HitEvent fields | Debug console/overlay | On hit | Development builds. |
| Duplicate suppression count | Debug overlay optional | Per attack instance | Tuning builds. |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|------------|-----------------------------|--------|
| Reads current attack identity and active phase | `design/gdd/combat-state-machine.md` | Attack state identity | Data dependency |
| Reads active frame counts and attack IDs | `design/gdd/attack-data-timing.md` | Attack active frames and frame data | Data dependency |
| Reads player position/facing | `design/gdd/player-movement-controller.md` | Position and facing rules | Data dependency |
| Emits dummy response tags | `design/gdd/training-dummy-state-system.md` | Future dummy hit/launch state transitions | State trigger |
| Emits launch/air-hit fields | `design/gdd/launch-air-juggle-system.md` | Future launch trajectory and air hit rules | Data dependency |
| Emits hitstop/position/type fields | `design/gdd/hit-feedback-system.md` | Future hitstop, flash, shake, hit spark | Data dependency |
| Emits combo increment tags | `design/gdd/combo-counter-training-metrics.md` | Future combo count and metrics | Data dependency |
| Emits hit type for audio | `design/gdd/basic-sfx-playback.md` | Future hit/swing SFX choice | Data dependency |

## Acceptance Criteria

- [ ] **GIVEN** Light Slash 1 is not in active frames, **WHEN** its hitbox overlaps the dummy, **THEN** no `HitEvent` is emitted.
- [ ] **GIVEN** Light Slash 1 is in active frames, **WHEN** its hitbox overlaps an enabled dummy hurtbox, **THEN** exactly one `HitEvent` is emitted.
- [ ] **GIVEN** the same Light Slash 1 attack remains overlapping on the next active frame, **WHEN** duplicate suppression checks the target, **THEN** no second hit is emitted for that attack instance.
- [ ] **GIVEN** Light Slash 2 hits the dummy, **WHEN** the event is emitted, **THEN** `attack_id = light_slash_2`, `hit_type = light`, and `combo_increment` is present.
- [ ] **GIVEN** Launcher hits the dummy, **WHEN** the event is emitted, **THEN** `hit_type = launcher`, `launcher_hit` is present, and suggested knockback includes upward Y.
- [ ] **GIVEN** Air Slash hits an airborne dummy, **WHEN** the event is emitted, **THEN** `hit_type = air` and `air_hit` is present.
- [ ] **GIVEN** reset starts during active frames, **WHEN** hit detection updates, **THEN** active attack registries clear and no new hit event is emitted.
- [ ] **GIVEN** pause is active, **WHEN** hitboxes and hurtboxes overlap, **THEN** no new hit event is emitted until gameplay resumes.
- [ ] **GIVEN** hitstop starts from a hit event, **WHEN** the same active frame resumes, **THEN** the already-hit target is not hit again by the same attack instance.
- [ ] **GIVEN** debug overlay is enabled, **WHEN** an attack is active, **THEN** hitbox and hurtbox geometry are visible for tuning.
- [ ] Performance: MVP hit checks must remain negligible within the 16.6 ms frame budget with one player and one dummy.
- [ ] No implementation may directly modify dummy state, combo count, VFX, audio, or camera from hit detection; it must emit `HitEvent`.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Should hitboxes be rectangles only for MVP or allow authored polygons? | gameplay-programmer | Before implementation story | Provisional: rectangles only. |
| Should hurtbox leniency expand dummy hurtbox or attack hitbox? | systems-designer | During first tuning pass | Provisional: no leniency expansion until playtest. |
| Should missed attacks emit miss events for metrics? | analytics-engineer / systems-designer | Before Combo Metrics GDD approval | Provisional: no player-facing miss events, optional debug only. |
| Should active frame hitbox shapes vary per active frame? | gameplay-programmer | During implementation | Provisional: supported by data, but first pass can use one shape per attack. |
| Should Launcher hit response values live here or entirely in Launch & Air Juggle? | systems-designer | During Launch & Air Juggle GDD | Provisional: this GDD emits suggested values; juggle owns final behavior. |

