
# Módulo para leer las barras en los archivos csv
module ModuloLecturaBarras
    export barras_sistema

    using CSV, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de las barras del sistema
    function barras_sistema(ruta_archivo::String)
        barras = Barra[]
        csv_barras = CSV.read(ruta_archivo, DataFrame)
        for fila in eachrow(csv_barras)
            id_barra = fila[Symbol("IdBar")]
            demanda_bloques = [fila[Symbol("Dmd_t$i")]
                               for i in 1:size(csv_barras, 2)-1]
            push!(barras, Barra(id_barra, demanda_bloques))
        end
        return barras
    end
end


