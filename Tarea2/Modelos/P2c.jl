
# Módulo en donde se modela el problema de optimización de la pregunta 2c.
module ModeloP2c
    export despacho_escenarios
    using JuMP, Gurobi

    include(joinpath("../Escritura/Escritura_resultados.jl"))
    include(joinpath("../Elementos_SEP/elementos_118.jl"))
    include(joinpath("../Elementos_SEP/conjuntos_118.jl"))
    include(joinpath("../Montecarlo/montecarlo.jl"))

    using .ElementosSistema118, .ConjuntosSumatorias118, .Montecarlo, .EscrituraExcel

    # Se cargan los 100 pronósticos renovables 
    _, _, diccionario_escenarios = obtener_datos_MC()

    # Rango de tiempo de demanda
    T = length(barras_case118[1].demanda)

    # Función con los generadores convencionales encendidos en cada periodo de tiempo
    function generadores_encendidos(w)
        nombre_generadores_encendidos = []
        for t in 1:T
            nombre_generadores_encendidos_en_t = Dict()
            for generador in generadores_case118
                g = generador.id
                if value.(w[g, t]) == 1
                    nombre_generadores_encendidos_en_t[g] = generador.nombre
                end
            end
            push!(nombre_generadores_encendidos, nombre_generadores_encendidos_en_t)
        end
        return nombre_generadores_encendidos
    end

    # Función con los generadores renovables encendidos en cada periodo de tiempo
    function renovables_encendidos(wr)
        nombre_renovables_encendidos = []
        for t in 1:T
            nombre_renovables_encendidos_en_t = Dict()
            for renovable in renovables_case118
                g = renovable.id
                if value.(wr[g, t]) == 1
                    nombre_renovables_encendidos_en_t[g] = renovable.nombre
                end
            end
            push!(nombre_renovables_encendidos, nombre_renovables_encendidos_en_t)
        end
        return nombre_renovables_encendidos
    end

    # Función que simula los 100 despachos económicos
    function despacho_escenarios(cantidad_reserva, w, wr)

        # Generadores convencionales y renovables encendidos
        nombre_generadores_encendidos = generadores_encendidos(w)
        nombre_renovables_encendidos = renovables_encendidos(wr)

        costo_total_promedio = 0
        cantidad_total_curtailment = 0

        # Se recorre cada uno de los 100 escenarios de pronóstico renoable
        for numero_escenario in eachindex(diccionario_escenarios)

            # Se genera una copia de los generadores renovables
            copia_renovables_case118 = deepcopy(renovables_case118)

            # Ajuste perfil de generación renovable
            for renovable in copia_renovables_case118
                renovable.p_pronosticada = diccionario_escenarios[numero_escenario][renovable.nombre]
            end

            # Id de los generadores renovables con los ajustes de perfil de generación
            dict_copia_renovables_case118 = Dict(gen.id => gen for gen in copia_renovables_case118)

            # Se corré el despacho para un escenario en particular
            costo_total_escenario, cantidad_curtailment_escenario = modelo_P2c(cantidad_reserva, numero_escenario, dict_copia_renovables_case118, nombre_generadores_encendidos, nombre_renovables_encendidos)
            
            # Se suman los costos totales y cantidad de curtailment del despacho del escenario
            costo_total_promedio += costo_total_escenario
            cantidad_total_curtailment += cantidad_curtailment_escenario

        end

        # Costo total promedio de los 100 despachos económicos
        costo_total_promedio = costo_total_promedio/100
        # Cantidad total de curtailment realizado
        frecuencia_cantidad_curtailment = cantidad_total_curtailment

        # Escribir resultados en un excel en la carpeta Resultados
        if cantidad_reserva == 90
            direccion_excel_resultados = joinpath("Resultados/resultados_P2c_reservas_90.xlsx")
        elseif cantidad_reserva == 99
            direccion_excel_resultados = joinpath("Resultados/resultados_P2c_reservas_99.xlsx")
        end
        guardar_resultados(direccion_excel_resultados, "Costo-Curtailment Promedio", costo_total_promedio=costo_total_promedio,
                            frecuencia_total_curtailment=frecuencia_cantidad_curtailment)
    end

    # Función que modela el problema de despacho económico de la pregunta 2c
    function modelo_P2c(cantidad_reserva, numero_escenario, dict_copia_renovables_case118, nombre_generadores_encendidos, nombre_renovables_encendidos)
                    
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
        @variable(modelo, pr[g = ids_renovables_case118, t = 0:T])
        
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
                if !(generador.nombre in values(nombre_generadores_encendidos[t]))
                    @constraint(modelo, pg[g, t] == 0)
                end
            end
        end

        # Generadores renovables apagados 
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                if !(renovable.nombre in values(nombre_renovables_encendidos[t]))
                    @constraint(modelo, pr[g, t] == 0)
                end
            end
        end

        # Barra 1 slack
        for t in 1:T
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
                if generador.nombre in values(nombre_generadores_encendidos[t])
                    @constraint(modelo, dict_generadores_case118[g].p_min <= pg[g, t])
                    @constraint(modelo, pg[g, t] <= dict_generadores_case118[g].p_max)
                end
            end
        end

        # Restricción límites de generación de generadores renovables
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                if renovable.nombre in values(nombre_renovables_encendidos[t])
                    @constraint(modelo, pr[g, t] <= dict_copia_renovables_case118[g].p_pronosticada[t])
                end
            end
        end

        # Restricción de rampa de generadores convencionales con relajaciones
        for generador in generadores_case118
            for t in 1:T
                g = generador.id
                @constraint(modelo, -1.5 * generador.rampa <= pg[g, t] - pg[g, t-1])
                if t-1 != 0
                    if !(generador.nombre in values(nombre_generadores_encendidos[t-1]))
                        @constraint(modelo, pg[g, t] - pg[g, t-1] <= 2.5 * generador.rampa)
                    else
                        @constraint(modelo, pg[g, t] - pg[g, t-1] <= generador.rampa)
                    end
                else
                    @constraint(modelo, pg[g, t] - pg[g, t-1] <= 2.5 * generador.rampa)
                end
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

        # Costos del sistema
        costos_totales = sum(value(dict_generadores_case118[g].costo * pg[g, t]) for g in ids_generadores_case118, t in 1:T)

        # Demandas totales por hora
        demanda_bloque_lista = [] 
        for t in 1:T
            demanda_bloque = 0
            for barra in barras_case118
                demanda_bloque += barra.demanda[t]
            end
            push!(demanda_bloque_lista, demanda_bloque)
        end

        # Cantidad de curtailment
        cantidad_curtailment = 0
        for renovable in renovables_case118
            for t in 1:T
                g = renovable.id
                if value.(pr[g, t]) != 0 && value.(pr[g, t]) < dict_copia_renovables_case118[g].p_pronosticada[t]
                    cantidad_curtailment += 1
                end
            end
        end

        # Escribir resultados en un excel en la carpeta Resultados
        if cantidad_reserva == 90
            direccion_excel_resultados = joinpath("Resultados/resultados_P2c_reservas_90.xlsx")
        elseif cantidad_reserva == 99
            direccion_excel_resultados = joinpath("Resultados/resultados_P2c_reservas_99.xlsx")
        end
        guardar_resultados(direccion_excel_resultados, "Escenario " * string(numero_escenario), pg, pr, demanda_bloque_lista, ids_generadores_case118, 
                                ids_renovables_case118, T, costos_totales, cantidad_curtailment=cantidad_curtailment)

        return costos_totales, cantidad_curtailment

    end

end


    