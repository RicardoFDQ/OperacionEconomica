
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
            cap = fila[Symbol("Cap")]
            rend = fila[Symbol("Rend")]
            barra = fila[Symbol("BarConexion")]
            push!(baterias, Bateria(id_bateria, cap, rend, barra))
        end
        return baterias
    end
end

