extends CharacterBody3D

func fire(length:float) -> void:
	$MeshInstance3D.mesh.length = length
	$Area3D/CollisionShape3D.shape.length = length

func increase_size() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($MeshInstance3D,"mesh.height",)
