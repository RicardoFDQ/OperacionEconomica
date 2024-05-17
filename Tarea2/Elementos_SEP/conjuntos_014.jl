
# Módulo que define los conjuntos del sistema case014 que se recorren en las sumatorias de las restricciones
module ConjuntosSumatorias014
    export generadores_en_barras_case014, lineas_out_barras_case014, lineas_in_barras_case014, renovables_en_barras_case014

    include(joinpath("elementos_014.jl"))
    using .ElementosSistema014

    # Diccionario del conjunto de los generadores en cada barra del sistema case014
    generadores_en_barras_case014 = Dict(barra.id => [generador for generador in generadores_case014
                                        if barra.id == generador.barra] for barra in barras_case014)

    # Diccionario del conjunto de los generadores renovables en cada barra del sistema case014
    renovables_en_barras_case014 = Dict(barra.id => [renovable for renovable in renovables_case014
                                        if barra.id == renovable.barra] for barra in barras_case014)

    # Diccionario del conjunto de las líneas que salen en cada barra del sistema case014
    lineas_out_barras_case014 = Dict(barra.id => [linea for linea in lineas_case014
                                if barra.id == linea.barra_ini] for barra in barras_case014)

    # Diccionario del conjunto de las líneas que salen en cada barra del sistema case014
    lineas_in_barras_case014 = Dict(barra.id => [linea for linea in lineas_case014
                                if barra.id == linea.barra_fin] for barra in barras_case014)
    

end
