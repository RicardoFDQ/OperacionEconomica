

module EscrituraExcel

    export guardar_resultados
    using XLSX, JuMP

    using XLSX

function guardar_resultados(direccion, nombre_hoja, pg, w, demanda_bloques_lista, ids_generadores, T)
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

        # Bloques de demanda
        for t in 1:T
            hoja[contador_filas, t+1] = "Hora " * string(t)
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
            hoja[contador_filas, 1] = "Potencia Generada por Generador " * string(g) * " [MW]"
            for t in 1:T
                hoja[contador_filas, t+1] = value.(pg[g, t])
            end
            contador_filas += 1
        end

        # Resultados de w[g, t]
        for g in ids_generadores
            hoja[contador_filas, 1] = "Estado ON/OFF Generador " * string(g)
            for t in 1:T
                hoja[contador_filas, t+1] = value.(w[g, t])
            end
            contador_filas += 1
        end
    end
end

end