
include(joinpath("Modelos/P1.jl"))
include(joinpath("Modelos/P2.jl"))
include(joinpath("Modelos/P3.jl"))
include(joinpath("Display/display_resultados.jl"))

using .ModeloP1, .ModeloP2, .ModeloP3, .ImprimirResultados

# Se almacenan los resultados de los modelos
pg_modelo_1, θ_modelo_1, valor_funcion_objetivo_modelo_1 = modelo_P1()
pg_modelo_2, θ_modelo_2, Δd_modelo_2, valor_funcion_objetivo_modelo_2 = modelo_P2()
pg_modelo_3, θ_modelo_3, e_modelo_3, pc_modelo_3, pd_modelo_3, valor_funcion_objetivo_modelo_3 = modelo_P3()

# Se muestran los resultados de los modelos
imprimir_resultados("modelo 1", pg_modelo_1, θ_modelo_1, valor_funcion_objetivo_modelo_1)
imprimir_resultados("modelo 2", pg_modelo_2, θ_modelo_2,  Δd = Δd_modelo_2, valor_funcion_objetivo_modelo_2)
imprimir_resultados("modelo 3", pg_modelo_3, θ_modelo_3, e=e_modelo_3, pc=pc_modelo_3, pd=pd_modelo_3, valor_funcion_objetivo_modelo_3)