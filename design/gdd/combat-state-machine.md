# Combat State Machine

> **Status**: Designed
> **Author**: Codex
> **Last Updated**: 2026-05-09
> **Last Verified**: 2026-05-09
> **Implements Pillar**: 刀刀有重量; 连段短而完整
> **Creative Director Review (CD-GDD-ALIGN)**: Skipped — Solo mode, 2026-05-09

## Summary

Combat State Machine defines the sword fighter's combat states and legal transitions for the MVP combo: light slash 1, light slash 2, light slash 3, launcher, air slash, recovery, and return to movement. It consumes input and movement state, then decides whether a combat action can start, chain, lock movement, lock facing, or return control.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `Input & Control Mapping`, `Player Movement Controller`

## Overview

This system is the rules layer that turns player combat input into a controlled short combo. The player presses `light_attack` to step through a ground three-hit chain, presses `launcher` from an allowed ground state to start the air-chase portion, then uses `light_attack` while airborne to perform an air slash. The state machine does not own exact hitbox timing, damage, VFX, hitstop, or dummy movement; it owns which combat state is active, when a transition is legal, and what movement/facing locks the active state requests.

## Player Fantasy

The player should feel like each button press is a deliberate sword form in a compact practice sequence. The combo should be simple enough to learn in seconds, but structured enough that completing the full route feels earned: step in, land three grounded cuts, break the dummy upward, chase, and finish. Dropped combos should read as timing or positioning failures, not as unclear state rules.

## Detailed Design

### Core Rules

1. The MVP combat route is fixed: `Light Slash 1 -> Light Slash 2 -> Light Slash 3 -> Launcher -> Air Slash`.
2. The player may begin `Light Slash 1` from grounded non-combat states.
3. `Light Slash 2` can only begin from a valid chain window after `Light Slash 1`.
4. `Light Slash 3` can only begin from a valid chain window after `Light Slash 2`.
5. `Launcher` can only begin from grounded state and from one of the allowed launcher entry states.
6. MVP allowed launcher entries are:
   - directly from grounded neutral, for practice access;
   - from a valid post-`Light Slash 3` chain window, for the intended combo.
7. `Air Slash` can only begin while airborne.
8. `light_attack` maps to ground combo while grounded and to air slash while airborne.
9. `launcher` never performs an air action in MVP.
10. The state machine owns movement lock and facing lock requests, but Player Movement Controller applies the physical result.
11. The state machine owns action acceptance/rejection, but Attack Data & Timing owns exact startup, active, recovery, cancel, and buffer frame values.
12. The state machine owns combat state identity, but Hit Detection & Hit Resolution owns whether an active attack hits anything.
13. The state machine must recover to movement even if an attack misses.
14. The state machine must survive hitstop without losing the current state or incorrectly advancing timers.
15. Reset and pause override combat states according to Input & Control Mapping priorities.

### Combat States

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Combat Ready | Player is not in a combat action and gameplay is active | Accepted combat input, reset, pause | Movement is fully available; facing follows movement rules. |
| Light Slash 1 Startup | `light_attack` accepted while grounded and ready | Startup window ends, reset, pause | Requests soft movement lock and facing lock. |
| Light Slash 1 Active | Startup ends | Active window ends, hitstop, reset, pause | Emits attack phase identity for Hit Detection; keeps facing locked. |
| Light Slash 1 Recovery | Active window ends | Recovery ends or chain input accepted | Allows transition to Light Slash 2 during chain window. |
| Light Slash 2 Startup | `light_attack` accepted from Slash 1 chain window | Startup window ends, reset, pause | Requests soft movement lock and facing lock. |
| Light Slash 2 Active | Startup ends | Active window ends, hitstop, reset, pause | Emits attack phase identity for Hit Detection. |
| Light Slash 2 Recovery | Active window ends | Recovery ends or chain input accepted | Allows transition to Light Slash 3 during chain window. |
| Light Slash 3 Startup | `light_attack` accepted from Slash 2 chain window | Startup window ends, reset, pause | Requests stronger movement lock; facing remains fixed. |
| Light Slash 3 Active | Startup ends | Active window ends, hitstop, reset, pause | Emits attack phase identity; sets up launcher chain eligibility. |
| Light Slash 3 Recovery | Active window ends | Recovery ends or launcher input accepted | Allows transition to Launcher during launcher chain window. |
| Launcher Startup | `launcher` accepted from grounded neutral or Slash 3 chain window | Startup window ends, reset, pause | Requests hard movement lock and facing lock. |
| Launcher Active | Startup ends | Active window ends, hitstop, reset, pause | Emits launcher attack identity for Hit Detection. |
| Launcher Recovery | Active window ends | Recovery ends, jump/air state begins, reset, pause | Returns to movement unless launch/jump follow-up is triggered by downstream systems. |
| Air Slash Startup | `light_attack` accepted while airborne | Startup window ends, reset, pause | Requests air drift/facing lock policy from movement. |
| Air Slash Active | Startup ends | Active window ends, hitstop, reset, pause | Emits air attack identity for Hit Detection. |
| Air Slash Recovery | Active window ends | Recovery ends or landing rules take over | Returns to airborne movement or landing. |
| Hitstop Suspended | Hit Feedback requests hitstop | Hitstop duration ends | Freezes combat state timer; resumes same state and phase after hitstop. |
| Paused | Pause action accepted | Resume or reset | Combat state is suspended; no timers advance. |
| Resetting | Reset action accepted | Reset flow completes | Clears combat state to Combat Ready. |

