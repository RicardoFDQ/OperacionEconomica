
# Módulo para leer los generadores renovables en los archivos excel
module ModuloLecturaRenovables    
    export  renovables_sistema

    using XLSX, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de las líneas del sistema
    function renovables_sistema(ruta_excel::String)
        renovables = Renovable[]
        tabla_renovables = DataFrame(XLSX.readtable(ruta_excel, "Renewables", first_row = 2))
        for fila in eachrow(tabla_renovables)
            if fila[1] == "END"
                break
            end
            id = string(fila[1])
            barra = parse(Int, match(r"\d+", string(fila[1])).match)
            p_generada = Array(fila[2:end])
            push!(renovables, Renovable(id, barra, p_generada))
        end
        return renovables
    end
end