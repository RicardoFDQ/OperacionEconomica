
# Módulo para printear los resultados de los problemas
module ImprimirResultados
    export imprimir_resultados

    # Función que muestra los resultados ordenadamente
    function imprimir_resultados(modelo, pg, θ, valor_funcion_objetivo; Δd=nothing, e=nothing, pc=nothing, pd=nothing)
        println("")
        println("")
        println("-" ^ 125)  
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
        if e !== nothing
            println("e del $modelo: ", Array(e))
            println("_" ^ 125)
        end
        if pc !== nothing
            println("pc del $modelo: ", pc)
            println("_" ^ 125)
        end
        if pd !== nothing
            println("pd del $modelo: ", pd)
            println("_" ^ 125)
        end
        println("Valor de la función objetivo del $modelo: ", valor_funcion_objetivo)
        println("_" ^ 125)  
        println("")
    end
end