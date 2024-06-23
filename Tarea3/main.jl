
include(joinpath("Modelos/P1.jl"))
include(joinpath("Modelos/P2.jl"))


using .ModeloP1, .ModeloP2

modelo_P1()
modelo_P2()