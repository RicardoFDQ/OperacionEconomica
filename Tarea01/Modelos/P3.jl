module ModeloP3
    export modelo_P3
    using JuMP, Gurobi

    include(joinpath("../Elementos_SEP/elementos.jl"))
    include(joinpath("../Elementos_SEP/conjuntos.jl"))

    using .ElementosSistema, .ConjuntosSumatorias


    function modelo_P3()
        

        #------------------------------------------------------------------------------
        modelo = Model(Gurobi.Optimizer)

        #------------------------------------------------------------------------------
        @variable(modelo, generadores[i].p_min <= pg[i = 1:3, t = 1:6] <= generadores[i].p_max)
        @variable(modelo, -2*π <= θ[i = 1:9, t = 1:6] <= 2*π)
        @variable(modelo, 0 <= e[b = 1:3, t = 1:6] <= baterias[b].cap)
        @variable(modelo, -baterias[b].cap <= d[b = 1:3, t = 1:6] <= baterias[b].cap)

        #------------------------------------------------------------------------------
        @objective(modelo, Min, sum(generadores[i].costo * pg[i,t] for i in 1:3, t in 1:6)) 

        #------------------------------------------------------------------------------

        # Restricción balance de potencia en barras
        for barra in barras
            for bloque in 1:length(barra.demanda)
                @constraint(modelo, sum(bateria.rend * d[bateria.id, bloque] for bateria in baterias_en_barras[barra.id]; init = 0)/100 
                + sum(pg[generador.id, bloque] for generador in generadores_en_barras[barra.id]; init = 0)/100 ==
                (barra.demanda[bloque]/100) + sum(linea.reactancia^(-1) * (θ[barra.id, bloque] - θ[linea.barra_fin, bloque]) for linea in lineas_out_barras[barra.id]; init = 0)
                + sum(linea.reactancia^(-1) * (θ[barra.id, bloque] - θ[linea.barra_ini, bloque]) for linea in lineas_in_barras[barra.id]; init = 0))
            end
        end

        # Restricción flujo máximo de potencia en líneas
        for linea in lineas
            for bloque in 1:length(barras[1].demanda)
                @constraint(modelo, -linea.p_max/100 <= linea.reactancia^(-1) * (θ[linea.barra_ini, bloque] - θ[linea.barra_fin, bloque]) <= linea.p_max/100)
            end
        end

        # Restricción de rampa
        for generador in generadores
            for bloque in 1:length(barras[1].demanda) - 1
                @constraint(modelo, -generador.rampa <= pg[generador.id, bloque] - pg[generador.id, bloque + 1]  <= generador.rampa)
            end
        end

        # Restricción balance potencia batería
        for bateria in baterias
            for bloque in 2:length(barras[1].demanda)
                @constraint(modelo, e[bateria.id, bloque] == e[bateria.id, bloque - 1] - d[bateria.id, bloque])
            end
        end
        optimize!(modelo)

        return value.(pg), value.(θ), value.(d), value.(e), objective_value(modelo)
    end
end