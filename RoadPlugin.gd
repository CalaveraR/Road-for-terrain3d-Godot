# RoadPlugin.gd (controlador geral)
extends Node3D

var spline_manager
var tile_manager
var terrain_deformer

func _ready():
    spline_manager = load("res://road_plugin/spline_manager.gd").new()
    add_child(spline_manager)

    tile_manager = load("res://road_plugin/tile_manager.gd").new()
    add_child(tile_manager)

    terrain_deformer = load("res://road_plugin/terrain_deformer.gd").new()
    add_child(terrain_deformer)

    # Conectar sinais e configurar comunicação entre módulos
