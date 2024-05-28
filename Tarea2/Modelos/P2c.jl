
# Módulo en donde se modela el problema de optimización de la pregunta 2c.
module ModeloP2c
    export modelo_P2c
    using JuMP, Gurobi

    include(joinpath("../Elementos_SEP/elementos.jl"))
    include(joinpath("../Elementos_SEP/conjuntos.jl"))

    using .ElementosSistema, .ConjuntosSumatorias

    # Función del problema de optimización de la pregunta 1
    function modelo_P2c()
        
        #------------------------------------------------------------------------------
        modelo = Model(Gurobi.Optimizer)

        #------------------------------------------------------------------------------
        # Variables de decisión

        # Potencia generada por generadores en lOS bloques [MW]
        @variable(modelo, generadores[i].p_min <= pg[i = 1:length(generadores), t = 1:length(barras[1].demanda)] <= generadores[i].p_max)
        
        # Ángulos de las barras en los bloques [rad]
        @variable(modelo, -π <= θ[i = 1:length(barras), t = 1:length(barras[1].demanda)] <= π)


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
                sum(pg[generador.id, bloque] for generador in generadores_en_barras[barra.id]; init = 0)/100 
                ==
                (barra.demanda[bloque]/100)
                + sum(linea.reactancia^(-1) * (θ[barra.id, bloque] - θ[linea.barra_fin, bloque]) for linea in lineas_out_barras[barra.id]; init = 0)
                + sum(linea.reactancia^(-1) * (θ[barra.id, bloque] - θ[linea.barra_ini, bloque]) for linea in lineas_in_barras[barra.id]; init = 0))
            end
        end

        # Restricción flujo máximo de potencia en líneas
        for linea in lineas
            for bloque in 1:length(barras[1].demanda)
                @constraint(modelo, -linea.p_max/100 <= linea.reactancia^(-1) * (θ[linea.barra_ini, bloque] - θ[linea.barra_fin, bloque]) <= linea.p_max/100)
            end
        end

        optimize!(modelo)

        return value.(pg), value.(θ), objective_value(modelo)

    end
end