### Transition Table

| From | Trigger | Conditions | To |
|------|---------|------------|----|
| Combat Ready | `light_attack` | Grounded, not movement-locked by reset/pause | Light Slash 1 Startup |
| Combat Ready | `launcher` | Grounded | Launcher Startup |
| Combat Ready | `light_attack` | Airborne | Air Slash Startup |
| Light Slash 1 Recovery | `light_attack` | Chain window open | Light Slash 2 Startup |
| Light Slash 2 Recovery | `light_attack` | Chain window open | Light Slash 3 Startup |
| Light Slash 3 Recovery | `launcher` | Launcher chain window open, grounded | Launcher Startup |
| Any attack phase | Hitstop event | Hit connected and feedback requests hitstop | Hitstop Suspended |
| Hitstop Suspended | Hitstop complete | No pause/reset pending | Previous attack phase |
| Any non-paused state | `pause` | Pause priority wins | Paused |
| Paused | Resume | Gameplay resumes | Previous non-paused state if valid, otherwise Combat Ready |
| Any state | `reset_training` | Reset priority wins | Resetting |
| Resetting | Reset complete | Player/dummy/metrics reset complete | Combat Ready |
| Any recovery | Recovery timer complete | No accepted chain input | Combat Ready |
| Air Slash Recovery | Landing | Player reaches floor | Combat Ready |

### Chain Windows

The state machine recognizes named windows but does not define exact frame counts. Those values are owned by Attack Data & Timing.

| Window | Opens During | Accepted Input | Intended Result |
|--------|--------------|----------------|-----------------|
| `chain_light_1_to_2` | Light Slash 1 Recovery | `light_attack` | Light Slash 2 Startup |
| `chain_light_2_to_3` | Light Slash 2 Recovery | `light_attack` | Light Slash 3 Startup |
| `chain_light_3_to_launcher` | Light Slash 3 Recovery | `launcher` | Launcher Startup |
| `air_slash_entry` | Airborne movement or post-launch chase | `light_attack` | Air Slash Startup |

### Movement and Facing Locks

| Combat State Group | Movement Lock | Facing Lock | Notes |
|--------------------|---------------|-------------|-------|
| Light Slash 1/2 Startup + Active | Soft lock | Locked | May preserve slight pre-attack momentum if Attack Data allows. |
| Light Slash 1/2 Recovery | Partial release | Locked until recovery end or chain | Supports combo rhythm without full sliding. |
| Light Slash 3 Startup + Active | Harder lock | Locked | Third hit should feel more committed. |
| Light Slash 3 Recovery | Partial release | Locked until recovery end or launcher | Sets up launcher timing. |
| Launcher Startup + Active | Hard lock | Locked | Launcher needs clear commitment and readable upward attack. |
| Launcher Recovery | Partial release | Locked until recovery end | May hand off to movement/jump follow-up later. |
| Air Slash | Air drift lock or damp | Locked | Exact air drift values belong to Attack Data & Timing. |

### Interactions with Other Systems

