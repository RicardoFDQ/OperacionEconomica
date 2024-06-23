
include(joinpath("Modelos/P1.jl"))
include(joinpath("Modelos/P2.jl"))
include(joinpath("Display/display_resultados.jl"))


using .ModeloP1, .ModeloP2, .ImprimirResultados

modelo_P1()
resultados_modelo_N_5, resultados_modelo_N_20, resultados_modelo_N_50, resultados_modelo_N_100 = modelo_P2()

imprimir_resultados_p2(5, resultados_modelo_N_5)
imprimir_resultados_p2(20, resultados_modelo_N_20)
imprimir_resultados_p2(50, resultados_modelo_N_50)
imprimir_resultados_p2(100, resultados_modelo_N_100)