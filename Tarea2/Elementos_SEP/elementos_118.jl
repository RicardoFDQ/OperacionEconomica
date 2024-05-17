
# Módulo donde se generan las listas con las structs de los elementos del sistema case118
module ElementosSistema118
    export  barras_case118, generadores_case118, lineas_case118, renovables_case118,
            ids_generadores_case118, dict_generadores_case118
    
    include(joinpath("..", "Lectura", "Lectura_barras.jl"))
    include(joinpath("..", "Lectura", "Lectura_generadores.jl"))
    include(joinpath("..", "Lectura", "Lectura_lineas.jl"))
    include(joinpath("..", "Lectura", "Lectura_renovable.jl"))

    using .ModuloLecturaBarras, .ModuloLecturaGeneradores, .ModuloLecturaLineas, .ModuloLecturaRenovables

    # Paths relativos de los archivos csv
    dir = @__DIR__

    ruta_case118 = joinpath(dir, "..", "Parametros", "Case118.xlsx")

    # Listas con los structs de los elementos del sistema case118
    barras_case118 = barras_sistema(ruta_case118)
    generadores_case118 = generadores_sistema(ruta_case118)
    lineas_case118 = lineas_sistema(ruta_case118)
    renovables_case118 = renovables_sistema(ruta_case118)
    
    # Elementos adicionales del sistema case118
    ids_generadores_case118 = [generador.id for generador in generadores_case118]
    dict_generadores_case118 = Dict(gen.id => gen for gen in generadores_case118)

end
