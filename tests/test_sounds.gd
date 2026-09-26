extends "res://addons/woldui/tests/wold_test_base.gd"
## The built-in UI sounds, measured: level, clean edges, pitch and direction.
## Whether they sound nice is for ears; these keep them in the ballpark.


func _run() -> void:
	var set := WoldSounds.builtin()
	var s := {}
	for slot in WoldSoundSet.SLOTS:
		s[slot] = WoldSounds._floats(set.stream(slot))
	_levels(s)
	_edges(s)
	_pitch(s)
	finish(9)


func _peak(a: PackedFloat32Array) -> float:
	var p := 0.0
	for v in a:
		p = maxf(p, absf(v))
	return p


func _rms(a: PackedFloat32Array) -> float:
	var sum := 0.0
	for v in a:
		sum += v * v
	return sqrt(sum / maxf(a.size(), 1.0))


# rough pitch from zero crossings; fine for the tonal sounds
func _hz(a: PackedFloat32Array) -> float:
	var crossings := 0
	for i in range(1, a.size()):
		if (a[i - 1] < 0.0) != (a[i] < 0.0):
			crossings += 1
	return crossings / 2.0 / (a.size() / float(WoldSounds.RATE))


func _half(a: PackedFloat32Array, second: bool) -> PackedFloat32Array:
	var mid := a.size() / 2
	return a.slice(mid) if second else a.slice(0, mid)


func _levels(s: Dictionary) -> void:
	var bad := []
	for slot in s:
		var p := _peak(s[slot])
		if p < 0.08 or p > 0.95:
			bad.append("%s %.2f" % [slot, p])
	check(bad.is_empty(), "every sound is audible and none clips (%s)" % [bad])
	check(_rms(s.hover) < _rms(s.click) * 0.8 and _rms(s.focus) < _rms(s.confirm) * 0.8, "hover and focus sit under the clicks, they happen all the time")
	var long := []
	for slot in s:
		var secs: float = s[slot].size() / float(WoldSounds.RATE)
		if secs > 0.35 or (slot in ["hover", "focus"] and secs > 0.08):
			long.append("%s %.3f" % [slot, secs])
	check(long.is_empty(), "short enough to not trail behind the UI (%s)" % [long])


func _edges(s: Dictionary) -> void:
	var clicky := []
	var offset := []
	for slot in s:
		var a: PackedFloat32Array = s[slot]
		var edge := 0.0
		# a pop is a jump right at the ends; a fade is fine
		for i in 4:
			edge = maxf(edge, maxf(absf(a[i]), absf(a[a.size() - 1 - i])))
		if edge > 0.03:
			clicky.append("%s %.3f" % [slot, edge])
		var mean := 0.0
		for v in a:
			mean += v
		if absf(mean / a.size()) > 0.02:
			offset.append(slot)
	check(clicky.is_empty(), "each starts and ends near silence, no pops (%s)" % [clicky])
	check(offset.is_empty(), "no DC offset (%s)" % [offset])


func _pitch(s: Dictionary) -> void:
	check(_hz(s.hover) < 1800.0 and _hz(s.focus) < 1800.0, "hover and focus aren't shrill (%.0f, %.0f Hz)" % [_hz(s.hover), _hz(s.focus)])
	var c1 := _hz(_half(s.confirm, false))
	var c2 := _hz(_half(s.confirm, true))
	check(c2 > c1 * 1.15, "confirm goes up (%.0f -> %.0f Hz)" % [c1, c2])
	var b1 := _hz(_half(s.back, false))
	var b2 := _hz(_half(s.back, true))
	check(b2 < b1 / 1.15, "back comes down (%.0f -> %.0f Hz)" % [b1, b2])
	check(_hz(s.error) < 400.0, "error is low (%.0f Hz)" % _hz(s.error))
