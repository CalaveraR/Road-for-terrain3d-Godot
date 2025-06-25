# addons/road_tool/spline/GizmoEditor.gd
extends Node3D

signal gizmo_moved(gizmo: Node3D, new_position: Vector3)

var selected_axis := null # Pode ser "x", "y", "z", ou null para livre
var is_dragging := false
var current_gizmo := null

func _unhandled_input(event):
    if not is_dragging or current_gizmo == null:
        return

    if event is InputEventMouseMotion:
        var delta = event.relative
        var move_vec = Vector3.ZERO

        match selected_axis:
            "x":
                move_vec.x += delta.x * 0.05
            "y":
                move_vec.y -= delta.y * 0.05
            "z":
                move_vec.z += delta.x * 0.05
            null:
                move_vec = Vector3(delta.x * 0.05, -delta.y * 0.05, 0)

        current_gizmo.translate(move_vec)
        emit_signal("gizmo_moved", current_gizmo, current_gizmo.global_position)

func select_gizmo(gizmo: Node3D, axis: String = null):
    selected_axis = axis
    is_dragging = true
    current_gizmo = gizmo

func release_gizmo():
    is_dragging = false
    current_gizmo = null
