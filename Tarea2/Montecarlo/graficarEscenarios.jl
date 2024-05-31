module GraficaEsc

    include(joinpath("montecarlo.jl"))

    using Plots, .Montecarlo, XLSX
    export graficarMC

    function graficarEsc(data::Array{Float64, 2}, ranges::Array{Float64, 2}, title::String, filename::String)
        num_horas, num_escenarios = size(data)
    
        # Crear el gráfico de las trayectorias
        plot(1:num_horas, data[:, 1], label="", lw=0.5, color=:blue, alpha=0.3)
        for i in 2:num_escenarios
            plot!(1:num_horas, data[:, i], label="", lw=0.5, color=:blue, alpha=0.3)
        end
    
        # Añadir las líneas de los rangos
        lower_range1 = ranges[1, :]
        upper_range1 = ranges[2, :]
        lower_range2 = ranges[3, :]
        upper_range2 = ranges[4, :]
    
        plot!(1:num_horas, lower_range1, label="Lower Range 90%", lw=2, color=:red, linestyle=:dash)
        plot!(1:num_horas, upper_range1, label="Upper Range 90%", lw=2, color=:red, linestyle=:dash)
        plot!(1:num_horas, lower_range2, label="Lower Range 99%", lw=2, color=:green, linestyle=:dot)
        plot!(1:num_horas, upper_range2, label="Upper Range 99%", lw=2, color=:green, linestyle=:dot)
    
        # Añadir título y etiquetas
        title!(title)
        xlabel!("Hour")
        ylabel!("Generation (MW)")
    
        # Guardar el gráfico
        savefig(filename)
    end

    function graficarMC()
        generacion_total_eolica, generacion_total_solar, generacion_total_renovable, generacion_eolicaI, generacion_solarI, generacion_totalI = datos_MC_graficar()
        graficarEsc(generacion_total_eolica, generacion_eolicaI, "Total Eólica", joinpath(@__DIR__, "..", "Resultados", "TotalEolica.png"))
        graficarEsc(generacion_total_solar, generacion_solarI, "Total Solar", joinpath(@__DIR__, "..", "Resultados", "TotalSolar.png"))
        graficarEsc(generacion_total_renovable, generacion_totalI, "Total Renovables", joinpath(@__DIR__, "..", "Resultados", "TotalER.png"))
    end

end