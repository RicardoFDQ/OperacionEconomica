
# Módulo para leer los generadores renovables en los archivos excel
module ModuloLecturaRenovables    
    export  renovables_sistema

    using XLSX, DataFrames
    include(joinpath("..", "Structs", "structs.jl"))
    using .ModuloStructs

    # Función que retorna una lista con los structs de las líneas del sistema
    function renovables_sistema(ruta_excel::String)
        generadores_renovables = Renovable[]
        diccionario_generacion_renovable = Dict()
        tabla_generadores = DataFrame(XLSX.readtable(ruta_excel, "Generators", first_row = 1))
        tabla_renovables = DataFrame(XLSX.readtable(ruta_excel, "Renewables", first_row = 2))

        for fila in eachrow(tabla_renovables)
            if fila[1] == "END"
                break
            end
            nombre = string(fila[1])
            p_generada = Array(fila[2:end])
            diccionario_generacion_renovable[nombre] = p_generada
        end

        for fila in eachrow(tabla_generadores)
            if fila[1] == "END"
                break
            end
            if !startswith(fila[1], r"G")
                nombre = String(fila[1])
                id_generador = parse(Int, match(r"\d+", string(fila[1])).match)
                barra = parse(Int, match(r"\d+", string(fila[2])).match)
                p_pronosticada = diccionario_generacion_renovable[nombre]
                p_min = fila[4]
                p_inicial = fila[12]
                rampa = fila[7]
                rampa_start = fila[8]
                minimum_up_time = fila[9]
                minimum_down_time = fila[10]
                estado_inicial = fila[11]
                push!(generadores_renovables, Renovable(nombre, id_generador, barra, p_pronosticada, p_min, p_inicial, rampa, rampa_start,
                                                        minimum_up_time, minimum_down_time, estado_inicial))
            end
        end
        return generadores_renovables
    end
end