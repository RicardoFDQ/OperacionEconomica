
# Módulo donde se generan las listas con las structs de los elementos del sistema de potencia
module ElementosSistema
    export  barras, generadores, lineas, baterias, lineas_P2
    
    include(joinpath("..", "Lectura", "Lectura_barras.jl"))
    include(joinpath("..", "Lectura", "Lectura_generadores.jl"))
    include(joinpath("..", "Lectura", "Lectura_lineas.jl"))
    include(joinpath("..", "Lectura", "Lectura_baterias.jl"))

    using .ModuloLecturaBarras, .ModuloLecturaGeneradores, .ModuloLecturaLineas, .ModuloLecturaBaterias

    # Paths relativos de los archivos csv
    dir = @__DIR__
    ruta_barras = joinpath(dir, "..", "Parametros", "Demand.csv")
    ruta_generadores = joinpath(dir, "..", "Parametros", "Generators.csv")
    ruta_lineas = joinpath(dir, "..", "Parametros", "Lines.csv")
    ruta_lineas_P2 = joinpath(dir, "..", "Parametros", "Lines_P2.csv")
    ruta_baterias = joinpath(dir, "..", "Parametros", "Bess.csv")

    # Listas con los structs de los elementos del sistema
    barras = barras_sistema(ruta_barras)
    generadores = generadores_sistema(ruta_generadores)
    lineas = lineas_sistema(ruta_lineas)
    lineas_P2 = lineas_sistema(ruta_lineas_P2)
    baterias = baterias_sistema(ruta_baterias)

    
end
