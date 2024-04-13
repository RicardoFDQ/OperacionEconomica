
# Módulo que define los conjuntos que se recorren en las sumatorias de las restricciones
module ConjuntosSumatorias
    export generadores_en_barras, lineas_out_barras, lineas_in_barras, baterias_en_barras, lineas_out_barras_P2, lineas_in_barras_P2

    include(joinpath("elementos.jl"))
    using .ElementosSistema

    # Lista que modela el conjunto de los generadores en cada barra
    generadores_en_barras = Dict(barra.id => [generador for generador in generadores
                                        if barra.id == generador.barra] for barra in barras)

    # Lista que modela conjunto de las líneas que salen en cada barra
    lineas_out_barras = Dict(barra.id => [linea for linea in lineas
                                if barra.id == linea.barra_ini] for barra in barras)

    # Lista que modela conjunto de las líneas que salen en cada barra
    lineas_in_barras = Dict(barra.id => [linea for linea in lineas
                                if barra.id == linea.barra_fin] for barra in barras)
    
    # Lista que modela conjunto de las líneas que salen en cada barra con línea 1-2 de pregunta 2
    lineas_out_barras_P2 = Dict(barra.id => [linea for linea in lineas_P2
                                if barra.id == linea.barra_ini] for barra in barras)

    # Lista que modela conjunto de las líneas que entran en cada barra con línea 1-2 de pregunta 2
    lineas_in_barras_P2 = Dict(barra.id => [linea for linea in lineas_P2
                                if barra.id == linea.barra_fin] for barra in barras)

    # Lista que modelo conjunto de baterias en cada barra                                
    baterias_en_barras = Dict(barra.id => [bateria for bateria in baterias
                                if barra.id == bateria.barra] for barra in barras)
                        
                                
end
