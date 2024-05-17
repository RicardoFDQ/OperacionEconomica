
# Módulo donde se generan las listas con las structs de los elementos del sistema case014
module ElementosSistema014
    export  barras_case014, generadores_case014, lineas_case014, renovables_case014, 
            ids_generadores_case014, dict_generadores_case014
    
    include(joinpath("..", "Lectura", "Lectura_barras.jl"))
    include(joinpath("..", "Lectura", "Lectura_generadores.jl"))
    include(joinpath("..", "Lectura", "Lectura_lineas.jl"))
    include(joinpath("..", "Lectura", "Lectura_renovable.jl"))

    using .ModuloLecturaBarras, .ModuloLecturaGeneradores, .ModuloLecturaLineas, .ModuloLecturaRenovables

    # Paths relativos de los archivos csv
    dir = @__DIR__

    ruta_case014 = joinpath(dir, "..", "Parametros", "Case014.xlsx")

    # Listas con los structs de los elementos del sistema case014
    barras_case014 = barras_sistema(ruta_case014)
    generadores_case014 = generadores_sistema(ruta_case014)
    lineas_case014 = lineas_sistema(ruta_case014)
    renovables_case014 = renovables_sistema(ruta_case014)
    
    # Elementos adicionales del sistema case014
    ids_generadores_case014 = [generador.id for generador in generadores_case014]
    dict_generadores_case014 = Dict(gen.id => gen for gen in generadores_case014)

    

end
