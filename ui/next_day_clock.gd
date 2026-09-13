## Source next-day animation clock, persisted inside round_transition.
## [SRC: NextDay_Round_AnimationLoop_Helper.c Update 0x2fd810;
## NextDay_Round_Helper.c Continue 0x2fd9e0; NextDay_Day_Speed_Syncer.c;
## GameScene helpers 12543/16020/13224; NextDay_Night/Day.anim.]
class_name NextDayClock
extends RefCounted

static func create() -> Dictionary:
	return {"time": 0.0, "speed": 1.0, "speed_change": 0.0,
		"continue": false, "night_time": 0.0, "day_time": 0.0, "day_speed": 1.0}

static func continue_to_day(clock: Dictionary) -> void:
	clock["continue"] = true
	var left := (9.0 - float(clock.time)) / 1.0
	clock.day_speed = 4.0 / left if left > 0.0 else 1.0

static func tick(clock: Dictionary, delta: float, phase: String) -> void:
	var old_time := float(clock.time)
	var speed := float(clock.speed)
	if not bool(clock["continue"]):
		if old_time > 3.0:
			if speed <= 0.125:
				clock.speed_change = 0.0
			else:
				clock.speed_change += delta
				speed = lerpf(1.0, 0.125, clampf(float(clock.speed_change) / 10.0, 0.0, 1.0))
	else:
		if speed >= 1.0:
			clock.speed_change = 0.0
		else:
			clock.speed_change += delta
			speed = lerpf(speed, 1.0, clampf(float(clock.speed_change) / 10.0, 0.0, 1.0))
	clock.speed = speed
	clock.time = old_time + delta * speed
	if not bool(clock["continue"]) and float(clock.time) > 6.0:
		clock.time -= 3.0
	if phase == "night_enter":
		clock.night_time = minf(4.0, float(clock.night_time) + delta)
	elif phase == "day_enter":
		clock.day_time = minf(4.0, float(clock.day_time) + delta * float(clock.day_speed))

static func hermite(t: float, duration: float, a: float, b: float, out_slope: float, in_slope: float) -> float:
	var u := clampf(t / duration, 0.0, 1.0)
	return (2*u*u*u-3*u*u+1)*a + (u*u*u-2*u*u+u)*duration*out_slope + (-2*u*u*u+3*u*u)*b + (u*u*u-u*u)*duration*in_slope

static func mask_position(clock: Dictionary, day: bool) -> Vector2:
	if day:
		return Vector2(hermite(clock.day_time, 4, 30, 111, 42.89641, 0), hermite(clock.day_time, 4, -17.1, -85.1, -36.1996, 0))
	return Vector2(hermite(clock.night_time, 4, -34.9, 30, 0, 24.482567), hermite(clock.night_time, 4, 37.4, -17.1, 0, -28.591768))

static func ring_degrees(clock: Dictionary, ring: int) -> float:
	# [SRC: AnimationClip/ND_round01, ND_round03, ND_round04 Euler z keys.]
	var keys: Array = [
		[[0,0,0,0], [3,180,95.20098,120], [6,540,120,131.11766], [9,720,-0.00000035762787,0]],
		[[0,0,0,0], [3,-360,-195.19563,-240], [6,-1080,-240,-264.71265], [9,-1440,0.00001001358,0]],
		[[0,0,0,0], [3,360,383.52902,480], [6,1800,480,401.62646], [9,2160,-0.00004005432,0]],
	][ring]
	var t := clampf(float(clock.time), 0, 9)
	for i in range(3):
		var a: Array = keys[i]
		var b: Array = keys[i+1]
		if t <= float(b[0]):
			return -hermite(t-float(a[0]), float(b[0])-float(a[0]), a[1], b[1], a[3], b[2])
	return -float(keys[3][1])
