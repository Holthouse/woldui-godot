extends SceneTree
## Base for the headless suites: check(), a watchdog so a hang fails, and
## finish(floor) to catch quietly skipped checks. Implement _run(), await is fine.

const WATCHDOG_SECONDS := 60.0

var _checks := 0
var _failed := 0


func _initialize() -> void:
	var dog := create_timer(WATCHDOG_SECONDS)
	dog.timeout.connect(func():
		print("FAIL: watchdog, suite still running after %d s" % WATCHDOG_SECONDS)
		print("RESULT: FAILED (watchdog)")
		quit(2))
	# one frame so the tree and theme cache settle
	await process_frame
	@warning_ignore("redundant_await")
	await _run()


func _run() -> void:
	pass


func check(ok: bool, what: String) -> bool:
	_checks += 1
	if not ok:
		_failed += 1
		print("FAIL: ", what)
	return ok


## minimum checks this suite should run
func finish(at_least: int) -> void:
	if _checks < at_least:
		check(false, "only %d checks ran, expected at least %d" % [_checks, at_least])
	if _failed == 0:
		print("RESULT: ALL PASSED (%d checks, 0 failed)" % _checks)
	else:
		print("RESULT: FAILED (%d checks, %d failed)" % [_checks, _failed])
	quit(0 if _failed == 0 else 1)


func tokens(path := "res://addons/woldui/tokens/default_dark.tres") -> WoldTokens:
	return load(path)
