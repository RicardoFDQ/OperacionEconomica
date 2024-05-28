
include(joinpath("Modelos/P1b.jl"))
include(joinpath("Modelos/P1c.jl"))
include(joinpath("Modelos/P1e.jl"))
include(joinpath("Display/display_resultados.jl"))


using .ModeloP1b, .ModeloP1c, .ModeloP1e, .ImprimirResultados

# Se almacenan los resultados de los modelos
pg_P1b, pr_P1b, θ_P1b, u_P1b, ur_P1b, v_P1b, vr_P1b, w_P1b, wr_P1b, fo_P1b, ids_generadores_P1b, ids_renovables_P1b, T_P1b, N_P1b, cvt_P1b, csut_P1b, cnlt_P1b = modelo_P1b()
# pg_P1c, pr_P1c, θ_P1c, u_P1c, ur_P1c, v_P1c, vr_P1c, w_P1c, wr_P1c, fo_P1c, ids_generadores_P1c, ids_renovables_P1c, T_P1c, N_P1c, cvt_P1c, csut_P1c, cnlt_P1c = modelo_P1c()
# pg_P1e, pr_P1e, θ_P1e, u_P1e, ur_P1e, v_P1e, vr_P1e, w_P1e, wr_P1e, fo_P1e, ids_generadores_P1e, ids_renovables_P1e, T_P1e, N_P1e, cvt_P1e, csut_P1e, cnlt_P1e = modelo_P1e()

# Se muestran los resultados de los modelos
imprimir_resultados(pg_P1b, pr_P1b, θ_P1b, u_P1b, ur_P1b, v_P1b, vr_P1b, w_P1b, wr_P1b, fo_P1b, ids_generadores_P1b, ids_renovables_P1b, T_P1b, N_P1b, cvt_P1b, csut_P1b, cnlt_P1b)
# imprimir_resultados(pg_P1c, pr_P1c, θ_P1c, u_P1c, ur_P1c, v_P1c, vr_P1c, w_P1c, wr_P1c, fo_P1c, ids_generadores_P1c, ids_renovables_P1c, T_P1c, N_P1c, cvt_P1c, csut_P1c, cnlt_P1c)
# imprimir_resultados(pg_P1e, pr_P1e, θ_P1e, u_P1e, ur_P1e, v_P1e, vr_P1e, w_P1e, wr_P1e, fo_P1e, ids_generadores_P1e, ids_renovables_P1e, T_P1e, N_P1e, cvt_P1e, csut_P1e, cnlt_P1e)



