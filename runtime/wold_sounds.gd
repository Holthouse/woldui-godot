@tool
class_name WoldSounds
## Built-in UI sounds, synthesised on first use (no audio files): soft mallet
## notes, a wooden tick, filtered whooshes. Meant to be quiet and short.
## Fill the same slot in the tokens' WoldSoundSet to use your own.

const RATE := 44100

static var _builtin: WoldSoundSet


static func builtin() -> WoldSoundSet:
	if _builtin == null:
		var s := WoldSoundSet.new()
		# hover / focus fire constantly: barely there, mid pitch
		s.hover = mallet(880.0, 0.05, 0.12)
		s.focus = mallet(660.0, 0.06, 0.12)
		s.click = mix([tick(2400.0, 0.018, 0.9), mallet(440.0, 0.04, 0.5)], [0.0, 0.0], 0.34)
		# up a fifth for yes, down for no
		s.confirm = mix([mallet(659.3, 0.18, 1.0), mallet(987.8, 0.2, 1.0)], [0.0, 0.07], 0.4)
		s.back = mix([mallet(493.9, 0.16, 0.9), mallet(329.6, 0.18, 1.0)], [0.0, 0.065], 0.32)
		# two low muted knocks
		s.error = mix([knock(196.0, 0.09), knock(185.0, 0.11)], [0.0, 0.1], 0.4)
		s.open = whoosh(500.0, 1800.0, 0.15, 0.22)
		s.close = whoosh(1800.0, 500.0, 0.13, 0.2)
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


## A soft struck note: a sine plus two quickly fading overtones (roughly a
## marimba bar's), 3 ms attack. Peak is `volume`.
static func mallet(hz: float, seconds: float, volume: float) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	# the fundamental rings longest, the overtones are just the strike
	var body := 4.5 / seconds
	for i in n:
		var t := float(i) / RATE
		var v := sin(TAU * hz * t) * exp(-t * body)
		v += 0.22 * sin(TAU * hz * 3.93 * t) * exp(-t * body * 4.0)
		v += 0.06 * sin(TAU * hz * 9.2 * t) * exp(-t * body * 9.0)
		samples[i] = v * _edges(i, n)
	return _wav(_normal(samples, volume))


## A dull knock: a low note soft-clipped warm, fast decay.
static func knock(hz: float, seconds: float) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := tanh(2.2 * sin(TAU * hz * t)) * exp(-t * 30.0)
		samples[i] = v * _edges(i, n)
	return _wav(_normal(samples, 1.0))


## A short band of noise around `hz`: a wooden tick, a key.
static func tick(hz: float, seconds: float, volume: float) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hz * seconds * 1000.0)
	var noise := PackedFloat32Array()
	noise.resize(n)
	for i in n:
		noise[i] = rng.randf_range(-1.0, 1.0)
	var band := _bandpass(noise, PackedFloat32Array([hz]), 2.5)
	for i in n:
		band[i] *= exp(-float(i) / RATE * 260.0) * _edges(i, n)
	return _wav(_normal(band, volume))


## Noise through a band that slides hz_from -> hz_to, swelling in and out,
## with a faint tone under it. Open / close.
static func whoosh(hz_from: float, hz_to: float, seconds: float, volume: float) -> AudioStreamWAV:
	var n := int(RATE * seconds)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(hz_from + hz_to)
	var noise := PackedFloat32Array()
	var centres := PackedFloat32Array()
	noise.resize(n)
	centres.resize(n)
	for i in n:
		noise[i] = rng.randf_range(-1.0, 1.0)
		# eased, so most of the travel is in the middle
		centres[i] = lerpf(hz_from, hz_to, smoothstep(0.0, 1.0, float(i) / n))
	var band := _bandpass(noise, centres, 1.6)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += TAU * centres[i] * 0.5 / RATE
		band[i] = (band[i] + 0.15 * sin(phase)) * sin(PI * k)
	return _wav(_normal(band, volume))


## Sounds laid over each other, each starting `offsets` seconds in. Peak is
## `volume`.
static func mix(parts: Array, offsets: Array, volume: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	for p in parts.size():
		var start := int(offsets[p] * RATE)
		var part := _floats(parts[p])
		if out.size() < start + part.size():
			out.resize(start + part.size())
		for i in part.size():
			out[start + i] += part[i]
	return _wav(_normal(out, volume))


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


# 3 ms in, 6 ms out, so nothing starts or stops with a pop
static func _edges(i: int, n: int) -> float:
	var attack := RATE * 0.003
	var release := RATE * 0.006
	return minf(minf(i / attack, 1.0), minf((n - 1 - i) / release, 1.0))


# Chamberlin state-variable filter, band output. One centre per sample, or
# a single one for all
static func _bandpass(input: PackedFloat32Array, centres: PackedFloat32Array, q: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(input.size())
	var low := 0.0
	var band := 0.0
	var damp := 1.0 / q
	for i in input.size():
		var hz: float = centres[mini(i, centres.size() - 1)]
		var f := 2.0 * sin(PI * minf(hz, RATE * 0.2) / RATE)
		low += f * band
		var high := input[i] - low - damp * band
		band += f * high
		out[i] = band
	return out


# scaled so the loudest sample is `peak`
static func _normal(samples: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var top := 0.0
	for v in samples:
		top = maxf(top, absf(v))
	if top > 0.0:
		for i in samples.size():
			samples[i] *= peak / top
	return samples


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
	@warning_ignore("integer_division")
	out.resize(wav.data.size() / 2)
	for i in out.size():
		out[i] = wav.data.decode_s16(i * 2) / 32767.0
	return out
