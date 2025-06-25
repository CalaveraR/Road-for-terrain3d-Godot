# addons/road_tool/spline/SplineCore.gd
extends Node

# Gera pontos laterais (ex: LI/RI/LE/RE) com base no vetor de direção e largura
static func gerar_pontos_laterais(pontos: Array, largura: float) -> Dictionary:
    var result = {
        "le": [],
        "li": [],
        "ri": [],
        "re": []
    }

    for i in pontos.size():
        var dir: Vector3
        if i == pontos.size() - 1:
            dir = (pontos[i] - pontos[i - 1]).normalized()
        else:
            dir = (pontos[i + 1] - pontos[i]).normalized()

        var binormal = Vector3.UP.cross(dir).normalized()

        var p = pontos[i]
        result["le"].append(p + binormal * largura * 0.6)
        result["li"].append(p + binormal * largura * 0.3)
        result["ri"].append(p - binormal * largura * 0.3)
        result["re"].append(p - binormal * largura * 0.6)

    return result
