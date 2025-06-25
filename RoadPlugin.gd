# addons/road_tool/RoadPlugin.gd
tool
extends EditorPlugin

var spline_gui

func _enter_tree():
    # Carrega a interface do editor
    spline_gui = preload("res://addons/road_tool/gui/SplineGUI.tscn").instantiate()
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, spline_gui)
    
    var controller = spline_gui.get_node("SplineGUIController")
    var spline_manager = preload("res://addons/road_tool/spline/SplineManager.gd").new()
    add_child(spline_manager)
    controller.init(spline_manager)

func _exit_tree():
    remove_control_from_docks(spline_gui)
