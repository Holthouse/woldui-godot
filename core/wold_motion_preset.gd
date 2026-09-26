@tool
class_name WoldMotionPreset
extends Resource
## One animation (appear, pop, ...) as a resource you tune in the Inspector.
## Values are offsets from where the node rests. Layout puts it at the end
## state and motion starts from somewhere else, never the other way round.

enum Duration { INSTANT, FAST, BASE, SLOW, CUSTOM }
enum Easing { ENTER, MOVE, CUSTOM }

@export var duration: Duration = Duration.BASE
@export_range(0.0, 3.0, 0.01, "suffix:s") var custom_seconds := 0.24
@export var easing: Easing = Easing.ENTER
@export var custom_transition: Tween.TransitionType = Tween.TRANS_QUART
@export var custom_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("From")
@export_range(0.0, 1.0, 0.01) var from_alpha := 0.0
## px from rest
@export var from_offset := Vector2(0, 12)
@export var from_scale := Vector2.ONE

@export_group("Sequence")
@export_range(0.0, 2.0, 0.01, "suffix:s") var delay := 0.0
## Added per sibling when a list appears together.
@export_range(0.0, 0.5, 0.005, "suffix:s") var stagger := 0.04


func seconds(t: WoldTokens) -> float:
	match duration:
		Duration.INSTANT: return t.duration_instant
		Duration.FAST: return t.duration_fast
		Duration.BASE: return t.duration_base
		Duration.SLOW: return t.duration_slow
	return custom_seconds


func transition(t: WoldTokens) -> Tween.TransitionType:
	match easing:
		Easing.ENTER: return t.enter_transition
		Easing.MOVE: return t.move_transition
	return custom_transition


func ease_type(t: WoldTokens) -> Tween.EaseType:
	match easing:
		Easing.ENTER: return t.enter_ease
		Easing.MOVE: return t.move_ease
	return custom_ease
