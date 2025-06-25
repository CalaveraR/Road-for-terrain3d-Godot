# addons/road_tool/mesh/RoadTileManager.gd
extends Node3D

var lista_meshes_disponiveis := []
var caminho_malhas := "res://meshes/road_tiles"

func carregar_tiles():
    var dir = DirAccess.open(caminho_malhas)
    if dir:
        for file in dir.get_files():
            if file.ends_with(".tscn"):
                var scene = load(caminho_malhas + "/" + file)
                lista_meshes_disponiveis.append(scene)

func instanciar_tile_em(pos: Vector3, rot: Basis, tipo: int = 0):
    var tile = lista_meshes_disponiveis[tipo].instantiate()
    tile.global_position = pos
    tile.global_transform.basis = rot
    add_child(tile)
