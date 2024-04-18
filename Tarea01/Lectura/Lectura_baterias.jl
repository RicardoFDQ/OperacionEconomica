
# Módulo para leer las baterías en los archivos csv
module ModuloLecturaBaterias
    export baterias_sistema

    using CSV, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de las baterías del sistema
    function baterias_sistema(ruta_archivo::String)
        baterias = Bateria[]
        csv_baterias = CSV.read(ruta_archivo, DataFrame; decimal=',')
        for fila in eachrow(csv_baterias)
            id_bateria = fila[Symbol("IdBESS")]
            cap_potencia = fila[Symbol("Cap")]
            cap_energia = 3 * fila[Symbol("Cap")]
            rend = fila[Symbol("Rend")]
            barra = fila[Symbol("BarConexion")]
            energia_inicial = 0.5 * fila[Symbol("Cap")]
            energia_final = 0.5 * fila[Symbol("Cap")]
            push!(baterias, Bateria(id_bateria, cap_potencia, cap_energia, rend, barra, energia_inicial, energia_final))
        end
        return baterias
    end
end