| System | Data Flow | Responsibility Split |
|--------|-----------|----------------------|
| Input & Control Mapping | Consumes `light_attack`, `launcher`, `pause`, `reset_training` | Input owns physical mapping and priorities; combat owns acceptance rules. |
| Player Movement Controller | Reads grounded/airborne/facing; sends lock requests | Movement owns actual velocity; combat owns when locks are requested. |
| Attack Data & Timing | Supplies frame/window definitions for each state | Timing owns exact startup/active/recovery/cancel/buffer frames; state machine owns phase names and legal transitions. |
| Hit Detection & Hit Resolution | Receives current attack identity and active phase | Hit detection owns collision and hit events; combat does not decide hit success. |
| Training Dummy State System | Reacts indirectly through hit resolution | Dummy states are not changed directly by combat state machine. |
| Launch & Air Juggle System | Uses launcher hit result and player air state | Juggle owns dummy launch behavior; combat owns launcher action eligibility. |
| Hit Feedback System | May suspend state timers through hitstop | Feedback owns hitstop duration and effect; combat preserves/resumes state. |
| Combo Counter & Training Metrics | Observes accepted attacks and hit results | Combat can expose action attempt/accepted events; combo owns scoring/count. |
| Training Room Reset Flow | Clears active combat state | Reset owns target reset state; combat returns to Combat Ready. |

## Formulas

### Combat State Transition Validity

The `can_transition` formula is defined as:

`can_transition = current_state_allows_action && movement_condition_met && chain_window_condition_met && !blocked_by_system_state`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_state_allows_action` | `S` | bool | true/false | Whether the active combat state can accept the requested action. |
| `movement_condition_met` | `M` | bool | true/false | Grounded/airborne/facing requirements from movement. |
| `chain_window_condition_met` | `C` | bool | true/false | Whether the relevant chain window is open, or not required. |
| `blocked_by_system_state` | `B` | bool | true/false | True if pause, reset, or other system lock blocks combat. |

**Output Range:** Boolean.  
**Example:** `Light Slash 2` requires `S = true`, `M = grounded`, `C = chain_light_1_to_2 open`, and `B = false`.

### Combo Step Index

The `combo_step_index` formula is defined as:

`combo_step_index = next_step(current_step, accepted_combat_action)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_step` | `N` | int | 0-5 | Current intended route position: 0 none, 1 Slash 1, 2 Slash 2, 3 Slash 3, 4 Launcher, 5 Air Slash. |
| `accepted_combat_action` | `A` | enum | light_1/light_2/light_3/launcher/air_slash/none | Combat action accepted by the state machine. |

**Output Range:** 0 to 5. Resets to 0 when the route drops or reset occurs.  
**Example:** If `current_step = 2` and `accepted_combat_action = light_3`, output becomes 3.

### State Timer Progress

The `state_elapsed_time` formula is defined as:

`state_elapsed_time = previous_elapsed_time + (delta_seconds * timer_scale)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `previous_elapsed_time` | `Tprev` | float | 0.0+ seconds | Time already spent in the current state phase. |
| `delta_seconds` | `dt` | float | 0.0-0.05 | Frame delta. |
| `timer_scale` | `K` | float | 0.0 or 1.0 | 0 during hitstop/pause, 1 during active gameplay. |

**Output Range:** 0.0 seconds upward until state exit.  
**Example:** During hitstop, `timer_scale = 0`, so combat phase timing does not advance.

### Route Drop Condition

The `route_dropped` formula is defined as:

`route_dropped = chain_window_expired || invalid_action_committed || reset_triggered || player_landed_after_air_route`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `chain_window_expired` | `W` | bool | true/false | A required chain window closed without the next accepted action. |
| `invalid_action_committed` | `I` | bool | true/false | Player entered an action that breaks the fixed route. |
| `reset_triggered` | `R` | bool | true/false | Training reset occurred. |
| `player_landed_after_air_route` | `L` | bool | true/false | Air route ended and player returned to floor. |

