# Level And Enemy Plan

## Combat Assumptions

- The arena has horizontal movement, vertical jump height, and a separate ground-depth axis.
- Light attack builds qi and auto-launches on the fourth hit.
- Ki strike costs 30 qi, hits a wider depth band than light attacks, and can hit downed enemies.
- Super costs 100 qi, has self-protection, heavy damage, a wide depth band, and can hit downed enemies.
- Downed enemies hit by ki strike or super bounce slightly and remain downed.

## Enemy Classes

### Small Soldier
- Role: basic pressure and qi-building target.
- Moves toward the player across horizontal and depth axes.
- Uses a short-range normal attack with narrow depth range.
- Dies quickly and teaches light-chain launch routes.

### Dasher Soldier
- Role: teaches reading long windup and moving across depth.
- Uses the base soldier normal attack at close range.
- At medium range, starts a long windup then rushes forward.
- Counterplay: move up/down before the dash becomes active, or spend super for protection.

### Ranged Soldier
- Role: forces the player to approach and use depth movement under pressure.
- Keeps medium distance from the player.
- Fires a slow qi bolt after a visible windup.
- Projectile travels horizontally on the current depth lane and only hits if the player is close enough in depth.
- Counterplay: change depth, jump over poorly timed shots, close distance, or use super protection.

### Heavy Guard
- Role: durable advanced soldier.
- Higher health, slower movement, shorter hitstun feel.
- Punishes repeated light attacks if the player does not manage qi.
- Counterplay: launch into ki strike, or super through pressure.

### Qi Adept
- Role: advanced ranged/control enemy.
- Uses a wider depth qi strike instead of a simple bolt.
- Pressures downed and airborne states more reliably than basic enemies.
- Counterplay: bait the windup, step out of depth, punish recovery.

## Boss: Break-Sky Warden

The boss is built as a full-system check rather than a pure damage sponge.

### Special Ability 1: Guard Pulse
- A self-protecting radial burst similar to the player's super guard, but weaker.
- Used when the player stays too close for too long or after the boss exits knockdown.
- Deals moderate damage and pushes the player away.
- Counterplay: respect the warning pulse, step out of depth or spend super.

### Special Ability 2: Depth Sweep
- A wide ground shockwave across multiple depth lanes.
- Hits standing and downed players unless they move out of the telegraphed band.
- Used more often in phase 2+.
- Counterplay: move to a safe depth lane or jump during the sweep window.

### Special Ability 3: Air-Catch Counter
- If launched, the boss may spend a cooldown to arrest vertical momentum and strike downward.
- Prevents infinite launch loops without making launch useless.
- Counterplay: route into ki strike/super quickly instead of slow repeated light attacks.

### Special Ability 4: Execute Dash
- Low-health phase dash with a longer telegraph, higher speed, and stronger damage.
- Tracks depth only during windup, not during active dash.
- Counterplay: change depth after the lock-in, or super through it.

## Four-Level Flow

Each level now starts in an independent briefing scene mode before combat actors are shown. The flow is:

1. Level briefing scene: shows `LEVEL N`, title, combat lesson, area count, time limit, and terrain hazard note.
2. Area transition scene: short `ENTERING` / `AREA N` interstitial before each combat area.
3. Combat scene: player explores the current area, fights the configured enemy group, and watches the shared area timer.
4. Result scene: `GAME OVER` for defeat, timeout, or player fall; `DEMO CLEAR` after the final boss prototype route.

Broken ground is a depth-band hazard, not a full-width blocker. Every combat area must keep at least one continuous safe depth lane across the arena so the map cannot become impossible to cross. Enemies that enter broken ground die immediately; the player entering broken ground triggers Game Over.

Enemy AI receives the active area's broken-ground data. Small soldiers, ranged soldiers, dashers, and bosses avoid voluntarily walking or dashing into known hazards by changing depth before crossing a dangerous band. Forced movement from player hits can still knock enemies into hazards, preserving traps as a combat tool rather than making enemies immune to terrain.

### Level 1: Training Alley
- Wave 1: 1 small soldier.
- Wave 2: 2 small soldiers.
- Wave 3: 1 small soldier + 1 dasher soldier.
- Lesson: light chain, auto-launch, depth movement, dash telegraph.
- Prototype areas:
  - Gate: no holes, two small soldiers.
  - Drain Walk: upper-lane hole, small + dasher.
  - Back Alley: lower-lane hole, dasher + small.

### Level 2: Bridge Crossfire
- Wave 1: 2 small soldiers.
- Wave 2: 1 ranged soldier + 1 small soldier.
- Wave 3: 1 dasher soldier + 1 ranged soldier + 1 downed-heavy target.
- Lesson: approach ranged pressure, use depth evasion, sweep downed targets with ki/super.
- Prototype areas:
  - Bridgehead: central depth hole, small + ranged.
  - Broken Span: split upper/lower holes, ranged + dasher.
  - Far Rail: center-lane hole, dasher + ranged.

### Level 3: Dojo Trial
- Wave 1: 2 dasher soldiers.
- Wave 2: 1 heavy guard + 1 ranged soldier.
- Wave 3: 1 qi adept + 1 dasher soldier + 1 small soldier.
- Final wave: 1 heavy guard + 1 qi adept.
- Lesson: target priority, qi spending, defensive super use.
- Prototype areas:
  - Outer Mat: no holes, two dashers.
  - Split Floor: upper/lower holes, ranged + dasher.
  - Inner Trial: staggered holes, four-enemy pressure group.

### Level 4: Break-Sky Warden
- Phase 1: normal attacks, dash, basic depth chase.
- Phase 2: adds depth sweep and guard pulse.
- Phase 3: adds execute dash and air-catch counter.
- Lesson: complete combat-system mastery.
- Prototype areas:
  - Ritual Gate: upper-lane hole, dasher + ranged.
  - Warden Floor: split edge holes, boss + ranged.
  - Break-Sky Ring: center-lane fracture, boss + dasher + ranged.

## Current Prototype Implementation Target

The current Godot prototype should first support:
- Two simultaneous enemies with type variants.
- Small soldier, dasher soldier, ranged soldier, and boss prototype.
- Ranged projectile pressure with depth-aware collision.
- Boss guard pulse and depth sweep as visible, testable special attacks.
- Existing tests updated or extended to cover enemy type behavior.
