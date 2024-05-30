
# Módulo en donde se modela el problema de optimización de la pregunta 2c.
module ModeloP2c
    export modelo_P2c
    using JuMP, Gurobi

    include(joinpath("../Elementos_SEP/elementos_118.jl"))
    include(joinpath("../Elementos_SEP/conjuntos_118.jl"))

    using .ElementosSistema118, .ConjuntosSumatorias118

    function generadores_encendidos(w, T)
        nombre_generadores_encendidos = []
        for t in 1:T
            nombre_generadores_encendidos_en_t = []
            for generador in generadores_case118
                g = generador.id
                if w[g, t] == 1
                    nombre_generadores_encendidos_en_t[g] = generador.nombre
                end
            end
            push!(nombre_generadores_encendidos, nombre_generadores_encendidos_en_t)
        end
        return nombre_generadores_encendidos
    end

    function renovables_encendidos(wr, T)
        nombre_renovables_encendidos = []
        for t in 1:T
            nombre_renovables_encendidos_en_t = Dict()
            for renovable in renovables_case118
                g = renovable.id
                if wr[g, t] == 1
                    nombre_renovables_encendidos_en_t[t] = renovable.nombre
                end
            end
            push!(nombre_renovables_encendidos, nombre_renovables_encendidos_en_t)
        end
        return nombre_generadores_encendidos
    end

    function despacho_escenarios(diccionario_escenarios, w, wr)

        nombre_generadores_encendidos = generadores_encendidos(w, T)
        nombre_renovables_encendidos = renovables_encendidos(wr, T)

        for escenario in 1:lenght(diccionario_escenarios)

            copia_renovables_case118 = deepcopy(renovables_case118)

            # Ajuste perfil de generación renovable
            for renovable in copia_renovables
                renovable.p_pronosticada = escenario(renovable.nombre)
            end

            dict_copia_renovables_case118 = Dict(gen.id => gen for gen in copia_renovables_case118)
            modelo_P2c(dict_copia_renovables_case118, nombre_generadores_encendidos, nombre_renovables_encendidos)

        end
    end

    # Función que modela el problema de despacho económico
    function modelo_P2c(dict_copia_renovables_case118, nombre_generadores_encendidos, nombre_renovables_encendidos)
                    
        #------------------------------------------------------------------------------
        modelo = Model(Gurobi.Optimizer)

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
        @variable(modelo, pr[g = ids_generadores_case118, t = 0:T])
        
        # Ángulos de las barras en los bloques [rad]
        @variable(modelo, -π <= θ[i = 1:N, t = 1:T] <= π)

        #------------------------------------------------------------------------------
        # Función objetivo
        @objective(modelo, Min, sum(dict_generadores_case118[g].costo * pg[g, t] for g in ids_generadores_case118, t in 1:T)) 

        #------------------------------------------------------------------------------
        # Restricciones

        # Generadores convencionales apagados 
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                if !(generador.nombre in nombre_generadores_encendidos[t])
                    @constraint(modelo, pg[g, t] == 0)
                end
            end
        end

        # Generadores renovables apagados 
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                if !(renovable.nombre in nombre_renovables_encendidos[t])
                    @constraint(modelo, pr[g, t] == 0)
                end
            end
        end

        # Barra 1 slack
        for t in 1:length(barras[1].demanda)
            @constraint(modelo, θ[1, t] == 0)
        end

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
                if generador.nombre in nombre_generadores_encendidos[t]
                    @constraint(modelo, dict_generadores_case118[g].p_min <= pg[g, t])
                    @constraint(modelo, pg[g, t] <= dict_generadores_case118[g].p_max)
                end
            end
        end

        # Restricción límites de generación de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                if renovable.nombre in nombre_renovables_encendidos[t]
                    @constraint(modelo, dict_copia_renovables_case118[g].p_min <= pr[g, t])
                    @constraint(modelo, pr[g, t] <= dict_copia_renovables_case118[g].p_pronosticada[t])
                end
            end
        end

        # Restricción de rampa de generadores convencionales
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                @constraint(modelo, -generador.rampa <= pg[g, t] - pg[g, t-1])
                @constraint(modelo, pg[g, t] - pg[g, t-1] <= generador.rampa)
            end
        end

        # Restricción de rampa de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                @constraint(modelo, -renovable.rampa <= pr[g, t] - pr[g, t-1])
                @constraint(modelo, pr[g, t] - pr[g, t-1] <= renovable.rampa)
            end
        end

        optimize!(modelo)

        return value.(pg), value.(θ), objective_value(modelo)

    end

end


    