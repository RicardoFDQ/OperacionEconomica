
# Módulo que define los conjuntos del sistema case118 que se recorren en las sumatorias de las restricciones
module ConjuntosSumatorias118
    export generadores_en_barras_case118, lineas_out_barras_case118, lineas_in_barras_case118, renovables_en_barras_case118

    include(joinpath("elementos_118.jl"))
    using .ElementosSistema118

    # Diccionario del el conjunto de los generadores en cada barra del sistema case118
    generadores_en_barras_case118 = Dict(barra.id => [generador for generador in generadores_case118
                                        if barra.id == generador.barra] for barra in barras_case118)

    # Diccionario del conjunto de los generadores renovables en cada barra del sistema case118
    renovables_en_barras_case118 = Dict(barra.id => [renovable for renovable in renovables_case118
                                        if barra.id == renovable.barra] for barra in barras_case118)

    # Diccionario del conjunto de las líneas que salen en cada barra del sistema case118
    lineas_out_barras_case118 = Dict(barra.id => [linea for linea in lineas_case118
                                if barra.id == linea.barra_ini] for barra in barras_case118)

    # Diccionario del conjunto de las líneas que salen en cada barra del sistema case118
    lineas_in_barras_case118 = Dict(barra.id => [linea for linea in lineas_case118
                                if barra.id == linea.barra_fin] for barra in barras_case118)
    
end