**Output Range:** Boolean.  
**Example:** If `chain_light_2_to_3` expires before `light_attack` is accepted, `route_dropped = true`.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player presses `light_attack` during Light Slash 1 Startup | Input is ignored by state machine unless Attack Data later defines a buffer window. | State machine should not invent buffering. |
| Player presses `light_attack` after Slash 1 chain window expires | No Slash 2 starts; state returns to Combat Ready, and a later press may start Slash 1. | Clear route drop behavior. |
| Player presses `launcher` before Slash 3 chain window | If grounded and ready, launcher may start from neutral; if already inside another attack with no launcher window, input is rejected. | Preserves practice access without breaking action commitment. |
| Player presses `launcher` while airborne | Input is rejected in MVP. | No air launcher exists. |
| Player presses `light_attack` while airborne during Air Slash Recovery | Input is rejected unless future Attack Data defines air repeat or buffer. | MVP has one air slash. |
| Player lands during Air Slash Startup or Active | Combat continues through the current phase unless implementation risk requires forced landing cancel; this must be reviewed in prototype. | Prevents abrupt action cancellation, but may need tuning. |
| Hitstop starts during a chain window | Chain window timing freezes and resumes after hitstop. | Hitstop should not punish timing. |
| Pause starts during an attack | Combat state suspends; timers do not advance. | Pause must be reliable. |
| Reset starts during an attack | Combat state clears to Resetting, then Combat Ready. | Training reset overrides all actions. |
| Player changes facing input during attack startup | Facing remains locked until the state allows release. | Attacks must read clearly and not flip unexpectedly. |
| Player is pushed or moved by future systems during attack | Combat lock policy still applies; any external displacement must be explicitly designed in that system. | Avoids hidden coupling. |
| Attack misses the dummy | State proceeds through recovery normally; hit systems do not feed back into legal transition unless later designed. | Missing should not soft-lock the player. |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Input & Control Mapping | This depends on Input | Consumes `light_attack`, `launcher`, `pause`, and `reset_training` actions. |
| Player Movement Controller | This depends on Movement | Reads grounded/airborne/facing and requests movement/facing locks. |
| Attack Data & Timing | Depends on this | Defines timings for each named combat phase and chain window. |
| Hit Detection & Hit Resolution | Depends on this | Uses current attack identity and active phase to enable hit checks. |
| Training Dummy State System | Indirect dependent | Reacts to hit results produced from combat attack identities. |
| Launch & Air Juggle System | Depends on this | Requires launcher and air slash states to exist. |
| Hit Feedback System | Depends on this | Freezes combat timers with hitstop and may react to attack phase/hit type. |
| Combo Counter & Training Metrics | Depends on this | Observes accepted attacks and route drops. |
| Training Room Reset Flow | This depends on Reset | Reset clears combat state and route state. |

## Tuning Knobs

Exact frame values are owned by Attack Data & Timing. This state-machine GDD defines the required knobs and safe intent.

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `allow_neutral_launcher` | true | true/false | Easier launcher practice without completing three slashes. | Forces full intended route before launcher. |
| `max_ground_route_step` | 4 | 3-4 | Allows launcher as part of route. | Stops route at Slash 3. |
| `max_air_route_step` | 5 | 4-5 | Allows air slash as finisher. | Removes air follow-up. |
| `chain_window_policy` | recovery_only | startup/active/recovery/custom | More forgiving if earlier windows allowed. | Stricter rhythm if recovery-only. |
| `hitstop_freezes_chain_windows` | true | true/false | Prevents hitstop from eating input timing. | Makes timing stricter but likely feels unfair. |
| `landing_cancels_air_slash` | false | true/false | If true, landing quickly returns control. | If false, air slash completion is preserved. |
| `movement_lock_policy_light` | soft | none/soft/hard | More commitment and weight. | More freedom, risk of floaty attacks. |
| `movement_lock_policy_launcher` | hard | soft/hard | Stronger launcher readability. | Easier movement correction during launcher. |
| `facing_lock_during_attacks` | true | true/false | Clearer attack direction and animation read. | Allows rapid flipping but can look messy. |

## Visual/Audio Requirements

