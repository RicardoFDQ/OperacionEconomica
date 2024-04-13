
# Módulo para leer las líneas en los archivos csv
module ModuloLecturaLineas    
    export  lineas_sistema

    using CSV, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de las líneas del sistema
    function lineas_sistema(ruta_archivo::String)
        lineas = Linea[]
        csv_lineas = CSV.read(ruta_archivo, DataFrame) 
        for fila in eachrow(csv_lineas)
            id_linea = fila[Symbol("IdLin")]
            BarIni = fila[Symbol("BarIni")]
            BarFin = fila[Symbol("BarFin")]
            P_max = fila[Symbol("PotMax")]
            Reactancia = fila[Symbol("Imp")]
            push!(lineas, Linea(id_linea, BarIni, BarFin,
                                P_max, Reactancia))
        end
        return lineas
    end
end
