
# Módulo para leer los generadores en los archivos csv
module ModuloLecturaGeneradores    
    export  generadores_sistema

    using CSV, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de los generadores del sistema
    function generadores_sistema(ruta_archivo::String)
        generadores = Generador[]
        csv_generadores = CSV.read(ruta_archivo, DataFrame)
        for fila in eachrow(csv_generadores)
            id_generador = fila[Symbol("IdGen")]
            P_min = fila[Symbol("PotMin")]
            P_max = fila[Symbol("PotMax")]
            Costo = fila[Symbol("GenCost")]
            Rampa = fila[Symbol("Ramp")]
            Barra = fila[Symbol("BarConexion")]
            push!(generadores, Generador(id_generador, P_min, P_max,
                                            Costo, Rampa, Barra))
        end
        return generadores
    end
end
