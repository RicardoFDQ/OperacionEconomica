
# Módulo en donde se modela el problema de optimización de la pregunta 1c.
module ModeloP1c
    export modelo_P1c
    using JuMP, Gurobi

    include(joinpath("../Escritura/Escritura_resultados.jl"))
    include(joinpath("../Elementos_SEP/elementos_014.jl"))
    include(joinpath("../Elementos_SEP/conjuntos_014.jl"))

    using .ElementosSistema014, .ConjuntosSumatorias014, .EscrituraExcel

    # Función del problema de optimización de la pregunta 1c
    function modelo_P1c()
        
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
        T = length(barras_case014[1].demanda)

        # Número de barras
        N = length(barras_case014)

        #------------------------------------------------------------------------------
        # Variables de decisión

        # Potencia generada por generadores convencionales en los bloques [MW]
        @variable(modelo, pg[g = ids_generadores_case014, t = 0:T])

        # Potencia generada por generadores renovables en los bloques [MW]
        @variable(modelo, pr[g = ids_renovables_case014, t = 0:T])
        
        # Ángulos de las barras en los bloques [rad]
        @variable(modelo, -π <= θ[i = 1:N, t = 1:T] <= π)

        # Variable binaria que enciende una unidad de generación convencional
        @variable(modelo, u[g = ids_generadores_case014, t = 1:T], Bin)

        # Variable binaria que enciende una unidad de generación renovable
        @variable(modelo, ur[g = ids_renovables_case014, t = 1:T], Bin)

        # Variable binaria que apaga una unidad de generación convencional
        @variable(modelo, v[g = ids_generadores_case014, t = 1:T], Bin)

        # Variable binaria que apaga una unidad de generación renovable
        @variable(modelo, vr[g = ids_renovables_case014, t = 1:T], Bin)

        # Variable binaria que indica el estado ON/OFF de una unidad de generación convencional
        @variable(modelo, w[g = ids_generadores_case014, t = dict_generadores_case014[g].estado_inicial:T], Bin)

        # Variable binaria que indica el estado ON/OFF de una unidad de generación renovable
        @variable(modelo, wr[g = ids_renovables_case014, t = dict_renovables_case014[g].estado_inicial:T], Bin)

        #------------------------------------------------------------------------------
        # Función objetivo
        @objective(modelo, Min, sum(dict_generadores_case014[g].costo * pg[g, t] + dict_generadores_case014[g].costo_start_up * u[g, t]
                                    + dict_generadores_case014[g].costo_no_load * w[g, t] for g in ids_generadores_case014, t in 1:T)) 

        #------------------------------------------------------------------------------
        # Restricciones

        # Potencias iniciales de generadores convencionales
        for generador in generadores_case014
            g = generador.id
            @constraint(modelo, pg[g, 0] == generador.p_inicial)
        end

        # Potencias iniciales de generadores renovables
        for renovable in renovables_case014
            g = renovable.id
            @constraint(modelo, pr[g, 0] == renovable.p_inicial)
        end
        
        # Estado previo de generadores convencionales (Todos en estado OFF)
        for g in ids_generadores_case014
            for t in dict_generadores_case014[g].estado_inicial:0
                @constraint(modelo, w[g, t] == 0)
            end
        end

        # Estado previo de generadores renovables (Todos en estado OFF)
        for g in ids_renovables_case014
            for t in dict_renovables_case014[g].estado_inicial:0
                @constraint(modelo, wr[g, t] == 0)
            end
        end
        
        # Barra 1 slack
        for t in 1:T
            @constraint(modelo, θ[1, t] == 0)
        end

        # Restricción balance de potencia en barras
        for barra in barras_case014
            for t in 1:T
                n = barra.id
                @constraint(modelo,
                sum(pg[generador.id, t] for generador in generadores_en_barras_case014[n]; init = 0)/100
                + sum(pr[renovable.id, t] for renovable in renovables_en_barras_case014[n]; init = 0)/100
                ==
                (barra.demanda[t]/100)
                + sum(linea.reactancia^(-1) * (θ[n, t] - θ[linea.barra_fin, t]) for linea in lineas_out_barras_case014[n]; init = 0)
                + sum(linea.reactancia^(-1) * (θ[n, t] - θ[linea.barra_ini, t]) for linea in lineas_in_barras_case014[n]; init = 0))
            end
        end

        # Restricción flujo máximo de potencia en líneas
        for linea in lineas_case014
            for t in 1:T
                @constraint(modelo, -linea.p_max/100 <= linea.reactancia^(-1) * (θ[linea.barra_ini, t] - θ[linea.barra_fin, t]) <= linea.p_max/100)
            end
        end

        # Restricción límites de generación de generadores convencionales
        for generador in generadores_case014
            for t in 1:T
                g = generador.id
                @constraint(modelo, dict_generadores_case014[g].p_min * w[g, t] <= pg[g, t])
                @constraint(modelo, pg[g, t] <= dict_generadores_case014[g].p_max * w[g, t])
            end
        end

        # Restricción límites de generación de generadores renovables
        for renovable in renovables_case014
            for t in 1:T
                g = renovable.id
                @constraint(modelo, dict_renovables_case014[g].p_min * wr[g, t] <= pr[g, t])
                @constraint(modelo, pr[g, t] <= dict_renovables_case014[g].p_pronosticada[t] * wr[g, t])
            end
        end

        # Restricción de relación entre estados binarios de generadores convencionales
        for generador in generadores_case014
            for t in 1:T
                g = generador.id
                @constraint(modelo, u[g, t] - v[g, t] == w[g, t] - w[g, t-1])
            end
        end

        # Restricción de relación entre estados binarios de generadores renovables
        for renovable in renovables_case014
            for t in 1:T
                g = renovable.id
                @constraint(modelo, ur[g, t] - vr[g, t] == wr[g, t] - wr[g, t-1])
            end
        end

        # Restricción de rampa de generadores convencionales
        for generador in generadores_case014
            for t in 1:T
                g = generador.id
                @constraint(modelo, -generador.rampa <= pg[g, t] - pg[g, t-1])
                @constraint(modelo, pg[g, t] - pg[g, t-1] <= generador.rampa + generador.rampa_start * u[g, t])
            end
        end

        # Restricción de rampa de generadores renovables
        for renovable in renovables_case014
            for t in 1:T
                g = renovable.id
                @constraint(modelo, -renovable.rampa <= pr[g, t] - pr[g, t-1])
                @constraint(modelo, pr[g, t] - pr[g, t-1] <= renovable.rampa + renovable.rampa_start * ur[g, t])
            end
        end

        optimize!(modelo)

        # Desglose de costos del sistema
        costos_variables_totales = sum(value(dict_generadores_case014[g].costo * pg[g, t]) for g in ids_generadores_case014, t in 1:T)
        costos_start_up_totales = sum(value(dict_generadores_case014[g].costo_start_up * u[g, t]) for g in ids_generadores_case014, t in 1:T)
        costos_no_load_totales = sum(value(dict_generadores_case014[g].costo_no_load * w[g, t]) for g in ids_generadores_case014, t in 1:T)

        # Demandas totales por hora
        demanda_bloque_lista = [] 
        for t in 1:T
            demanda_bloque = 0
            for barra in barras_case014
                demanda_bloque += barra.demanda[t]
            end
            push!(demanda_bloque_lista, demanda_bloque)
        end

        # Escribir resultados en un excel en la carpeta Resultados
        direccion_excel_resultados = joinpath("Resultados/resultados_P1.xlsx")
        guardar_resultados(direccion_excel_resultados, "Pregunta 1c", pg, pr, demanda_bloque_lista, ids_generadores_case014, 
                            ids_renovables_case014, T, costos_variables_totales, costos_start_up_totales, costos_no_load_totales)


        return pg, pr, θ, u, ur, v, vr, w, wr, objective_value(modelo), ids_generadores_case014, ids_renovables_case014, T, N,
        costos_variables_totales, costos_start_up_totales, costos_no_load_totales

    end
end



