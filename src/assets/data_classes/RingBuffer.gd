class_name RingBuffer
extends RefCounted

var buffer: Array
var size: int
var head: int = 0
var tail: int = 0

var is_full: bool:
	get:
		return (head + 1) % size == tail


var is_empty: bool:
	get:
		return head == tail


var available_space: int:
	get:
		if is_full:
			return 0
		if head >= tail:
			return size - (head - tail) - 1
		else:
			return tail - head - 1


var available_data: int:
	get:
		if is_empty:
			return 0
		if head >= tail:
			return head - tail
		else:
			return size - (tail - head)


func _init(buffer_size: int):
	size = buffer_size
	buffer = Array()
	buffer.resize(size)


func push(value: Variant):
	buffer[head] = value
	head = (head + 1) % size


func pop() -> Variant:
	var value = buffer[tail]
	tail = (tail + 1) % size

	return value


func peek() -> Variant:
	if is_empty:
		return null
	return buffer[tail]


func clear():
	head = 0
	tail = 0
	buffer.resize(size)
