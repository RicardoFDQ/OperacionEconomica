module Montecarlo

    include(joinpath("structures.jl"))

    using Random, Statistics, Plots, Printf, .Structures, XLSX

    export obtener_datos_MC, montecarlo_RE_excel, montecarlo_datos, datos_MC_graficar

    # Función para interpolar las desviaciones estándar para cada hora
    function interpolar_desviacion(k_1hr, k_24hr, num_horas)
        return [(k_1hr + (k_24hr - k_1hr) * (hora - 1) / (num_horas - 1)) for hora in 1:num_horas]
    end

    # Desviaciones estándar porcentuales
    k_eolico_1hr = 14.70 / 100
    k_eolico_24hr = 30.92 / 100
    k_solar_1hr = 10.20 / 100
    k_solar_24hr = 14.02 / 100

    confianza_90 = 1.645
    confianza_99 = 2.575

    # Desviaciones estándar para cada hora
    desviacion_eolico = interpolar_desviacion(k_eolico_1hr, k_eolico_24hr, 24)
    desviacion_solar = interpolar_desviacion(k_solar_1hr, k_solar_24hr, 24)

    #########################################################################################################################
    #Este archivo es solamente para sacar los datos de simulaciones de montecarlo y guardarlos

    function montecarlo_RE(lista_gen::Vector{Gen},lista_RE::Vector{REnergy}) #Genera los datos montecarlo para usarlos en el código
        # Número de escenarios y horas
        num_generadores = length(lista_RE)
        num_escenarios = 100
        num_horas = length(lista_RE[1].Pd)

        lista_escenarios_generacion = []

        for escenario in 1:num_escenarios
            dictG = Dict()
            for re in 1:num_generadores
                gen = get_list_id(lista_RE[re].id, lista_gen)
                lista_horas = []
                var = randn()
                for hora in 1:num_horas
                    if gen.Type == "Wind"
                        var *= desviacion_eolico[hora]
                    elseif gen.Type == "Solar"
                        var *= desviacion_solar[hora]
                    else
                        println("Fallo en tipo de generación")
                    end
                    pd = max(0, lista_RE[re].Pd[hora] * (1 + var))
                    push!(lista_horas, pd)
                end
                dictG[lista_RE[re].id] = lista_horas
            end
            push!(lista_escenarios_generacion, dictG)
        end

        res_90 = []
        res_99 = []
        for hora in 1:num_horas
            error90 = 0
            error99 = 0
            for re in range(1,num_generadores)
                gen = get_list_id(lista_RE[re].id, lista_gen)
                if gen.Type == "Wind"
                    error90 += desviacion_eolico[hora] * lista_RE[re].Pd[hora] * confianza_90
                    error99 += desviacion_eolico[hora] * lista_RE[re].Pd[hora] * confianza_99
                elseif gen.Type == "Solar"
                    error90 += desviacion_solar[hora] * lista_RE[re].Pd[hora] * confianza_90
                    error99 += desviacion_solar[hora] * lista_RE[re].Pd[hora] * confianza_99
                else
                    println("Fallo en tipo de generación")
                end
            end
            push!(res_90, error90)
            push!(res_99, error99)
        end

        return res_90, res_99, lista_escenarios_generacion
    end

    function montecarlo_RE_excel(lista_gen::Vector{Gen},lista_RE::Vector{REnergy}) #Genera dos Excel para ver los datos a ojo
        # Número de escenarios y horas
        num_generadores = length(lista_RE)
        num_escenarios = 100
        num_horas = length(lista_RE[1].Pd)
        string_escenarios = [@sprintf("esc%03d", i) for i in 1:num_escenarios]

        # Inicializar matrices para guardar los resultados
        generacion_toda_rv = zeros(num_generadores, num_horas, num_escenarios)
        generacion_eolica = zeros(num_generadores, num_horas, num_escenarios)
        generacion_solar = zeros(num_generadores, num_horas, num_escenarios)
        generacion_total_eolica = zeros(num_horas, num_escenarios)
        generacion_total_solar = zeros(num_horas, num_escenarios)
        generacion_total_renovable = zeros(num_horas, num_escenarios)

        #Crear XLSX
        ruta_archivo = joinpath(@__DIR__, "..", "Resultados", "Montecarlo.xlsx")
        XLSX.openxlsx(ruta_archivo, mode="w") do xf

            # Simular los escenarios
            for escenario in 1:num_escenarios
                sh = XLSX.addsheet!(xf, string_escenarios[escenario])
                filaT = 1
                for hora in 1:num_horas
                    for re in 1:num_generadores
                        gen = get_list_id(lista_RE[re].id, lista_gen)
                        if gen.Type == "Wind"
                            error = randn() * desviacion_eolico[hora] * lista_RE[re].Pd[hora]
                            generacion_eolica[re, hora, escenario] = max(0, lista_RE[re].Pd[hora] + error)
                        elseif gen.Type == "Solar"
                            error = randn() * desviacion_solar[hora] * lista_RE[re].Pd[hora]
                            generacion_solar[re, hora, escenario] = max(0, lista_RE[re].Pd[hora] + error)
                        else
                            error = 0
                            println("Fallo en tipo de generación")
                        end
                        sh[re + filaT, 1] = lista_RE[re].id
                        sh[re + filaT, hora+1] = max(0, lista_RE[re].Pd[hora] + error)
                    end
                    generacion_total_eolica[hora, escenario] = sum(generacion_eolica[re, hora, escenario] for re in 1:num_generadores)
                    sh[filaT + 1 + num_generadores, 1] = "Total Eolico"
                    sh[filaT + 1 + num_generadores, hora+1] = generacion_total_eolica[hora, escenario]
                    generacion_total_solar[hora, escenario] = sum(generacion_solar[re, hora, escenario] for re in 1:num_generadores)
                    sh[filaT + 2 + num_generadores, 1] = "Total Solar"
                    sh[filaT + 2 + num_generadores, hora+1] = generacion_total_solar[hora, escenario]
                    generacion_total_renovable[hora, escenario] = generacion_total_eolica[hora, escenario] + generacion_total_solar[hora, escenario]
                    sh[filaT + 3 + num_generadores, 1] = "Total Renovable"
                    sh[filaT + 3 + num_generadores, hora+1] = generacion_total_renovable[hora, escenario]
                end
                filaT += 4 + num_generadores
                sh[filaT, 1] = "End"
                filaT += 2
            end
        end

        generacion_eolicaI = zeros(4,num_horas)
        generacion_solarI  = zeros(4,num_horas)
        generacion_totalI  = zeros(4,num_horas)

        ruta_archivo = joinpath(@__DIR__, "..", "Resultados", "Intervalo.xlsx")
        XLSX.openxlsx(ruta_archivo, mode="w") do xf

            #Intervalos 
            sh2 = xf[1]
            XLSX.rename!(sh2, "Intervarlos")

            filaT = 1

            sh2[filaT + 0, 1] = "low_eolico_90"
            sh2[filaT + 1, 1] = "high_eolico_90"
            sh2[filaT + 2, 1] = "low_solar_90"
            sh2[filaT + 3, 1] = "high_solar_90"
            sh2[filaT + 4, 1] = "low_total_90"
            sh2[filaT + 5, 1] = "low_total_90"

            sh2[filaT + 7, 1] = "low_eolico_99"
            sh2[filaT + 8, 1] = "high_eolico_99"
            sh2[filaT + 9, 1] = "low_solar_99"
            sh2[filaT + 10, 1] = "high_solar_99"
            sh2[filaT + 11, 1] = "low_total_99"
            sh2[filaT + 12, 1] = "low_total_99"
            for hora in 1:num_horas
                for re in range(1,num_generadores)
                    gen = get_list_id(lista_RE[re].id, lista_gen)
                    if gen.Type == "Wind"
                        error = desviacion_eolico[hora] * lista_RE[re].Pd[hora] * confianza_90
                        
                        generacion_eolicaI[1,hora] += max(0, lista_RE[re].Pd[hora] - error)
                        generacion_eolicaI[2,hora] += max(0, lista_RE[re].Pd[hora] + error)
                        error = desviacion_eolico[hora] * lista_RE[re].Pd[hora] * confianza_99
                        generacion_eolicaI[3,hora] += max(0, lista_RE[re].Pd[hora] - error)
                        generacion_eolicaI[4,hora] += max(0, lista_RE[re].Pd[hora] + error)
                    elseif gen.Type == "Solar"
                        error = desviacion_solar[hora] * lista_RE[re].Pd[hora] * confianza_90
                        generacion_solarI[1,hora] += max(0, lista_RE[re].Pd[hora] - error)
                        generacion_solarI[2,hora] += max(0, lista_RE[re].Pd[hora] + error)
                        error = desviacion_solar[hora] * lista_RE[re].Pd[hora] * confianza_99
                        generacion_solarI[3,hora] += max(0, lista_RE[re].Pd[hora] - error)
                        generacion_solarI[4,hora] += max(0, lista_RE[re].Pd[hora] + error)
                    else
                        error = 0
                        println("Fallo en tipo de generación")
                    end
                end
                generacion_totalI[1, hora] = generacion_eolicaI[1,hora] + generacion_solarI[1,hora]
                generacion_totalI[2, hora] = generacion_eolicaI[2,hora] + generacion_solarI[2,hora]
                generacion_totalI[3, hora] = generacion_eolicaI[3,hora] + generacion_solarI[3,hora]
                generacion_totalI[4, hora] = generacion_eolicaI[4,hora] + generacion_solarI[4,hora]

                sh2[filaT + 0, hora + 1] = generacion_eolicaI[1,hora]
                sh2[filaT + 1, hora + 1] = generacion_eolicaI[2,hora]
                sh2[filaT + 2, hora + 1] = generacion_solarI[1,hora]
                sh2[filaT + 3, hora + 1] = generacion_solarI[2,hora]
                sh2[filaT + 4, hora + 1] = generacion_totalI[1,hora]
                sh2[filaT + 5, hora + 1] = generacion_totalI[2,hora]

                sh2[filaT + 7, hora + 1] = generacion_eolicaI[3,hora]
                sh2[filaT + 8, hora + 1] = generacion_eolicaI[4,hora]
                sh2[filaT + 9, hora + 1] = generacion_solarI[3,hora]
                sh2[filaT + 10, hora + 1] = generacion_solarI[4,hora]
                sh2[filaT + 11, hora + 1] = generacion_totalI[3,hora]
                sh2[filaT + 12, hora + 1] = generacion_totalI[4,hora]
            end
        end
        return
    end

    function montecarlo_datos(lista_gen::Vector{Gen},lista_RE::Vector{REnergy}) #Genera dos Excel para ver los datos a ojo
        # Número de escenarios y horas
        num_generadores = length(lista_RE)
        num_escenarios = 100
        num_horas = length(lista_RE[1].Pd)

        # Inicializar matrices para guardar los resultados
        generacion_eolica = zeros(num_generadores, num_horas, num_escenarios)
        generacion_solar = zeros(num_generadores, num_horas, num_escenarios)
        generacion_total_eolica = zeros(num_horas, num_escenarios)
        generacion_total_solar = zeros(num_horas, num_escenarios)
        generacion_total_renovable = zeros(num_horas, num_escenarios)

        

        # Simular los escenarios
        for escenario in 1:num_escenarios
            for hora in 1:num_horas
                for re in 1:num_generadores
                    gen = get_list_id(lista_RE[re].id, lista_gen)
                    if gen.Type == "Wind"
                        error = randn() * desviacion_eolico[hora] * lista_RE[re].Pd[hora]
                        generacion_eolica[re, hora, escenario] = max(0, lista_RE[re].Pd[hora] + error)
                    elseif gen.Type == "Solar"
                        error = randn() * desviacion_solar[hora] * lista_RE[re].Pd[hora]
                        generacion_solar[re, hora, escenario] = max(0, lista_RE[re].Pd[hora] + error)
                    else
                        error = 0
                        println("Fallo en tipo de generación")
                    end
                end
                generacion_total_eolica[hora, escenario] = sum(generacion_eolica[re, hora, escenario] for re in 1:num_generadores)
                generacion_total_solar[hora, escenario] = sum(generacion_solar[re, hora, escenario] for re in 1:num_generadores)

                generacion_total_renovable[hora, escenario] = generacion_total_eolica[hora, escenario] + generacion_total_solar[hora, escenario]
            end
        end

        generacion_eolicaI = zeros(4,num_horas)
        generacion_solarI  = zeros(4,num_horas)
        generacion_totalI  = zeros(4,num_horas)

        for hora in 1:num_horas
            for re in range(1,num_generadores)
                gen = get_list_id(lista_RE[re].id, lista_gen)
                if gen.Type == "Wind"
                    error = desviacion_eolico[hora] * lista_RE[re].Pd[hora] * confianza_90
                    
                    generacion_eolicaI[1,hora] += max(0, lista_RE[re].Pd[hora] - error)
                    generacion_eolicaI[2,hora] += max(0, lista_RE[re].Pd[hora] + error)
                    error = desviacion_eolico[hora] * lista_RE[re].Pd[hora] * confianza_99
                    generacion_eolicaI[3,hora] += max(0, lista_RE[re].Pd[hora] - error)
                    generacion_eolicaI[4,hora] += max(0, lista_RE[re].Pd[hora] + error)
                elseif gen.Type == "Solar"
                    error = desviacion_solar[hora] * lista_RE[re].Pd[hora] * confianza_90
                    generacion_solarI[1,hora] += max(0, lista_RE[re].Pd[hora] - error)
                    generacion_solarI[2,hora] += max(0, lista_RE[re].Pd[hora] + error)
                    error = desviacion_solar[hora] * lista_RE[re].Pd[hora] * confianza_99
                    generacion_solarI[3,hora] += max(0, lista_RE[re].Pd[hora] - error)
                    generacion_solarI[4,hora] += max(0, lista_RE[re].Pd[hora] + error)
                else
                    error = 0
                    println("Fallo en tipo de generación")
                end
            end
            generacion_totalI[1, hora] = generacion_eolicaI[1,hora] + generacion_solarI[1,hora]
            generacion_totalI[2, hora] = generacion_eolicaI[2,hora] + generacion_solarI[2,hora]
            generacion_totalI[3, hora] = generacion_eolicaI[3,hora] + generacion_solarI[3,hora]
            generacion_totalI[4, hora] = generacion_eolicaI[4,hora] + generacion_solarI[4,hora]
        end
        return generacion_total_eolica, generacion_total_solar, generacion_total_renovable, generacion_eolicaI, generacion_solarI, generacion_totalI
    end


    function obtener_datos_MC()
        dir = @__DIR__
        file_path = joinpath(dir, "..", "Parametros", "Case118.xlsx")
        sheet_gen = "Generators"
        sheet_RE = "Renewables"

        gens = read_excel_generators(file_path, sheet_gen);
        re = read_excel_RE(file_path, sheet_RE);
        montecarlo_RE_excel(gens,re)

        return montecarlo_RE(gens,re)
        #Para llamar: res_90, res_99, lista_escenarios_generacion = obtener_datos_MC()
    end

    function datos_MC_graficar()
        dir = @__DIR__
        file_path = joinpath(dir, "..", "Parametros", "Case118.xlsx")
        sheet_gen = "Generators"
        sheet_RE = "Renewables"

        gens = read_excel_generators(file_path, sheet_gen);
        re = read_excel_RE(file_path, sheet_RE);
        generacion_total_eolica, generacion_total_solar, generacion_total_renovable, generacion_eolicaI, generacion_solarI, generacion_totalI = montecarlo_datos(gens,re)

        return generacion_total_eolica, generacion_total_solar, generacion_total_renovable, generacion_eolicaI, generacion_solarI, generacion_totalI
    end

end

