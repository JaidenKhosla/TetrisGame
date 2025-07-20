extends Control

@onready var textLabel = $RichTextLabel
@onready var pausedText = $PausedText
@onready var GameOver: RichTextLabel = $GameOver
@export var LEVEL: int = 0:
	set(lvl):
		LEVEL = lvl
		textLabel.text = "Score: %d\nLevel: %d\nLines Cleared: %d" % [SCORE, LEVEL, LINES_CLEARED]
		
@export var SCORE: int = 0:
	set(score):
		SCORE = score
		textLabel.text = "Score: %d\nLevel: %d\nLines Cleared: %d" % [SCORE, LEVEL, LINES_CLEARED]

@export var PAUSED: bool = false:
	set(val):
		PAUSED = val
		pausedText.visible = PAUSED

@export var LINES_CLEARED: int = 0:
	set(val):
		LINES_CLEARED = val
		textLabel.text = "Score: %d\nLevel: %d\nLines Cleared: %d" % [SCORE, LEVEL, LINES_CLEARED]
