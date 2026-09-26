@tool
extends WoldMessageLog
## A log with the game talking in it: a turn marker line between rounds of
## chat, via add() with a WoldSeparator.


func turn(n: int) -> void:
	var line: WoldSeparator = load("res://addons/woldui/components/wold_separator/wold_separator.tscn").instantiate()
	line.text = "Turn %d" % n
	add(line)
