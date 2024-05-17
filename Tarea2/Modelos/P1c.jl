
# Módulo en donde se modela el problema de optimización de la pregunta 1.
module ModeloP1c
    export modelo_P1c
    using JuMP, Gurobi

    include(joinpath("../Elementos_SEP/elementos_014.jl"))
    include(joinpath("../Elementos_SEP/conjuntos_014.jl"))

    using .ElementosSistema014, .ConjuntosSumatorias014

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

        # Potencia generada por generadores en los bloques [MW]
        @variable(modelo, pg[g = ids_generadores_case014, t = 0:T])
        
        # Ángulos de las barras en los bloques [rad]
        @variable(modelo, -π <= θ[i = 1:N, t = 1:T] <= π)

        # Variable binaria que enciende una unidad de generación 
        @variable(modelo, u[g = ids_generadores_case014, t = 1:T], Bin)

        # Variable binaria que apaga una unidad de generación 
        @variable(modelo, v[g = ids_generadores_case014, t = 1:T], Bin)

        # Variable binaria que indica el estado ON/OFF de una unidad de generación
        @variable(modelo, w[g = ids_generadores_case014, t = dict_generadores_case014[g].estado_inicial:T], Bin)

        #------------------------------------------------------------------------------
        # Función objetivo
        @objective(modelo, Min, sum(dict_generadores_case014[g].costo * pg[g, t] + dict_generadores_case014[g].costo_start_up * u[g, t]
                                    + dict_generadores_case014[g].costo_no_load * w[g, t] for g in ids_generadores_case014, t in 1:T)) 

        #------------------------------------------------------------------------------
        # Restricciones

        # Potencias iniciales de generadores 
        for generador in generadores_case014
            g = generador.id
            @constraint(modelo, pg[g, 0] == generador.p_inicial)
        end
        
        # Estado previo de generadores (Todos en estado OFF)
        for g in ids_generadores_case014
            for t in dict_generadores_case014[g].estado_inicial:0
                @constraint(modelo, w[g, t] == 0)
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
                + sum(renovable.p_generada[t] for renovable in renovables_en_barras_case014[n]; init = 0)/100
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

        # Restricción límites de generación
        for generador in generadores_case014
            for t in 1:T
                g = generador.id
                @constraint(modelo, dict_generadores_case014[g].p_min * w[g, t] <= pg[g, t])
                @constraint(modelo, pg[g, t] <= dict_generadores_case014[g].p_max * w[g, t])
            end
        end

        # Restricción de relación entre estados binarios
        for generador in generadores_case014
            for t in 1:T
                g = generador.id
                @constraint(modelo, u[g, t] - v[g, t] == w[g, t] - w[g, t-1])
            end
        end

        # Restricción de rampa
        for generador in generadores_case014
            for t in 1:T
                g = generador.id
                @constraint(modelo, -generador.rampa <= pg[g, t] - pg[g, t-1])
                @constraint(modelo, pg[g, t] - pg[g, t-1] <= generador.rampa + generador.rampa_start * u[g, t])
            end
        end

        optimize!(modelo)

        costos_variables_totales = sum(value(dict_generadores_case014[g].costo * pg[g, t]) for g in ids_generadores_case014, t in 1:T)
        costos_start_up_totales = sum(value(dict_generadores_case014[g].costo_start_up * u[g, t]) for g in ids_generadores_case014, t in 1:T)
        costos_no_load_totales = sum(value(dict_generadores_case014[g].costo_no_load * w[g, t]) for g in ids_generadores_case014, t in 1:T)

        return pg, θ, u, v, w, objective_value(modelo), ids_generadores_case014, T, N,
               costos_variables_totales, costos_start_up_totales, costos_no_load_totales

    end
end



