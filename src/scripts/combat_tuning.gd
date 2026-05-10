extends Resource

const GROUND_Y: float = 560.0
const PLAYER_START: Vector2 = Vector2(360.0, GROUND_Y)
const DUMMY_START: Vector2 = Vector2(760.0, GROUND_Y)
const STAGE_LEFT: float = 120.0
const STAGE_RIGHT: float = 1160.0
const STAGE_DEPTH_TOP: float = -78.0
const STAGE_DEPTH_BOTTOM: float = 78.0
const DEPTH_SPEED: float = 150.0
const DEPTH_CHASE_SPEED: float = 90.0
const ENEMY_ATTACK_DEPTH_RANGE: float = 20.0
const DUMMY_CORPSE_DURATION: float = 0.75
const DUMMY_RESPAWN_OFFSET_X: float = 86.0

const GROUND_MAX_SPEED: float = 220.0
const GROUND_RUN_MAX_SPEED: float = 330.0
const GROUND_ACCELERATION: float = 1800.0
const GROUND_RUN_ACCELERATION: float = 2400.0
const GROUND_DECELERATION: float = 2400.0
const RUN_DOUBLE_TAP_WINDOW: float = 0.28
const AIR_MAX_SPEED: float = 190.0
const AIR_ACCELERATION: float = 900.0
const GRAVITY: float = 1100.0
const JUMP_HEIGHT: float = 120.0
const MAX_FALL_SPEED: float = 850.0
const AIR_SLASH_MIN_FALL_SPEED: float = 170.0

const PLAYER_MAX_HEALTH: int = 120
const DUMMY_MAX_HEALTH: int = 180
const METER_MAX: int = 300
const KI_STRIKE_COST: int = 30
const SUPER_COST: int = 100

const HITSTOP_LIGHT: int = 3
const HITSTOP_HEAVY: int = 4
const HITSTOP_LAUNCHER: int = 5
const HITSTOP_AIR: int = 4
const HITSTOP_KI: int = 5
const HITSTOP_SUPER: int = 10

const SHAKE_LIGHT: float = 4.0
const SHAKE_HEAVY: float = 7.0
const SHAKE_LAUNCHER: float = 9.0
const SHAKE_AIR: float = 6.0
const SHAKE_KI: float = 8.0
const SHAKE_SUPER: float = 16.0

const ATTACKS: Dictionary = {
	&"light_1": {
		"display": "Light Slash 1",
		"startup": 4,
		"active": 3,
		"recovery": 10,
		"chain_start": 2,
		"chain_end": 8,
		"buffer": 5,
		"next_action": &"light_attack",
		"next_attack": &"light_2",
		"hit_type": &"light",
		"hitstop": HITSTOP_LIGHT,
		"shake": SHAKE_LIGHT,
		"knockback": Vector2(22.0, 0.0),
		"damage": 8,
		"meter_gain": 10,
		"cost": 0,
		"allow_downed": false,
		"max_hits": 1,
		"depth_range": 18.0,
		"advance": 120.0,
		"hitbox": Rect2(42.0, -64.0, 62.0, 34.0),
	},
	&"light_2": {
		"display": "Light Slash 2",
		"startup": 5,
		"active": 3,
		"recovery": 11,
		"chain_start": 2,
		"chain_end": 9,
		"buffer": 5,
		"next_action": &"light_attack",
		"next_attack": &"light_3",
		"hit_type": &"light",
		"hitstop": HITSTOP_LIGHT,
		"shake": SHAKE_LIGHT,
		"knockback": Vector2(24.0, 0.0),
		"damage": 9,
		"meter_gain": 10,
		"cost": 0,
		"allow_downed": false,
		"max_hits": 1,
		"depth_range": 20.0,
		"advance": 135.0,
		"hitbox": Rect2(48.0, -68.0, 70.0, 38.0),
	},
	&"light_3": {
		"display": "Light Slash 3",
		"startup": 7,
		"active": 4,
		"recovery": 12,
		"chain_start": 3,
		"chain_end": 4,
		"buffer": 0,
		"next_action": &"auto",
		"next_attack": &"launcher",
		"auto_chain": true,
		"hit_type": &"heavy",
		"hitstop": HITSTOP_HEAVY,
		"shake": SHAKE_HEAVY,
		"knockback": Vector2(26.0, 0.0),
		"damage": 11,
		"meter_gain": 12,
		"cost": 0,
		"allow_downed": false,
		"max_hits": 1,
		"depth_range": 22.0,
		"advance": 155.0,
		"hitbox": Rect2(52.0, -64.0, 78.0, 42.0),
	},
	&"launcher": {
		"display": "Light Slash 4 - Launcher",
		"startup": 8,
		"active": 4,
		"recovery": 16,
		"chain_start": -1,
		"chain_end": -1,
		"special_chain_start": 4,
		"special_chain_end": 14,
		"buffer": 4,
		"next_action": &"",
		"next_attack": &"",
		"hit_type": &"launcher",
		"hitstop": HITSTOP_LAUNCHER,
		"shake": SHAKE_LAUNCHER,
		"knockback": Vector2(28.0, -420.0),
		"damage": 14,
		"meter_gain": 16,
		"cost": 0,
		"allow_downed": false,
		"max_hits": 1,
		"depth_range": 24.0,
		"advance": 95.0,
		"hitbox": Rect2(38.0, -112.0, 72.0, 96.0),
	},
	&"air_slash": {
		"display": "Air Slash",
		"startup": 5,
		"active": 4,
		"recovery": 14,
		"chain_start": -1,
		"chain_end": -1,
		"buffer": 0,
		"next_action": &"",
		"next_attack": &"",
		"hit_type": &"air",
		"hitstop": 2,
		"shake": SHAKE_AIR,
		"knockback": Vector2(75.0, 120.0),
		"damage": 8,
		"meter_gain": 8,
		"cost": 0,
		"allow_downed": false,
		"max_hits": 1,
		"depth_range": 22.0,
		"advance": 0.0,
		"hitbox": Rect2(44.0, -66.0, 64.0, 46.0),
	},
	&"ki_blast": {
		"display": "Ki Strike",
		"startup": 7,
		"active": 12,
		"recovery": 18,
		"chain_start": -1,
		"chain_end": -1,
		"special_chain_start": 5,
		"special_chain_end": 15,
		"buffer": 6,
		"next_action": &"",
		"next_attack": &"",
		"hit_type": &"ki",
		"hitstop": HITSTOP_KI,
		"shake": SHAKE_KI,
		"knockback": Vector2(34.0, -120.0),
		"damage": 12,
		"meter_gain": 0,
		"cost": KI_STRIKE_COST,
		"allow_downed": true,
		"max_hits": 3,
		"depth_range": 44.0,
		"advance": 45.0,
		"hitbox": Rect2(28.0, -180.0, 230.0, 230.0),
	},
	&"super": {
		"display": "Guarding Sky Rupture",
		"startup": 10,
		"active": 24,
		"recovery": 28,
		"chain_start": -1,
		"chain_end": -1,
		"buffer": 8,
		"next_action": &"",
		"next_attack": &"",
		"hit_type": &"super",
		"hitstop": HITSTOP_SUPER,
		"shake": SHAKE_SUPER,
		"knockback": Vector2(360.0, -520.0),
		"damage": 18,
		"meter_gain": 0,
		"cost": SUPER_COST,
		"allow_downed": true,
		"max_hits": 5,
		"guard_time": 1.25,
		"depth_range": 84.0,
		"advance": 0.0,
		"hitbox": Rect2(-48.0, -260.0, 360.0, 330.0),
	},
}
