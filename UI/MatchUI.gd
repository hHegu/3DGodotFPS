extends Control


func _ready():
	HUDSingleton.connect("score_changed", self, "_score_changed")


func _score_changed(blue_score:int , red_score:int):
	$Panel/HBoxContainer/BlueScore.bbcode_text = Utils.center_bbtext(str(blue_score))
	$Panel/HBoxContainer/RedScore.bbcode_text = Utils.center_bbtext(str(red_score))
