
# Módulo para printear los resultados de los problemas
module ImprimirResultados
    export imprimir_resultados

    # Función que muestra los resultados ordenadamente
    function imprimir_resultados(barrido, numero_etapa, numero_escenario, inputs)
        e, costo_marginal, costos, costos_etapa_actual, θ, pgs = inputs
        println("")
        println("_" ^ 100)
        println("Resultados Barrido $barrido - Etapa $numero_etapa - Escenario $numero_escenario:")
        println("")
        println("Agua Almacenada e [MWh]: ", e)
        for (i, pg) in enumerate(pgs)
            if i == 4
                println("Generación Hidraúlica q [MW]: ", pg)
            else
                println("Generación Térmica Central pg $i [MW]: ", pg)                    
            end
        end
        println("Costos [\$]: ", costos)
        println("Costos Etapa Actual [\$]: ", costos_etapa_actual)
        println("Costos Futuros θ [\$]: ", θ)
        println("Costo Marginal [\$/MWh]: ", costo_marginal)
    end
end