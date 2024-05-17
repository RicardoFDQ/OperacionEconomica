
# Módulo para leer los generadores en los archivos excel
module ModuloLecturaGeneradores    
    export  generadores_sistema

    using XLSX, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de los generadores del sistema
    function generadores_sistema(ruta_excel::String)
        generadores = Generador[]
        tabla_generadores = DataFrame(XLSX.readtable(ruta_excel, "Generators", first_row = 1))
        for fila in eachrow(tabla_generadores)
            if fila[1] == "END" || !startswith(fila[1], r"G")
                break
            end
            id_generador = parse(Int, match(r"\d+", string(fila[1])).match)
            barra = parse(Int, match(r"\d+", string(fila[2])).match)
            p_max = fila[3]
            p_min = fila[4]
            p_inicial = fila[12]
            rampa = fila[7]
            rampa_start = fila[8]
            minimum_up_time = fila[9]
            minimum_down_time = fila[10]
            estado_inicial = fila[11]
            costo_start_up = fila[13]
            costo_no_load = fila[14]
            costo = fila[15]
            push!(generadores, Generador(id_generador, p_min, p_max, p_inicial, costo, costo_start_up, costo_no_load, 
                                            minimum_up_time, minimum_down_time, estado_inicial, rampa_start, rampa, barra))
        end
        return generadores
    end
end
