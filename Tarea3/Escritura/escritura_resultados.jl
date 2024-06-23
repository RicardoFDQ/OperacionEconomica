

module EscrituraExcel

    export guardar_resultados
    using XLSX, JuMP

# Función para guardar resultados de los modelos de optimización
function guardar_resultados(direccion, nombre_hoja, inputs)
    
    agua_almacenada_esperada, cota_inferior, cota_superior, costo_futuro, costo_marginal = inputs

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

        # Semanas
        for t in 1:100
            hoja[contador_filas, t+1] = string(t)
        end
        contador_filas += 1

        # Resultados de agua almacenada esperada
        hoja[contador_filas, 1] = "Agua Almacenada Esperada [MWh]"
        for (t, agua) in enumerate(agua_almacenada_esperada)
            hoja[contador_filas, t+1] = agua
        end
        contador_filas += 3

        # Cotas inferior y superior
        hoja[contador_filas, 1] = "Cota Inferior [\$]"
        hoja[contador_filas, 2] = cota_inferior
        contador_filas += 1
        hoja[contador_filas, 1] = "Intervalo Cota Superior [\$]"
        hoja[contador_filas, 2] = cota_superior[1]
        hoja[contador_filas, 3] = cota_superior[2]
        contador_filas += 1
        
        
        # Costos futuros y marginales
        hoja[contador_filas, 1] = "Costos Futuros de Agua Almacenda [\$]"
        hoja[contador_filas, 2] = costo_futuro
        contador_filas += 1
        hoja[contador_filas, 1] = "Costos Marginal del Agua [\$]"
        hoja[contador_filas, 2] = costo_marginal


    end
end

end