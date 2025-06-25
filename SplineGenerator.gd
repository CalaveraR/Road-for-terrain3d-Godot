class_name SplineGenerator
extends Node

var manager: SplineManager

func init(_manager: SplineManager) -> void:
    manager = _manager

func gerar_splines_auxiliares():
    if not manager.gerar_splines_auxiliares:
        return

    # A lógica continua aqui como foi explicada antes
