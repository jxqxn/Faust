extends RefCounted

## [SRC: UnityPlayer.dll 0xf0490 -> 0x5949c0; permutation 0x199a690.
## Registration loop 0xfd7bf0/0xfd7c01; native oracle in docs/audit.]
const PERMUTATION := [
	151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,
	140,36,103,30,69,142,8,99,37,240,21,10,23,190,6,148,
	247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,
	57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,
	74,165,71,134,139,48,27,166,77,146,158,231,83,111,229,122,
	60,211,133,230,220,105,92,41,55,46,245,40,244,102,143,54,
	65,25,63,161,1,216,80,73,209,76,132,187,208,89,18,169,
	200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,
	52,217,226,250,124,123,5,202,38,147,118,126,255,82,85,212,
	207,206,59,227,47,16,58,17,182,189,28,42,223,183,170,213,
	119,248,152,2,44,154,163,70,221,153,101,155,167,43,172,9,
	129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,
	218,246,97,228,251,34,242,193,238,210,144,12,191,179,162,241,
	81,51,145,235,249,14,239,107,49,192,214,31,181,199,106,157,
	184,84,204,176,115,121,50,45,127,4,150,254,138,236,205,93,
	222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
]

static func f(value: float) -> float:
	return PackedFloat32Array([value])[0]

static func _p(index: int) -> int:
	return PERMUTATION[index & 255]

static func _fade(value: float) -> float:
	var t := minf(1.0, value)
	return f(f(f(f(f(t * 6.0) - 15.0) * t) + 10.0) * f(f(t * t) * t))

static func _gradient(hash_value: int, x: float, y: float) -> float:
	var h := hash_value & 15
	var u := x if h < 8 else y
	var v := y if h < 4 else (x if h == 12 or h == 14 else 0.0)
	return f((-u if h & 1 else u) + (-v if h & 2 else v))

static func _lerp(a: float, b: float, t: float) -> float:
	return f(a + f(f(b - a) * t))

static func perlin(x: float, y: float) -> float:
	x = absf(f(x))
	y = absf(f(y))
	var ix := int(x)
	var iy := int(y)
	x = f(x - float(ix))
	y = f(y - float(iy))
	var a := _p(ix) + (iy & 255)
	var b := _p(ix + 1) + (iy & 255)
	var lower := _lerp(_gradient(_p(_p(a)), x, y), _gradient(_p(_p(b)), f(x - 1.0), y), _fade(x))
	var upper := _lerp(_gradient(_p(_p(a + 1)), x, f(y - 1.0)), _gradient(_p(_p(b + 1)), f(x - 1.0), f(y - 1.0)), _fade(x))
	return f(f(_lerp(lower, upper, _fade(y)) + f(0.69)) / f(1.483))

## [SRC: GameAssembly.dll Mathf.SmoothDamp 0x197a3e0, dump.cs:343100.]
static func smooth_damp(current: float, velocity: float, delta: float, speed := 10.0) -> Vector2:
	current = f(current)
	velocity = f(velocity)
	delta = f(delta)
	var smooth_time := maxf(f(0.0001), delta)
	var omega := f(2.0 / smooth_time)
	var x := f(omega * delta)
	var denominator := f(f(f(f(x * f(0.48)) * x) + f(1.0 + x)) + f(f(f(x * f(0.235)) * x) * x))
	var decay := f(1.0 / denominator)
	var maximum := f(smooth_time * f(speed))
	var change := clampf(current, -maximum, maximum)
	var temp := f(f(f(omega * change) + velocity) * delta)
	var next_velocity := f(f(velocity - f(temp * omega)) * decay)
	var output := f(f(current - change) + f(f(temp + change) * decay))
	if (-current > 0.0) == (output > 0.0):
		output = 0.0
		next_velocity = f(0.0 / delta) if delta != 0.0 else NAN
	return Vector2(output, next_velocity)

static func position_offset(seed: float, elapsed: float, frequency: float, strength: float, intensity: Vector2) -> Vector2:
	var t := f(fmod(f(elapsed), f(TAU)))
	var phase := f(t * f(frequency))
	var nx := perlin(f(seed + 1.0), phase)
	var ny := perlin(f(seed + 2.0), phase)
	return Vector2(f(f(f(f(nx + nx) - 1.0) * intensity.x) * strength), f(f(f(f(ny + ny) - 1.0) * intensity.y) * strength))
