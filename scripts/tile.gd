class_name Tile
extends Node

# Coordinates
var x : int
var y : int
# Type of tile
var height : int
var is_source : bool
# Water filling
var max_filling : int
var current_filling : int
# Water flowing
var max_flow : int
var current_flow : int

func _init(height, is_source, filling, flow):
	self.height = height
	self.is_source = is_source
	self.max_filling = filling
	self.max_flow = flow
	if(is_source):
		self.current_filling = filling
		self.current_flow = flow

func is_filled() -> bool:
	return max_filling <= current_filling

func is_flowing() -> bool:
	return max_flow <= current_flow
	
func send_flow(amount : int) -> int:
	if(!is_filled()):
		var fill_qty = min(max_filling - current_filling, amount)
		current_filling += fill_qty
		amount -= fill_qty
	elif(!is_flowing()):
		var flow_qty = min(max_flow - current_flow, amount)
		current_flow += flow_qty
	return amount

func flood():
	self.height = 4
	self.current_filling = self.max_filling
	self.current_flow = self.max_flow

static func NewLand():
	return Tile.new(0, false, 10, 10)

static func NewHill():
	return Tile.new(1, false, 15, 15)
	
static func NewForest():
	return Tile.new(2, false, 20, 20)
	
static func NewMountain():
	return Tile.new(3, false, 25, 25)
	
static func NewSource(flow=100):
	return Tile.new(4, true, 50, flow)
