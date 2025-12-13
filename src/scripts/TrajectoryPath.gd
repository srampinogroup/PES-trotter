class_name TrajectoryPath
extends Path3D

var follower: PathFollow3D:
	get:
		return %PathFollow3D

func is_empty() -> bool:
	return curve.point_count == 0
