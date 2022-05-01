extends CSGSphere

export(Enums.HITMARK_TYPE) var hitmark_type

func take_damage(damage: float):
	print(damage)
	WeaponSingleton.show_hitmarks(damage, hitmark_type)
