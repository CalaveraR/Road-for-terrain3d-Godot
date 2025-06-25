# addons/road_tool/save/RoadMapSaver.gd
extends Node

func salvar_mapa(caminho: String, dados: Dictionary):
    var file = FileAccess.open(caminho, FileAccess.WRITE)
    file.store_string(to_json(dados))
    file.close()

func carregar_mapa(caminho: String) -> Dictionary:
    if not FileAccess.file_exists(caminho):
        return {}
    var file = FileAccess.open(caminho, FileAccess.READ)
    var content = file.get_as_text()
    return JSON.parse_string(content)
