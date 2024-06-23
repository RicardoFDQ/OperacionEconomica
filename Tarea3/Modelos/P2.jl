
module ModeloP2
    export modelo_P2

    using SDDP, JuMP, Gurobi, Plots, Random
    
    include(joinpath("../Display/display_resultados.jl"))

    using .ImprimirResultados

    function subproblem_builder(subproblem::Model, node::Int)

        # State variables
        @variable(subproblem, 0 <= volumen <= 300, SDDP.State, initial_value = 100)
    
        # Control variables
        @variables(subproblem, begin
            0 <= pth_1 <= 50
            0 <= pth_2 <= 50
            0 <= pth_3 <= 50
            0 <= pg_hidro <= 150
            vertimiento >= 0
        end)
    
        # Random variables
        @variable(subproblem, inflow)    
        Ω = collect(range(5, step=5, stop=100))
        P = fill(0.05, length(Ω))
        SDDP.parameterize(subproblem, Ω, P) do ω
            return JuMP.fix(inflow, ω)
        end
    
        # Transition function and constraints
        @constraints(
            subproblem,
            begin
                volumen.out == volumen.in - pg_hidro - vertimiento + inflow
                restriccion_demanda, pg_hidro + pth_1 + pth_2 + pth_3 == 150
            end
        )
    
        # Stage-objective
        costos_variables = [50, 100, 150]
        @stageobjective(subproblem, costos_variables[1] * pth_1 + costos_variables[2] *pth_2 + costos_variables[3] * pth_3)
    
        return subproblem
    end
    
    function crear_modelo(N, graficos)
        model = SDDP.LinearPolicyGraph(
            subproblem_builder;
            stages = 100,
            sense = :Min,
            lower_bound = 0.0,
            optimizer = Gurobi.Optimizer,
        )

        resultados_modelo = entrenar_y_simular(model, N, graficos)

        return resultados_modelo
    end
    
    function entrenar_y_simular(model, N, graficos)
        SDDP.train(model; iteration_limit = N)
        simulations = SDDP.simulate(
        # The trained model to simulate.
        model,
        # The number of replications.
        100,
        # A list of names to record the values of.
        [:volumen, :pth_1, :pth_2, :pth_3, :pg_hidro, :vertimiento, :inflow],
        )
    
    
        agua_almacenada_esperada = trayectorias_agua_almacenada(graficos, simulations, N)
        title!("Trayectorias Centrales de Agua Almacenada")
        xlabel!("Semanas")
        ylabel!("Agua Almacenada [MWh]")
    
        cota_inferior, cota_superior = cotas(model, simulations)
        costo_futuro, costo_marginal = costos(model, agua_almacenada_esperada[1])
    
        return agua_almacenada_esperada, cota_inferior, cota_superior, costo_futuro, costo_marginal
    end
    
    
    # Funcion para obtener trayectorias de agua almacenada de las 100 replicaciones
    function trayectorias_agua_almacenada(graficos, simulacion, N)
    
        # Se obtienen los volumenes de agua almacenada de todas las replicaciones
        agua_almacenada_realizaciones = Dict()
        for (numero_realizacion, realizacion) in enumerate(simulacion)
            agua_almacenada_realizacion = Dict()
            agua_almacenada_realizacion[0] = 100
            for (etapa, info_etapa) in enumerate(realizacion)
                agua_almacenada_realizacion[etapa] = info_etapa[:volumen].:out
            end
            agua_almacenada_realizaciones[numero_realizacion] = agua_almacenada_realizacion
        end
    
        # Se obtienen los volumenes de agua del valor esperados de las replicaciones
        agua_almacenada_esperada = zeros(101)
        semanas = collect(0:100)
        for realizacion in range(1, 100)
            vector_agua_almacenada = []
            for semana in semanas
                push!(vector_agua_almacenada, agua_almacenada_realizaciones[realizacion][semana])
                if semana == 100
                    agua_almacenada_esperada += 0.01 * vector_agua_almacenada
                end
            end
        end
    
        # Se grafica el valor esperado de los volumenes de agua a lo largo de las semanas
        graficar(graficos, agua_almacenada_esperada, N)
    
        return agua_almacenada_esperada
    end
    
    # Función para graficar los volumenes de agua de las semanas
    function graficar(graficos, agua_almacenada_esperada, N)
        semanas = collect(0:100)
        plot!(graficos, semanas, agua_almacenada_esperada, label="N=$N", yformatter=:plain, lw=2.25, grid=true)
    end
    
    # Función para encontrar las cotas superior e inferior
    function cotas(modelo, simulacion)
        cota_inferior = SDDP.calculate_bound(modelo)
        realizaciones_aleatorias = rand(1:100, 20)
        simulaciones_elegidas = []
        for (numero_realizacion, realizacion) in enumerate(simulacion)
            if numero_realizacion in realizaciones_aleatorias
                push!(simulaciones_elegidas, realizacion)
            end
        end
        objectives = map(simulaciones_elegidas) do simulation
            return sum(stage[:stage_objective] for stage in simulation)
        end
        μ, ci = SDDP.confidence_interval(objectives)
        intervalo_confianza_cota_superior = [μ - ci, μ + ci]
        return cota_inferior, intervalo_confianza_cota_superior
    end
    
    # Función para encontrar los costos futuros y costo marginal del agua para la etapa 1
    function costos(modelo, agua_almacenada_esperada_etapa_1)
        V = SDDP.ValueFunction(modelo, node=1)
        costo_futuro, costo_marginal = SDDP.evaluate(V, Dict("volumen" => agua_almacenada_esperada_etapa_1))
        return costo_futuro, costo_marginal
    end
    
    function modelo_P2()
    
        graficos = plot()
    
        resultados_modelo_N_5 = crear_modelo(5, graficos)
        resultados_modelo_N_20 = crear_modelo(20, graficos)
        resultados_modelo_N_50 = crear_modelo(50, graficos)
        resultados_modelo_N_100 = crear_modelo(100, graficos)
        savefig(joinpath(@__DIR__, "..", "Graficos", "evolucion_agua.png"))
    
        imprimir_resultados_p2(5, resultados_modelo_N_5)
        imprimir_resultados_p2(20, resultados_modelo_N_20)
        imprimir_resultados_p2(50, resultados_modelo_N_50)
        imprimir_resultados_p2(100, resultados_modelo_N_100)
    
    end

    
end
