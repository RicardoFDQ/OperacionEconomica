using JuMP, Gurobi

function crear_modelo(e_anterior, afluente, M=nothing, N=nothing, e_optimo_previo=nothing)

    modelo = Model(Gurobi.Optimizer)

    # Variable auxiliar
    @variable(modelo, e_aux_anterior >= 0)

    # Variables hidraúlicas
    @variable(modelo, 0 <= e <= 300)
    @variable(modelo, 0 <= q <= 150)

    # Generación térmica
    @variable(modelo, 0 <= pg_1 <= 50)
    @variable(modelo, 0 <= pg_2 <= 50)
    @variable(modelo, 0 <= pg_3 <= 50)

    # Costos futuros
    @variable(modelo, θ >= 0)

    # Función objetivo
    @objective(modelo, Min, 50 * pg_1 + 100 * pg_2 + 150 * pg_3 + θ)

    # Balance hídrico   
    @constraint(modelo, e_aux_anterior + afluente == e + q)

    # Balance de potencia
    @constraint(modelo, pg_1 + pg_2 + pg_3 + q == 150)

    # Cortes de Benders
    if !isnothing(M) && !isnothing(N)
        @constraint(modelo, N + M * (e - e_optimo_previo) <= θ)
    end

    # Igualdad variable auxiliar
    @constraint(modelo, aux, e_aux_anterior == e_anterior)

    optimize!(modelo)

    # Se obtiene el precio sombra
    precio_sombra = dual(aux)

    # Se obtiene valor función objetivo
    costo = objective_value(modelo)

    return value.(e), precio_sombra, costo, 50 * value.(pg_1) + 100 * value.(pg_2) + 150 * value.(pg_3), [value.(pg_1), value.(pg_2), value.(pg_3), value.(q)]

end

# Parámetros de entrada
e_0 = 100
afluentes = [[50], [25, 75], [25, 75]]

# -----------------------------------------------------------------------------------------------------------
# Barrido Forward 1

# Etapa 1
resultado_forward1_etapa1_escenario1 = crear_modelo(e_0, afluentes[1][1])

# Etapa 2
resultado_forward1_etapa2_escenario1 = crear_modelo(resultado_forward1_etapa1_escenario1[1], afluentes[2][1])
resultado_forward1_etapa2_escenario2 = crear_modelo(resultado_forward1_etapa1_escenario1[1], afluentes[2][2])

# Etapa 3
resultado_forward1_etapa3_escenario1 = crear_modelo(resultado_forward1_etapa2_escenario1[1], afluentes[3][1])
resultado_forward1_etapa3_escenario2 = crear_modelo(resultado_forward1_etapa2_escenario1[1], afluentes[3][2])
resultado_forward1_etapa3_escenario3 = crear_modelo(resultado_forward1_etapa2_escenario2[1], afluentes[3][1])
resultado_forward1_etapa3_escenario4 = crear_modelo(resultado_forward1_etapa2_escenario2[1], afluentes[3][2])

# -----------------------------------------------------------------------------------------------------------
# Barrido Backward 1

# Etapa 2
e_1_1_forward1 = resultado_forward1_etapa1_escenario1[1]
e_2_1_forward1 = resultado_forward1_etapa2_escenario1[1]
e_2_2_forward1 = resultado_forward1_etapa2_escenario2[1]

M_etapa3_escenario_1_2 = 0.5 * (resultado_forward1_etapa3_escenario1[2] + resultado_forward1_etapa3_escenario2[2]) 
M_etapa3_escenario_3_4 = 0.5 * (resultado_forward1_etapa3_escenario3[2] + resultado_forward1_etapa3_escenario4[2])

N_etapa3_escenario_1_2 = 0.5 * (resultado_forward1_etapa3_escenario1[3] + resultado_forward1_etapa3_escenario2[3]) 
N_etapa3_escenario_3_4 = 0.5 * (resultado_forward1_etapa3_escenario3[3] + resultado_forward1_etapa3_escenario4[3])

resultado_backward1_etapa2_escenario1 = crear_modelo(e_1_1_forward1, afluentes[2][1], M_etapa3_escenario_1_2, N_etapa3_escenario_1_2, e_2_1_forward1)
resultado_backward1_etapa2_escenario2 = crear_modelo(e_1_1_forward1, afluentes[2][2], M_etapa3_escenario_3_4, N_etapa3_escenario_3_4, e_2_2_forward1)

# Etapa 1
e_1_1_forward1 = resultado_forward1_etapa1_escenario1[1]

M_etapa2_escenario_1_2 = 0.5 * (resultado_backward1_etapa2_escenario1[2] + resultado_backward1_etapa2_escenario2[2]) 

N_etapa2_escenario_1_2 = 0.5 * (resultado_backward1_etapa2_escenario1[3] + resultado_backward1_etapa2_escenario2[3]) 

resultado_backward1_etapa1_escenario1 = crear_modelo(e_0, afluentes[1][1], M_etapa2_escenario_1_2, N_etapa2_escenario_1_2, e_1_1_forward1)


# Barrido Forward 2

# Etapa 1
e_1_1_backward1 = resultado_backward1_etapa1_escenario1[1]
resultado_forward2_etapa1_escenario1 = crear_modelo(e_0, afluentes[1][1], M_etapa2_escenario_1_2, N_etapa2_escenario_1_2, e_1_1_forward1)

# Etapa 2
resultado_forward2_etapa2_escenario1 = crear_modelo(resultado_forward2_etapa1_escenario1[1], afluentes[2][1], M_etapa3_escenario_1_2, N_etapa3_escenario_1_2, e_2_1_forward1)
resultado_forward2_etapa2_escenario2 = crear_modelo(resultado_forward2_etapa1_escenario1[1], afluentes[2][2], M_etapa3_escenario_3_4, N_etapa3_escenario_3_4, e_2_2_forward1)

# Etapa 3
resultado_forward2_etapa3_escenario1 = crear_modelo(resultado_forward2_etapa2_escenario1[1], afluentes[3][1])
resultado_forward2_etapa3_escenario2 = crear_modelo(resultado_forward2_etapa2_escenario1[1], afluentes[3][2])
resultado_forward2_etapa3_escenario3 = crear_modelo(resultado_forward2_etapa2_escenario2[1], afluentes[3][1])
resultado_forward2_etapa3_escenario4 = crear_modelo(resultado_forward2_etapa2_escenario2[1], afluentes[3][2])

