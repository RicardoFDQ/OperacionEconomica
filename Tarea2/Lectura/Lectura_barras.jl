
# Módulo para leer las barras en los archivos excel
module ModuloLecturaBarras
    export barras_sistema

    using XLSX, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))

    using .ModuloStructs

    # Función que retorna una lista con los structs de las barras del sistema
    function barras_sistema(ruta_excel::String)
        barras = Barra[]
        tabla_barras = DataFrame(XLSX.readtable(ruta_excel, "Demand", first_row = 2))
        for fila in eachrow(tabla_barras)
            if fila[1] == "END"
                break
            end
            id_barra = parse(Int, match(r"\d+", string(fila[1])).match)
            demanda_bloques = Array(fila[2:end])
            push!(barras, Barra(id_barra, demanda_bloques))
        end
        return barras
    end
end