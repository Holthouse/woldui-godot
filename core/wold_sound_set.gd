@tool
class_name WoldSoundSet
extends Resource
## UI sound slots. Empty = silent. Tokens hold the default set, components can
## override it.

@export var hover: AudioStream
@export var click: AudioStream
@export var confirm: AudioStream
@export var back: AudioStream
@export var error: AudioStream
@export var open: AudioStream
@export var close: AudioStream
@export var focus: AudioStream
@export_range(-40.0, 12.0, 0.5, "suffix:dB") var volume_db := -6.0
## Random pitch spread, so spam-clicking doesn't sound like a machine gun.
@export_range(0.0, 0.3, 0.01) var pitch_jitter := 0.04

const SLOTS: PackedStringArray = ["hover", "click", "confirm", "back", "error", "open", "close", "focus"]


func stream(slot: String) -> AudioStream:
	assert(SLOTS.has(slot), "WoldSoundSet: unknown slot '%s'" % slot)
	return get(slot)
