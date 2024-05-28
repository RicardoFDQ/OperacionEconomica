
# Módulo para printear los resultados de los problemas
module ImprimirResultados
    export imprimir_resultados
    using JuMP

    # Función que muestra los resultados ordenadamente
    function imprimir_resultados(pg, pr, θ, u, ur, v, vr, w, wr, fo, ids_generadores, ids_renovables, T, N, cvt, csut, cnlt)


        println("--------------------------------------------------------")
        println("Potencia generada por generadores convencionales en los bloques [MW]:")
        println("--------------------------------------------------------")

        for g in ids_generadores
            for t in 1:T
                println("pg[", g, ",", t, "] = ", value.(pg[g, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Potencia generada por generadores renovables en los bloques [MW]:")
        println("--------------------------------------------------------")

        for g in ids_renovables
            for t in 1:T
                println("pr[", g, ",", t, "] = ", value.(pr[g, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Ángulos de las barras en los bloques [rad]:")
        println("--------------------------------------------------------")

        for i in 1:N
            for t in 1:T
                println("θ[", i, ",", t, "] = ", value.(θ[i, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Estado de encendido de las unidades de generación convencionales:")
        println("--------------------------------------------------------")

        for g in ids_generadores
            for t in 1:T
                println("u[", g, ",", t, "] = ", value.(u[g, t]))
            end
            println()
        end
        println("--------------------------------------------------------")
        println("Estado de encendido de las unidades de generación renovables:")
        println("--------------------------------------------------------")

        for g in ids_renovables
            for t in 1:T
                println("ur[", g, ",", t, "] = ", value.(ur[g, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Estado de apagado de las unidades de generación convencionales:")
        println("--------------------------------------------------------")

        for g in ids_generadores
            for t in 1:T
                println("v[", g, ",", t, "] = ", value.(v[g, t]))
            end
            println()
        end
        println("--------------------------------------------------------")
        println("Estado de apagado de las unidades de generación renovables:")
        println("--------------------------------------------------------")

        for g in ids_renovables
            for t in 1:T
                println("vr[", g, ",", t, "] = ", value.(vr[g, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Estado ON/OFF de las unidades de generación convencionales:")
        println("--------------------------------------------------------")

        for g in ids_generadores
            for t in 1:T
                println("w[", g, ",", t, "] = ", value.(w[g, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Estado ON/OFF de las unidades de generación renovables:")
        println("--------------------------------------------------------")
        
        for g in ids_renovables
            for t in 1:T
                println("wr[", g, ",", t, "] = ", value.(wr[g, t]))
            end
            println()
        end

        println("--------------------------------------------------------")
        println("Costo total del sistema [\$]: ", fo)
        println()
        println("Costos variables totales del sistema [\$]: ", cvt)
        println()
        println("Costos start-up totales del sistema [\$]: ", csut)
        println()
        println("Costos no-load totales del sistema [\$]: ", cnlt)

    end
end