
# Módulo para printear los resultados de los problemas
module ImprimirResultados
    export imprimir_resultados

    # Función que muestra los resultados ordenadamente
    function imprimir_resultados(modelo, pg, θ, valor_funcion_objetivo; Δd=nothing)
        println("")
        println("")
        println("-" ^ 125)  # Línea de guiones bajos como delimitador superior
        println("Resultados del $modelo:")
        println("_" ^ 125)
        println("Pg del $modelo: ", pg)
        println("_" ^ 125)
        println("θ del $modelo: ", θ)
        println("_" ^ 125)
        if Δd !== nothing
            println("Δd del $modelo: ", Δd)
            println("_" ^ 125)
        end
        println("Valor de la función objetivo del $modelo: ", valor_funcion_objetivo)
        println("_" ^ 125)  # Línea de guiones bajos como delimitador inferior
        println("")
    end
end