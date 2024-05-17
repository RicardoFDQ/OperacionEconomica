
# Módulo para leer las líneas en los archivos excel
module ModuloLecturaLineas    
    export  lineas_sistema

    using XLSX, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de las líneas del sistema
    function lineas_sistema(ruta_excel::String)
        lineas = Linea[]
        tabla_lineas = DataFrame(XLSX.readtable(ruta_excel, "Lines", first_row = 1))
        for fila in eachrow(tabla_lineas)
            if fila[1] == "END"
                break
            end
            id_linea = string(fila[1])
            barra_ini = parse(Int, match(r"\d+", string(fila[2])).match)
            barra_fin = parse(Int, match(r"\d+", string(fila[3])).match)
            p_max = fila[7]
            reactancia = fila[5]
            push!(lineas, Linea(id_linea, barra_ini, barra_fin, p_max, reactancia))
        end
        return lineas
    end
end
