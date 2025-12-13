extends Node


## Test cases for bilerpf. Run anywhere.
func test_bilerpf() -> void:
	const TESTS := [
	{
		"s": Vector4(0, 0, 0, 0),
		"w": Vector2(0, 0),
		"r": 0,
	},
	{
		"s": Vector4(1, 1, 1, 1),
		"w": Vector2(0, 0),
		"r": 1,
	},
	{
		"s": Vector4(0, 0, 1, 1),
		"w": Vector2(0.7, 0),
		"r": 0.7,
	},
	{
		"s": Vector4(0, 1, 0, 1),
		"w": Vector2(0, 0.8),
		"r": 0.8,
	},
	{
		"s": Vector4(0, 1, 2, 3),
		"w": Vector2(0.6, 0.1),
		"r": 1.3,
	},
	]
	
	for test in TESTS:
		assert(is_equal_approx(Globals.bilerpf(test["s"], test["w"]), test["r"]))
		print("Tests OK")


## Test function for resample
func test_resample() -> void:
	const TESTS := [
		# trivial
		[
			[0.0],
			1,
			[0.0],
		],
		[
			[0.0],
			5,
			[0.0, 0.0, 0.0, 0.0, 0.0],
		],
		[
			[0.0, 0.0, 0.0, 0.0, 0.0],
			1,
			[0.0],
		],
		[
			[0.0, 1.0, 2.0, 3.0, 4.0],
			5,
			[0.0, 1.0, 2.0, 3.0, 4.0],
		],
		# upscaling
		[
			[0.0, 1.0],
			6,
			[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
		],
		[
			[0.0, 1.0, 2.0],
			5,
			[0.0, 0.5, 1.0, 1.5, 2.0],
		],
		[
			[0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
			7,
			[0.0, 5.0/6.0, 10.0/6.0, 15.0/6.0, 20.0/6.0, 25.0/6.0, 30.0/6.0],
		],
		[
			[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)],
			8,
			[Vector2(0, 0), Vector2(3/7.0, 0), Vector2(6/7.0, 0), Vector2(1, 9/7.0 - 1),
			 Vector2(1.0, 12/7.0 - 1), Vector2(6/7.0, 1), Vector2(3/7.0, 1), Vector2(0, 1)]
		],
		# downscaling
		[
			[0.0, 1.0, 2.0, 3.0, 4.0],
			3,
			[0.0, 2.0, 4.0],
		],
		[
			[0.0, 1.0, 2.0, 3.0, 4.0],
			4,
			[0.0, 4.0/3.0, 8.0/3.0, 4.0],
		],
	]
	
	for test in TESTS:
		var input = test[0]
		var new_size = test[1]
		var expected = test[2]
		var result = Globals.resample(input, new_size)
		
		var fail := false
		for i in len(result):
			if result[i] is float and is_equal_approx(result[i], expected[i]) \
					or result[i].is_equal_approx(expected[i]):
				continue
			
			print(result)
			print(expected)
			fail = true
			break
		
		assert(not fail, "test fail")
	
	print("__test_resample ok")


func test_find_extrema_1d() -> void:
	# format as list of [array, expected results]
	const TESTS := [
		# trivial
		[[0, 0, 0, 0],
		 [0, 0, 0, 0]],
		# monotonous
		[[7, 6, 5, 4],
		 [0, 0, 0, 0]],
		# alternating
		[[1, 2, 1, 2, 1, 2],
		 [0, 1,-1, 1,-1, 0]],
		[[0, 1, 2, 3, 2, 1, 2, 3, 4, 3, 2, 1, 0, -1, 8],
		 [0, 0, 0, 1, 0,-1, 0, 0, 1, 0, 0, 0, 0, -1, 0]],
		##FIXME flat not supported
		#[[0, 5, 5, 0],
		 #[0, 1, 0, 0]],
		#[[1, 2.5, 2.6, 2.6, 2.6, 2.7, 9],
		 #[0, 0  , 0  , 0  , 0  , 0  , 0]],
	]
	
	for test in TESTS:
		var arr := test[0] as Array
		var expected := test[1] as Array
		var result := CriticalPoints._find_extrema_1d(arr)
		assert(result == expected)
	
	print('__test__find_extrema_1d ok.')


func test_find_extrema_2d() -> void:
	# format as list of [array, expected results]
	const TESTS := [
		# trivial
		[ # test 0
		[[0, 0, 0, 0, 0],
		
		
		 [0, 0, 0, 0, 0]],
		[[0, 0, 0, 0, 0],
		 [0, 0, 0, 0, 0]],
		],
		[ # test 1
		[[0, 0],
		 [0, 0],
		 [0, 0],
		 [0, 0]],
		[[0, 0],
		 [0, 0],
		 [0, 0],
		 [0, 0]],
		],
		# simple
		[ # test 2
		[[0, 1, 2],
		 [3, 4, 5],
		 [6, 7, 8]],
		[[0, 0, 0],
		 [0, 0, 0],
		 [0, 0, 0]],
		],
		[ # test 3
		[[0, 0, 0],
		 [0, 1, 0],
		 [0, 0, 0]],
		[[0, 0, 0],
		 [0, 1, 0],
		 [0, 0, 0]],
		],
		[ # test 4
		[[0, 0, 0],
		 [0, -1, 0],
		 [0, 0, 0]],
		[[0, 0, 0],
		 [0, -1, 0],
		 [0, 0, 0]],
		],
		[ # test 5
		[[0, 0, 0],
		 [2, 1, 2],
		 [0, 0, 0]],
		[[0, 0, 0],
		 [1, 2, 1],
		 [0, 0, 0]],
		],
		# complete
		[ # test 5
		[[0, 1, 2, 3, 4],
		 [5, 4, 3, 2, 1],
		 [0, 1, 2, 3, 4],
		 [5, 4, 3, 2, 1]],
		[[ 0, 0, 0, 0, 0],
		 [1, 0, 0, 0,-1],
		 [-1, 0, 0, 0, 1],
		 [0, 0, 0, 0, 0]],
		],
		[ # test 6
		[[0, 1, 1, 1, 0],
		 [1, 0, 2, 1, 0],
		 [0,-1, 0,-1, 0],
		 [0, 1, 2, 1, 0],
		 [0, 0, 0, 0, 0]],
		[[0, 0, 0, 0, 0],
		 [1, 0, 1, 0, 0],
		 [0,-1, 2,-1, 0],
		 [0, 0, 1, 0, 0],
		 [0, 0, 0, 0, 0]],
		],
	]
	
	for test in TESTS:
		var arr := test[0] as Array
		var expected := test[1] as Array
		var result := CriticalPoints._find_extrema_2d(arr)
		assert(result == expected)
	
	print('__test__find_extrema_2d ok.')


func test_upscale_matrix() -> void:
	const TESTS := [
		[
			[[3.14]],
			[[3.14]],
		],
		[
			[[0.0, 2.0, 4.0]],
			[[0.0, 1.0, 2.0, 3.0, 4.0]],
		],
		[
			[[0.0], [2.0], [4.0]],
			[[0.0], [1.0], [2.0], [3.0], [4.0]],
		],
		[
			# order-2 saddle
			[[0.0, 2.0],
			 [2.0, 0.0],],
			[[0.0, 1.0, 2.0],
			 [1.0, 1.0, 1.0], 
			 [2.0, 1.0, 0.0],],
		],
		[
			# order-3 saddle
			[[2.0, 0.0],
			 [0.0, 2.0],
			 [2.0, 0.0],],
			[[2.0, 1.0, 0.0],
			 [1.0, 1.0, 1.0],
			 [0.0, 1.0, 2.0],
			 [1.0, 1.0, 1.0],
			 [2.0, 1.0, 0.0],],
		],
		[
			# order-4 saddle
			[[0.0, 2.0, 0.0],
			 [2.0, 0.0, 2.0],
			 [0.0, 2.0, 0.0],],
			[[0.0, 1.0, 2.0, 1.0, 0.0],
			 [1.0, 1.0, 1.0, 1.0, 1.0],
			 [2.0, 1.0, 0.0, 1.0, 2.0],
			 [1.0, 1.0, 1.0, 1.0, 1.0],
			 [0.0, 1.0, 2.0, 1.0, 0.0],],
		],
	]
	
	for test in TESTS:
		var mat := test[0] as Array
		var exp_ := test[1] as Array
		var res := CriticalPoints.upscale_matrix(mat as Array)
		assert(res == exp_)
		
	print('__test__upscale_matrix ok.')
