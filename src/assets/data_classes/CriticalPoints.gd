extends Node


func compute_critical_points() -> void:
	var pes := Globals.pes_data
	if pes == null:
		return
	
	var size_x := pes.size_x
	var size_y := pes.size_y
	var energies_2d := pes.get_energies_matrix()
	#var upscaled = _upscale_matrix(energies_2d)
	var criticals := _find_extrema_2d(energies_2d)
	#var up_crits := _find_extrema_2d(upscaled)
	
	Globals.pes_criticals = []
	
	var crit_num := 0
	for ix in range(size_x):
		for iy in range(size_y):
			var crit = criticals[ix][iy]
			if crit != Globals.CriticalType.NONE:
				Globals.pes_criticals.append([ix, iy, crit])
				crit_num += 1
	
	print('> found %d critical points' % crit_num)


## Upscale to (2m-1 x 2n-1) a (m x n) matrix with linear interpolation
func upscale_matrix(mat: Array) -> Array:
	var m := len(mat)
	var n := len(mat[0])
	var up: Array = []
	
	for _im in range(2 * m - 1):
		var row := []
		row.resize(2 * n - 1)
		up.append(row)
	
	# Identical pixels
	for i in range(m):
		for j in range(n):
			up[2 * i][2 * j] = mat[i][j]
	
	# First pass
	for i in range(m - 1):
		for j in range(n - 1):
			up[2 * i + 1][2 * j + 0] = (mat[i][j] + mat[i + 1][j + 0]) * 0.5
			up[2 * i + 0][2 * j + 1] = (mat[i][j] + mat[i + 0][j + 1]) * 0.5
	
	# Last row and col
	for i in range(m - 1):
		up[2 * i + 1][-1] = (mat[i][-1] + mat[i + 1][-1]) * 0.5
	
	for j in range(n - 1):
		up[-1][2 * j + 1] = (mat[-1][j] + mat[-1][j + 1]) * 0.5
	
	# Second pass
	for i in range(m - 1):
		for j in range(n - 1):
			var mid = (up[2 * i][2 * j + 1] + up[2 * i + 2][2 * j + 1]) * 0.5
			up[2 * i + 1][2 * j + 1] = mid

	return up


## Return an array of CriticalType with same size as arr
## TODO handle extremities of array
## FIXME perfectly flat portion not supported
func _find_extrema_1d(arr: Array) -> Array:
	# FIXME put array init in some util script
	var extrema := [] as Array[int]
	extrema.resize(len(arr))
	extrema.fill(0)
	
	for i in range(1, len(arr) - 1):
		if arr[i] > arr[i - 1] and arr[i] > arr[i + 1]:
			extrema[i] = Globals.CriticalType.MAXIMUM
		elif arr[i] < arr[i - 1] and arr[i] < arr[i + 1]:
			extrema[i] = Globals.CriticalType.MINIMUM
	
	return extrema


## Return an array of CriticalType with same size as arr
## TODO remove unnecessary computation of 1D for the inside
## FIXME perfectly flat portion not supported
func _find_extrema_2d(arr: Array) -> Array:
	# FIXME put array init in some util script
	# C style indexing	
	var size_x := len(arr)
	var size_y := len(arr[0])
	var criticals := []
	for _r in arr:
		var row := []
		row.resize(size_y)
		row.fill(Globals.CriticalType.NONE)
		criticals.append(row)
	
	var row_wise := []
	for ix in range(size_x):
		row_wise.append(_find_extrema_1d(arr[ix]))
	
	var col_wise := []
	for iy in range(size_y):
		var col := []
		for ix in range(size_x):
			col.append(arr[ix][iy])
		
		col_wise.append(_find_extrema_1d(col))
	
	# Convolution approach
	for ix in range(1, size_x - 1):
		for iy in range(1, size_y - 1):
			criticals[ix][iy] = _conv_critical(arr, ix, iy)
	
	# Allow borders min/max
	criticals[0] = row_wise[0]
	criticals[-1] = row_wise[-1]
	for ix in range(size_x):
		criticals[ix][0] = col_wise[0][ix]
		criticals[ix][-1] = col_wise[-1][ix]
	
	return criticals


## Compute the critical point type from the 3 x 3 kernel centered at the point
func _conv_critical(arr: Array, ix: int, iy: int) -> Globals.CriticalType:
	var epsilon := Globals.settings[&"epsilon"] as float
	var center := arr[ix][iy] as float
	# Anti-clockwise
	var neighbors := [
		arr[ix - 1][iy - 1],
		arr[ix + 0][iy - 1],
		arr[ix + 1][iy - 1],
		arr[ix + 1][iy + 0],
		arr[ix + 1][iy + 1],
		arr[ix - 0][iy + 1],
		arr[ix - 1][iy + 1],
		arr[ix - 1][iy - 0],
	]
	
	var neigh_comp := []
	for n in neighbors:
		if abs(center - n) < epsilon:
			neigh_comp.append(0)
		elif center > n:
			neigh_comp.append(+1)
		else:
			neigh_comp.append(-1)
		
	if neigh_comp.all(func(val): return val == +1):
		return Globals.CriticalType.MAXIMUM
		
	if neigh_comp.all(func(val): return val == -1):
		return Globals.CriticalType.MINIMUM

	neigh_comp = neigh_comp.filter(func(c): return c != 0)
	if neigh_comp.is_empty():
		return Globals.CriticalType.NONE

	# Saddle type
	var change_count: int = 1
	var prev = neigh_comp[0]
	for ic in range(1, len(neigh_comp)):
		var comp = neigh_comp[ic]
		if prev != comp:
			change_count += 1
		prev = comp
	
	if prev == neigh_comp[0]:
		change_count -= 1
	
	if change_count > 2:
		@warning_ignore("integer_division")
		return change_count / 2 as Globals.CriticalType
	
	return Globals.CriticalType.NONE
