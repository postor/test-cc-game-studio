extends Node2D

const GROUND_Y: float = 575.0
const GRAVITY: float = 1500.0
const HURT_KNOCKBACK_SPEED: float = 110.0
const LAUNCH_KNOCKBACK_SPEED: float = 330.0

enum State { IDLE, HURT, LAUNCHED }

var depth: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var state: State = State.IDLE
var hurt_timer: float = 0.0
var hit_flash_timer: float = 0.0
var active_hitstun_scale: float = 1.0


func reset_enemy(start_position: Vector2, start_depth: float = 0.0) -> void:
	depth = start_depth
	position = start_position
	velocity = Vector2.ZERO
	state = State.IDLE
	hurt_timer = 0.0
	hit_flash_timer = 0.0
	active_hitstun_scale = 1.0
	queue_redraw()


func tick(delta: float) -> void:
	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	match state:
		State.HURT:
			hurt_timer = maxf(hurt_timer - delta, 0.0)
			position.x = clampf(position.x + velocity.x * delta, 120.0, 1160.0)
			velocity.x = move_toward(velocity.x, 0.0, 420.0 * delta)
			if hurt_timer <= 0.0:
				state = State.IDLE
		State.LAUNCHED:
			position.x = clampf(position.x + velocity.x * delta, 120.0, 1160.0)
			position.y += velocity.y * delta
			velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
			var ground_y: float = GROUND_Y + depth
			if position.y >= ground_y:
				position.y = ground_y
				velocity = Vector2.ZERO
				state = State.HURT
				hurt_timer = 0.28 * active_hitstun_scale
		_:
			position.y = GROUND_Y + depth
	queue_redraw()


func apply_hit(direction: int, final_hit: bool, hitstun_scale: float = 1.0) -> void:
	var dir: float = float(direction)
	active_hitstun_scale = hitstun_scale
	if final_hit:
		state = State.LAUNCHED
		velocity = Vector2(LAUNCH_KNOCKBACK_SPEED * dir, -560.0)
	else:
		state = State.HURT
		hurt_timer = 0.24 * hitstun_scale
		velocity = Vector2(HURT_KNOCKBACK_SPEED * dir, 0.0)
	hit_flash_timer = 0.12
	queue_redraw()


func hurtbox() -> Rect2:
	return Rect2(position + Vector2(-34.0, -116.0), Vector2(68.0, 116.0))


func _draw() -> void:
	var body_color: Color = Color("#8E2F2D") if hit_flash_timer > 0.0 else Color("#4E5960")
	var outline: Color = Color("#141414")
	if state == State.LAUNCHED:
		draw_rect(Rect2(Vector2(-50.0, -58.0), Vector2(100.0, 34.0)), body_color)
		draw_rect(Rect2(Vector2(-53.0, -61.0), Vector2(106.0, 40.0)), outline, false, 3.0)
		draw_circle(Vector2(42.0, -48.0), 16.0, body_color)
		draw_circle(Vector2(42.0, -48.0), 18.0, outline, false, 3.0)
	else:
		draw_rect(Rect2(Vector2(-22.0, -90.0), Vector2(44.0, 86.0)), body_color)
		draw_rect(Rect2(Vector2(-25.0, -93.0), Vector2(50.0, 92.0)), outline, false, 3.0)
		draw_circle(Vector2(0.0, -112.0), 18.0, body_color)
		draw_circle(Vector2(0.0, -112.0), 20.0, outline, false, 3.0)
	draw_circle(Vector2(-14.0, -4.0), 6.0, Color("#F2B84B"))
	draw_circle(Vector2(14.0, -4.0), 6.0, Color("#F2B84B"))