Combat state changes must be visually legible even with placeholder art. The art bible's “读招优先” and “像素少而有劲” principles apply directly.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Light Slash 1 accepted | Immediate first slash startup pose. | Light swing SFX later owned by audio/combat feedback. | High |
| Light Slash 2 accepted | Distinct second slash pose or arc direction. | Light swing SFX variation. | High |
| Light Slash 3 accepted | Heavier third slash pose, slightly stronger anticipation. | Slightly heavier swing SFX. | High |
| Launcher accepted | Clear upward slash anticipation and vertical sword arc. | Launcher swing accent. | High |
| Air Slash accepted | Readable airborne slash pose. | Air slash SFX. | High |
| Route dropped | No punitive VFX in MVP; combo UI may later signal drop. | Optional low feedback owned by metrics/UI. | Low |
| State rejected input | No active-play error VFX. | None by default. | Low |

## Game Feel

### Feel Reference

The intended feel is a compact arcade sword combo: quick first hit, clear second and third rhythm, committed launcher, then a readable air follow-up. It should not feel like a free-form character action game with many cancels; the point is one short route that can be learned, repeated, and tuned.

### Input Responsiveness

| Action | Max Input-to-Response Latency (ms) | Frame Budget (at 60fps) | Notes |
|--------|-----------------------------------|--------------------------|-------|
| Light Slash 1 accepted | 50.0 ms | 3 frames | Matches Input GDD attack response budget. |
| Light Slash 2 accepted | 50.0 ms | 3 frames | Startup change must be visible when accepted. |
| Light Slash 3 accepted | 50.0 ms | 3 frames | Can feel heavier, but acceptance must be visible. |
| Launcher accepted | 50.0 ms | 3 frames | Heavier anticipation is allowed after visible response begins. |
| Air Slash accepted | 50.0 ms | 3 frames | Must be readable before dummy falls out of chase window. |
| Rejected input | No explicit feedback by default | N/A | Avoid noisy errors during practice. |

### Animation Feel Targets

Exact frame counts are delegated to Attack Data & Timing, but these intent targets constrain that future GDD.

| Animation | Startup Frames | Active Frames | Recovery Frames | Feel Goal | Notes |
|-----------|---------------|--------------|----------------|-----------|-------|
| Light Slash 1 | Short | Short | Short | Fast opener | Easiest route entry. |
| Light Slash 2 | Short | Short | Short-medium | Rhythmic continuation | Should clearly differ from Slash 1. |
| Light Slash 3 | Medium | Short-medium | Medium | Heavier route punctuation | Sets up launcher. |
| Launcher | Medium | Short-medium | Medium | Committed upward strike | Must read vertically. |
| Air Slash | Short-medium | Short | Medium | Chase finisher | Must work near jump apex and descent. |

### Impact Moments

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Action accepted | 0-50 ms | Visible pose/sword startup confirms input. | Indirectly via timing |
| Route step advanced | Instant | Internal route index advances; combo UI may later react. | Yes |
| Chain window opened | N/A player-hidden | Debug overlay may show during tuning only. | Yes |
| Route dropped | N/A player-hidden | Combo metrics may later reset/decay. | Yes |

### Weight and Responsiveness Profile

- **Weight**: Starts light, grows heavier by Slash 3 and Launcher.
- **Player control**: High outside combat; moderate to low during active attacks.
- **Snap quality**: State transitions should feel crisp and discrete.
- **Acceleration model**: Combat actions begin from accepted input quickly, then commitment is expressed by lock/recovery.
- **Failure texture**: Drops should feel like “I mistimed the next input” or “I was airborne/grounded wrong,” not like the state machine ignored a valid command.

### Feel Acceptance Criteria

- [ ] A new player can discover `J, J, J, K` as the ground route within a short practice session.
- [ ] The third slash and launcher feel more committed than the first two slashes.
- [ ] Chain windows feel fair once Attack Data & Timing values are tuned.
- [ ] Hitstop never causes the player to miss a chain window unfairly.
- [ ] Air slash acceptance feels clear while airborne.

## UI Requirements

