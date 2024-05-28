

module EscrituraExcel

    export guardar_resultados
    using XLSX, JuMP

    using XLSX

function guardar_resultados(direccion, nombre_hoja, pg, pr, demanda_bloques_lista, ids_generadores, ids_renovables, T)
    if !isfile(direccion)
        # Si el archivo no existe, crea uno nuevo
        XLSX.openxlsx(direccion, mode="w") do archivo_excel
            XLSX.addsheet!(archivo_excel, nombre_hoja)
        end
    end

    # Abre el archivo en modo "rw"
    XLSX.openxlsx(direccion, mode="rw") do archivo_excel

        # Verificar si la hoja ya existe
        if !(nombre_hoja in XLSX.sheetnames(archivo_excel))
            XLSX.addsheet!(archivo_excel, nombre_hoja)
        end

        hoja = archivo_excel[nombre_hoja]

        # Contador que enumera las filas escritas en la hoja excel
        contador_filas = 1
        hoja[contador_filas, 1] = "Variables/Horas"

        # Bloques de demanda
        for t in 1:T
            hoja[contador_filas, t+1] = string(t)
        end
        contador_filas += 1

        # Resultados de demanda_bloques_lista
        hoja[contador_filas, 1] = "Demanda Total Bloques [MW]"
        for (t, demanda_bloque) in enumerate(demanda_bloques_lista)
            hoja[contador_filas, t+1] = demanda_bloque
        end
        contador_filas += 1

        # Resultados de pg[g, t]
        for g in ids_generadores
            hoja[contador_filas, 1] = "Potencia Generada por Generador Convencional " * string(g) * " [MW]"
            for t in 1:T
                hoja[contador_filas, t+1] = value.(pg[g, t])
            end
            contador_filas += 1
        end

        # Resultados de pr[g, t]
        for g in ids_renovables
            hoja[contador_filas, 1] = "Potencia Generada por Generador Renovable " * string(g) * " [MW]"
            for t in 1:T
                hoja[contador_filas, t+1] = value.(pr[g, t])
            end
            contador_filas += 1
        end

    end
end

end