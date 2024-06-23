
# Módulo para printear los resultados de los problemas
module ImprimirResultados
    export imprimir_resultados_p1, imprimir_resultados_p2 

    # Función que muestra los resultados ordenadamente
    function imprimir_resultados_p1(barrido, numero_etapa, numero_escenario, inputs)
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

    function imprimir_resultados_p2(N, inputs)
        agua_almacenada_esperada, cota_inferior, intervalo_cota_superior, costo_futuro, costo_marginal = inputs
    
        println("")
        println("_" ^ 100)
        println("Resultados N = $N:")
        println("")
        println("Agua Almacenada Esperada [MWh]: ", agua_almacenada_esperada)
        println("Cota Inferior [\$]: ", cota_inferior)
        println("Intervalo Cota Superior [\$]: ", intervalo_cota_superior)
        println("Costos Futuros Etapa 1 [\$]: ", costo_futuro)
        println("Costo Marginal del Agua Etapa 1 [\$/MWh]: ", costo_marginal)
    end


end