extends Node3D


func equip_railgun(object:Node3D) -> void:
	if object.has_method("equip_weapon"):
		object.equip_weapon("railgun")