Combat State Machine has minimal direct UI. Player-facing combo display belongs to Combo Counter & Training Metrics.

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Current combat state | Debug overlay only | Per state change | Prototype tuning only, not player-facing. |
| Chain window open/closed | Debug overlay only | Per frame during tuning | Useful for tuning, hidden in player build. |
| Combo route progress | HUD / combo UI | On accepted action or hit | Owned by Combo Counter & Training Metrics. |
| Control hint for next route step | Optional tutorial hint | On route step change | Owned by Training HUD Visual Pass. |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|------------|-----------------------------|--------|
| Consumes `light_attack`, `launcher`, `pause`, `reset_training` | `design/gdd/input-control-mapping.md` | Named action contract and input priority | Data dependency |
| Reads grounded/airborne/facing and requests locks | `design/gdd/player-movement-controller.md` | Movement states, facing rules, movement locks | Data dependency |
| Delegates frame values and chain window durations | `design/gdd/attack-data-timing.md` | Future startup/active/recovery/buffer windows | Ownership handoff |
| Emits attack phase identity | `design/gdd/hit-detection-hit-resolution.md` | Future hitbox enable/resolve rules | Data dependency |
| Launcher state enables launch behavior | `design/gdd/launch-air-juggle-system.md` | Future launch and air chase rules | State trigger |
| Hitstop suspends combat timers | `design/gdd/hit-feedback-system.md` | Future hitstop duration and pause behavior | Rule dependency |
| Route progress feeds combo UI | `design/gdd/combo-counter-training-metrics.md` | Future combo tracking and display | Data dependency |
| Reset clears combat state | `design/gdd/training-room-reset-flow.md` | Future reset behavior | State trigger |

## Acceptance Criteria

- [ ] **GIVEN** the player is grounded and in Combat Ready, **WHEN** `light_attack` is pressed, **THEN** combat enters Light Slash 1 Startup.
- [ ] **GIVEN** the player is in Light Slash 1 Recovery and `chain_light_1_to_2` is open, **WHEN** `light_attack` is pressed, **THEN** combat enters Light Slash 2 Startup.
- [ ] **GIVEN** the player is in Light Slash 2 Recovery and `chain_light_2_to_3` is open, **WHEN** `light_attack` is pressed, **THEN** combat enters Light Slash 3 Startup.
- [ ] **GIVEN** the player is in Light Slash 3 Recovery and `chain_light_3_to_launcher` is open, **WHEN** `launcher` is pressed, **THEN** combat enters Launcher Startup.
- [ ] **GIVEN** the player is grounded and in Combat Ready, **WHEN** `launcher` is pressed and `allow_neutral_launcher` is true, **THEN** combat enters Launcher Startup.
- [ ] **GIVEN** the player is airborne and in Combat Ready, **WHEN** `light_attack` is pressed, **THEN** combat enters Air Slash Startup.
- [ ] **GIVEN** the player is airborne, **WHEN** `launcher` is pressed, **THEN** no launcher state starts.
- [ ] **GIVEN** a chain window expires without the required input, **WHEN** recovery completes, **THEN** combat returns to Combat Ready and route step resets.
- [ ] **GIVEN** hitstop starts during an attack active or recovery phase, **WHEN** hitstop is active, **THEN** combat state timer does not advance.
- [ ] **GIVEN** hitstop ends, **WHEN** no pause or reset is pending, **THEN** combat resumes the exact previous attack phase.
- [ ] **GIVEN** pause is pressed during any combat state, **WHEN** pause takes effect, **THEN** combat timers stop and no new combat input is accepted until resume.
- [ ] **GIVEN** reset is pressed during any combat state, **WHEN** reset completes, **THEN** combat state becomes Combat Ready and route step becomes 0.
- [ ] **GIVEN** any attack startup or active state, **WHEN** facing input changes, **THEN** facing remains locked until the state releases it.
- [ ] Performance: state-machine update should be negligible within the 16.6 ms frame budget.
- [ ] No implementation may hardcode timing values inside transition logic; frame/window values must come from Attack Data & Timing or tunable data.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Should neutral launcher remain enabled after onboarding? | game-designer | After first combat prototype | Provisional: enabled for training accessibility. |
| Should landing cancel Air Slash or let it finish? | systems-designer | During Attack Data & Timing GDD | Provisional: air slash continues unless playtest feels bad. |
| Should chain input buffering be accepted before recovery windows? | systems-designer | During Attack Data & Timing GDD | Provisional: state machine supports named windows only; exact buffer policy undecided. |
| Should missed hits still allow route chaining? | game-designer | During Hit Detection & Combo Metrics GDDs | Provisional: route chaining is input/state-based, hit combo is tracked separately. |
| Should combat route progress reset on any non-route action? | systems-designer | During Combo Counter & Metrics GDD | Provisional: yes for fixed-route clarity. |

