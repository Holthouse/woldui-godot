@tool
class_name WoldVariant
extends Resource
## A new style variant without code: an existing style redrawn with different
## tokens, plus optional per-item tweaks.
##
## e.g. name "ButtonGold", base "ButtonPrimary", token_overrides {"accent": gold}.
## Anything not redrawn falls back to the base.

## Goes in theme_type_variation. PascalCase.
@export var name := ""
## A generated style ("ButtonPrimary", "Heading") or a native type ("Button").
@export var base := ""
## e.g. {"accent": Color, "radius_md": 0}
@export var token_overrides: Dictionary = {}
## Per-item tweaks, applied after the redraw.
@export var colors: Dictionary[String, Color] = {}
@export var constants: Dictionary[String, int] = {}
@export var font_sizes: Dictionary[String, int] = {}
@export var fonts: Dictionary[String, Font] = {}
@export var styleboxes: Dictionary[String, StyleBox] = {}
@export var icons: Dictionary[String, Texture2D] = {}
