extends Window


func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		print("New Root Size detected: ", size)
