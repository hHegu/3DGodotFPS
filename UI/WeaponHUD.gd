extends Panel

onready var clip_ammo_text: RichTextLabel = $VBoxContainer/AmmoContainer/ClipAmmo
onready var current_ammo_text: RichTextLabel = $VBoxContainer/AmmoContainer/CurrentAmmo
onready var weapon_name_text: RichTextLabel = $VBoxContainer/WeaponName


func _process(_delta):
	var current_weapon = WeaponSingleton.current_weapon
	if not current_weapon or current_weapon == null:
		return
	clip_ammo_text.bbcode_text = Utils.center_bbtext(str(current_weapon.clip_ammo))
	current_ammo_text.bbcode_text = Utils.center_bbtext(str(current_weapon.ammo))
	weapon_name_text.bbcode_text = Utils.center_bbtext(current_weapon.weapon_name)

