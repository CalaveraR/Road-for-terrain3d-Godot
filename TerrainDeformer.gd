# addons/road_tool/terrain/TerrainDeformer.gd
extends Node

@export var terrain: Node3D
@export var grau_maximo := 40.0

func deformar_terreno(pontos_referencia: Array):
    if terrain == null or not terrain.has_method("set_height_at"):
        return

    for ponto in pontos_referencia:
        # Exemplo: afundar ou elevar a área lateral conforme diferença
        terrain.set_height_at(ponto.x, ponto.z, ponto.y)
