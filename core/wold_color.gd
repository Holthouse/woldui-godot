@tool
class_name WoldColor
## Colour maths: tone ramps from a seed, WCAG contrast. Static, no theme stuff.

## Lightest to darkest. 950 is there because dark UIs need a step below the panel.
const STEPS: PackedInt32Array = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]

## OKLab lightness at the ends of the ramp.
# 500 is the seed as picked; the rest spread out from it to these ends, so even
# a very pale or dark seed still gives an ordered ramp
const LIGHTEST := 0.975
const DARKEST := 0.16


## {step: Color} from one seed. `overrides` wins per step.
static func ramp(seed: Color, overrides: Dictionary = {}) -> Dictionary:
	var out := {}
	var h := seed.ok_hsl_h
	var s := seed.ok_hsl_s
	var seed_l := seed.ok_hsl_l
	var top := maxf(LIGHTEST, seed_l + 0.02)
	var bottom := minf(DARKEST, seed_l - 0.05)
	var mid := STEPS.find(500)
	for i in STEPS.size():
		var step := STEPS[i]
		if step == 500:
			out[step] = seed
			continue
		var l: float
		if i < mid:
			l = lerpf(seed_l, top, float(mid - i) / mid)
		else:
			l = lerpf(seed_l, bottom, float(i - mid) / (STEPS.size() - 1 - mid))
		# less chroma at the extremes, otherwise the pale steps look neon
		var edge := absf(l - 0.6) / 0.4
		out[step] = Color.from_ok_hsl(h, s * lerpf(1.0, 0.55, clampf(edge, 0.0, 1.0)), l)
	for key in overrides:
		out[int(key)] = overrides[key]
	return out


static func luminance(c: Color) -> float:
	var lin := c.srgb_to_linear()
	return 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b


## WCAG contrast of `fg` on `bg`. fg's alpha is blended in first.
static func contrast(fg: Color, bg: Color) -> float:
	var solid := bg.lerp(Color(fg, 1.0), fg.a)
	var a := luminance(solid) + 0.05
	var b := luminance(Color(bg, 1.0)) + 0.05
	return maxf(a, b) / minf(a, b)


## Light or dark text, whichever reads better on `bg`.
static func on(bg: Color, light: Color = Color(1, 1, 1), dark: Color = Color(0.06, 0.06, 0.08)) -> Color:
	return light if contrast(light, bg) >= contrast(dark, bg) else dark


static func with_alpha(c: Color, a: float) -> Color:
	return Color(c, a)
