@tool
class_name WoldSounds
## Built-in UI sounds, synthesised on first use (no audio files).
## Placeholders until the game has real ones: fill the same slot in the
## tokens' WoldSoundSet to replace one.

const RATE := 44100

static var _builtin: WoldSoundSet


static func builtin() -> WoldSoundSet:
	if _builtin == null:
		var s := WoldSoundSet.new()
		s.hover = tone(2600.0, 2600.0, 0.018, 0.10)
		s.focus = tone(2200.0, 2200.0, 0.02, 0.12)
		s.click = tone(1500.0, 900.0, 0.035, 0.35, 0.25)
		s.confirm = chord([880.0, 1318.5], 0.07, 0.3)
		s.back = chord([1318.5, 880.0], 0.07, 0.26)
		s.error = tone(190.0, 150.0, 0.14, 0.32, 0.0, true)
		s.open = sweep(300.0, 1400.0, 0.09, 0.16)
		s.close = sweep(1400.0, 300.0, 0.08, 0.14)
		_builtin = s
	return _builtin


## Sine blip gliding hz_from -> hz_to. `hollow` clips it toward a square,
## `noise` mixes in hiss.
static func tone(hz_from: float, hz_to: float, seconds: float, volume: float, noise := 0.0, hollow := false) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hz_from * 1000.0 + seconds * 1000.0)
	for i in n:
		var k := float(i) / n
		phase += TAU * lerpf(hz_from, hz_to, k) / RATE
		var v := sin(phase)
		if hollow:
			v = clampf(v * 3.0, -1.0, 1.0) * 0.6
		v = lerpf(v, rng.randf_range(-1.0, 1.0), noise)
		samples[i] = v * _envelope(k, seconds) * volume
	return _wav(samples)


## Not really a chord, the notes play in sequence.
static func chord(notes: Array, seconds_each: float, volume: float) -> AudioStreamWAV:
	var all := PackedFloat32Array()
	for hz in notes:
		var part := tone(hz, hz, seconds_each, volume)
		all.append_array(_floats(part))
	return _wav(all)


## Filtered-noise swoosh, for open/close.
static func sweep(hz_from: float, hz_to: float, seconds: float, volume: float) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hz_from + hz_to)
	var low := 0.0
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		var cutoff := lerpf(hz_from, hz_to, k)
		var a := clampf(TAU * cutoff / RATE, 0.0, 1.0)
		low += a * (rng.randf_range(-1.0, 1.0) - low)
		phase += TAU * cutoff * 0.5 / RATE
		samples[i] = (low * 2.2 + sin(phase) * 0.25) * sin(PI * k) * volume
	return _wav(samples)


static func _envelope(k: float, seconds: float) -> float:
	var attack := minf(0.004 / seconds, 0.2)
	if k < attack:
		return k / attack
	return pow(1.0 - (k - attack) / (1.0 - attack), 2.2)


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


static func _floats(wav: AudioStreamWAV) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(wav.data.size() / 2)
	for i in out.size():
		out[i] = wav.data.decode_s16(i * 2) / 32767.0
	return out
