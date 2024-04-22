
# Módulo en donde se modela el problema de optimización de la pregunta 3.
module ModeloP3
    export modelo_P3
    using JuMP, Gurobi

    include(joinpath("../Elementos_SEP/elementos.jl"))
    include(joinpath("../Elementos_SEP/conjuntos.jl"))

    using .ElementosSistema, .ConjuntosSumatorias

    # Función del problema de optimización de la pregunta 3
    function modelo_P3()
        

        #------------------------------------------------------------------------------
        modelo = Model(Gurobi.Optimizer)

        #------------------------------------------------------------------------------
        # Variables de decisión

        # Potencia generada por generadores en lso blqoues [MW]
        @variable(modelo, generadores[i].p_min <= pg[i = 1:length(generadores), t = 1:length(barras[1].demanda)] <= generadores[i].p_max)

        # Ángulos de las barras en los bloques [rad]
        @variable(modelo, -π <= θ[i = 1:length(barras), t = 1:length(barras[1].demanda)] <= π)

        # Almacenamiento baterías en los bloques [MWh]
        @variable(modelo, 0 <= e[b = 1:length(baterias), t = 0:length(barras[1].demanda)] <= baterias[b].cap_energia)

        # Potencia consumida por batería en los bloques [MW]
        @variable(modelo, 0 <= pc[b = 1:length(baterias), t = 1:length(barras[1].demanda)] <= baterias[b].cap_potencia)

        # Potencia inyectada por batería en los bloques [MW]
        @variable(modelo, 0 <= pd[b = 1:length(baterias), t = 1:length(barras[1].demanda)] <= baterias[b].cap_potencia)

        #------------------------------------------------------------------------------
        # Función objetivo
        @objective(modelo, Min, sum(generadores[i].costo * pg[i,t] for i in 1:length(generadores), t in 1:length(barras[1].demanda)))

        #------------------------------------------------------------------------------
        # Barra 1 slack
        for t in 1:length(barras[1].demanda)
            @constraint(modelo, θ[1, t] == 0)
        end

        # Restricción balance de potencia en barras
        for barra in barras
            for bloque in 1:length(barra.demanda)
                @constraint(modelo, 
                sum(pd[bateria.id, bloque] for bateria in baterias_en_barras[barra.id]; init = 0)/100 
                + sum(pg[generador.id, bloque] for generador in generadores_en_barras[barra.id]; init = 0)/100 
                ==
                (barra.demanda[bloque]/100)
                + sum(linea.reactancia^(-1) * (θ[barra.id, bloque] - θ[linea.barra_fin, bloque]) for linea in lineas_out_barras[barra.id]; init = 0)
                + sum(linea.reactancia^(-1) * (θ[barra.id, bloque] - θ[linea.barra_ini, bloque]) for linea in lineas_in_barras[barra.id]; init = 0)
                + sum(pc[bateria.id, bloque] for bateria in baterias_en_barras[barra.id]; init = 0)/100)
            end
        end

        # Restricción flujo máximo de potencia en líneas
        for linea in lineas
            for bloque in 1:length(barras[1].demanda)
                @constraint(modelo, -linea.p_max/100 <= linea.reactancia^(-1) * (θ[linea.barra_ini, bloque] - θ[linea.barra_fin, bloque]) <= linea.p_max/100)
            end
        end

        # Restricción balance potencia baterías
        for bateria in baterias
            for bloque in 1:length(barras[1].demanda)
                @constraint(modelo, e[bateria.id, bloque] == e[bateria.id, bloque - 1]
                + bateria.rend^(0.5) * pc[bateria.id, bloque] - pd[bateria.id, bloque]/bateria.rend^(0.5))
            end
        end

        # Restricción estado de carga inicial y final de baterías
        for bateria in baterias
            @constraint(modelo, e[bateria.id, 0] == bateria.energia_inicial)
            @constraint(modelo, e[bateria.id, length(barras[1].demanda)] == bateria.energia_final)
        end

        optimize!(modelo)

        return value.(pg), value.(θ), value.(e), value.(pc), value.(pd), objective_value(modelo)
    end
end