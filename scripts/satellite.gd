class_name Satellite
extends RefCounted

enum Pattern { CIRCLE, COLUMN, OVAL, BUTTERFLY }

var center_x : int
var center_y : int
var pattern_type : Pattern
var interval : int
var turns_until_snap : int

func _init(p_x: int, p_y: int, p_pattern: Pattern, p_interval: int):
	center_x = p_x
	center_y = p_y
	pattern_type = p_pattern
	interval = p_interval
	turns_until_snap = 0
