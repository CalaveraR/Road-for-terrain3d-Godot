# addons/road_tool/gui/SplineGUIController.gd
class_name SplineGUIController
extends Control

@onready var btn_aplicar := %BtnAplicar

var spline_manager

func init(manager):
    spline_manager = manager

func _ready():
    btn_aplicar.pressed.connect(_on_aplicar)

func _on_aplicar():
    spline_manager.regerar_splines()
