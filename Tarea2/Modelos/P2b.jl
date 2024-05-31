
# Módulo en donde se modela el problema de optimización de la pregunta 2b.
module ModeloP2b
    export modelo_P2b
    using JuMP, Gurobi, XLSX

    include(joinpath("../Escritura/Escritura_resultados.jl"))
    include(joinpath("../Montecarlo/montecarlo.jl"))
    include(joinpath("../Montecarlo/graficarEscenarios.jl"))
    include(joinpath("../Elementos_SEP/elementos_118.jl"))
    include(joinpath("../Elementos_SEP/conjuntos_118.jl"))

    using .ElementosSistema118, .ConjuntosSumatorias118, .Montecarlo, .EscrituraExcel, .GraficaEsc

    # Se obtienen el valor de las reservas para los interalos de confianza del 90% y 99%
    reservas_90, reservas_99, _ = obtener_datos_MC()

    # Se grafican los resultados de la generación renovables de los escenarios
    graficarMC()

    # Función del problema de optimización de la pregunta 2b
    function modelo_P2b(reservas_deseadas)

        # Se definen las reservas a utilizar
        if reservas_deseadas == 90
            reservas = reservas_90
        elseif reservas_deseadas == 99
            reservas = reservas_99
        end

        #------------------------------------------------------------------------------
        modelo = Model(Gurobi.Optimizer)

        #------------------------------------------------------------------------------
        # Configuraciones

        # Tiempo máximo de resolución a 1 hora (3600 segundos)
        set_optimizer_attribute(modelo, "TimeLimit", 3600)

        # Gap de optimalidad a 0.1%
        set_optimizer_attribute(modelo, "MIPGap", 0.001)

        #------------------------------------------------------------------------------
        # Variables auxiliares
        
        # Rango de tiempo de demanda
        T = length(barras_case118[1].demanda)

        # Número de barras
        N = length(barras_case118)

        #------------------------------------------------------------------------------
        # Variables de decisión

        # Potencia generada por generadores convencionales en los bloques [MW]
        @variable(modelo, pg[g = ids_generadores_case118, t = 0:T])

        # Potencia generada por generadores renovables en los bloques [MW]
        @variable(modelo, pr[g = ids_renovables_case118, t = 0:T])

        # Rerservas hacia arriba generadores convencionales
        @variable(modelo, r_up[g = ids_generadores_case118, t = 1:T] >= 0)

        # Rerservas hacia abajo generadores convencionales
        @variable(modelo, r_down[g = ids_generadores_case118, t = 1:T] >= 0)

        # Ángulos de las barras en los bloques [rad]
        @variable(modelo, -π <= θ[i = 1:N, t = 1:T] <= π)

        # Variable binaria que enciende una unidad de generación convencional
        @variable(modelo, u[g = ids_generadores_case118, t = 1:T], Bin)

        # Variable binaria que enciende una unidad de generación renovable
        @variable(modelo, ur[g = ids_renovables_case118, t = 1:T], Bin)

        # Variable binaria que apaga una unidad de generación convencional
        @variable(modelo, v[g = ids_generadores_case118, t = 1:T], Bin)

        # Variable binaria que apaga una unidad de generación renovable
        @variable(modelo, vr[g = ids_renovables_case118, t = 1:T], Bin)

        # Variable binaria que indica el estado ON/OFF de una unidad de generación convencional
        @variable(modelo, w[g = ids_generadores_case118, t = dict_generadores_case118[g].estado_inicial:T], Bin)

        # Variable binaria que indica el estado ON/OFF de una unidad de generación renovable
        @variable(modelo, wr[g = ids_renovables_case118, t = dict_renovables_case118[g].estado_inicial:T], Bin)

        #------------------------------------------------------------------------------
        # Función objetivo
        @objective(modelo, Min, sum(dict_generadores_case118[g].costo * pg[g, t] + dict_generadores_case118[g].costo_start_up * u[g, t]
                                    + dict_generadores_case118[g].costo_no_load * w[g, t] for g in ids_generadores_case118, t in 1:T)) 

        #------------------------------------------------------------------------------
        # Restricciones

        # Potencias iniciales de generadores convencionales
        for generador in generadores_case118
            g = generador.id
            @constraint(modelo, pg[g, 0] == generador.p_inicial)
        end

        # Potencias iniciales de generadores renovables
        for renovable in renovables_case118
            g = renovable.id
            @constraint(modelo, pr[g, 0] == renovable.p_inicial)
        end
        
        # Estado previo de generadores convencionales (Todos en estado OFF)
        for g in ids_generadores_case118
            for t in dict_generadores_case118[g].estado_inicial:0
                @constraint(modelo, w[g, t] == 0)
            end
        end

        # Estado previo de generadores renovables (Todos en estado OFF)
        for g in ids_renovables_case118
            for t in dict_renovables_case118[g].estado_inicial:0
                @constraint(modelo, wr[g, t] == 0)
            end
        end
        
        # Barra 1 slack
        for t in 1:T
            @constraint(modelo, θ[1, t] == 0)
        end

        # Restricción balance de potencia en barras
        for barra in barras_case118
            for t in 1:T
                n = barra.id
                @constraint(modelo,
                sum(pg[generador.id, t] for generador in generadores_en_barras_case118[n]; init = 0)/100
                + sum(pr[renovable.id, t] for renovable in renovables_en_barras_case118[n]; init = 0)/100
                ==
                (barra.demanda[t]/100)
                + sum(linea.reactancia^(-1) * (θ[n, t] - θ[linea.barra_fin, t]) for linea in lineas_out_barras_case118[n]; init = 0)
                + sum(linea.reactancia^(-1) * (θ[n, t] - θ[linea.barra_ini, t]) for linea in lineas_in_barras_case118[n]; init = 0))
            end
        end

        # Restricción flujo máximo de potencia en líneas
        for linea in lineas_case118
            for t in 1:T
                @constraint(modelo, -linea.p_max/100 <= linea.reactancia^(-1) * (θ[linea.barra_ini, t] - θ[linea.barra_fin, t]) <= linea.p_max/100)
            end
        end

        # Restricción límites de generación de generadores convencionales
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                @constraint(modelo, dict_generadores_case118[g].p_min * w[g, t] <= pg[g, t])
                @constraint(modelo, pg[g, t] <= dict_generadores_case118[g].p_max * w[g, t])
            end
        end

        # Restricción límites de generación de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                @constraint(modelo, dict_renovables_case118[g].p_min * wr[g, t] <= pr[g, t])
                @constraint(modelo, pr[g, t] <= dict_renovables_case118[g].p_pronosticada[t] * wr[g, t])
            end
        end

        # Restricción de relación entre estados binarios de generadores convencionales
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                @constraint(modelo, u[g, t] - v[g, t] == w[g, t] - w[g, t-1])
            end
        end

        # Restricción de relación entre estados binarios de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                @constraint(modelo, ur[g, t] - vr[g, t] == wr[g, t] - wr[g, t-1])
            end
        end

        # Restricción de rampa de generadores convencionales
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                @constraint(modelo, -generador.rampa <= pg[g, t] - pg[g, t-1])
                @constraint(modelo, pg[g, t] - pg[g, t-1] <= generador.rampa + generador.rampa_start * u[g, t])
            end
        end

        # Restricción de rampa de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                @constraint(modelo, -renovable.rampa <= pr[g, t] - pr[g, t-1])
                @constraint(modelo, pr[g, t] - pr[g, t-1] <= renovable.rampa + renovable.rampa_start * ur[g, t])
            end
        end

        # Restricción tiempo mínimo de encendido y de apagado de generadores convencionales
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                m_up = generador.minimum_up_time
                m_down = generador.minimum_down_time
                @constraint(modelo, sum(w[g, k] for k in t-m_up:t-1) >= m_up * v[g, t])
                @constraint(modelo, sum((1 - w[g, k]) for k in t-m_down:t-1) >= m_down * u[g, t])
            end
        end

        # Restricción tiempo mínimo de encendido y de apagado de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                m_up = renovable.minimum_up_time
                m_down = renovable.minimum_down_time
                @constraint(modelo, sum(wr[g, k] for k in t-m_up:t-1) >= m_up * vr[g, t])
                @constraint(modelo, sum((1 - wr[g, k]) for k in t-m_down:t-1) >= m_down * ur[g, t])
            end
        end

        # Restricción de reservas
        for t in 1:T 
            for generador in generadores_case118
                g = generador.id
                # Reservas hacia arriba
                @constraint(modelo, pg[g, t] + r_up[g, t] <= dict_generadores_case118[g].p_max * w[g, t])        
                # Reservas hacia abajo
                @constraint(modelo, pg[g, t] - r_down[g, t] >= dict_generadores_case118[g].p_min * w[g, t])
            end
            # Cumplimiento reservas totales
            @constraint(modelo, sum(r_up[generador.id, t] * w[generador.id, t] for generador in generadores_case118) >= reservas[t])
            @constraint(modelo, sum(r_down[generador.id, t] * w[generador.id,t] for generador in generadores_case118) >= reservas[t])
        end
        
        optimize!(modelo)

        # Desglose de costos del sistema
        costos_variables_totales = sum(value(dict_generadores_case118[g].costo * pg[g, t]) for g in ids_generadores_case118, t in 1:T)
        costos_start_up_totales = sum(value(dict_generadores_case118[g].costo_start_up * u[g, t]) for g in ids_generadores_case118, t in 1:T)
        costos_no_load_totales = sum(value(dict_generadores_case118[g].costo_no_load * w[g, t]) for g in ids_generadores_case118, t in 1:T)

        # Demandas totales por hora
        demanda_bloque_lista = [] 
        for t in 1:T
            demanda_bloque = 0
            for barra in barras_case118
                demanda_bloque += barra.demanda[t]
            end
            push!(demanda_bloque_lista, demanda_bloque)
        end

        # Escribir resultados en un excel en la carpeta Resultados
        direccion_excel_resultados = joinpath("Resultados/resultados_P1.xlsx")
        guardar_resultados(direccion_excel_resultados, "Reservas " * string(reservas_deseadas), pg, pr, demanda_bloque_lista, ids_generadores_case118, 
                            ids_renovables_case118, T, costos_variables_totales, costos_start_up_totales, costos_no_load_totales)

        return pg, pr, θ, u, ur, v, vr, w, wr, objective_value(modelo), ids_generadores_case118, ids_renovables_case118, T, N,
                costos_variables_totales, costos_start_up_totales, costos_no_load_totales
    end
    

end



