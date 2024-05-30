
# Módulo con los structs que representan a los elementos del sistema
module ModuloStructs

   export  Barra, Generador, Linea, Renovable


    # Struct que representa a las barras
    struct Barra
        id::Int64
        demanda::Vector{Float64}
    end

    # Struct que representa a los generadores convencionales
    struct Generador
        nombre::String
        id::Int64
        p_min::Float64
        p_max::Float64
        p_inicial::Float64
        costo::Float64
        costo_start_up::Float64
        costo_no_load::Float64
        minimum_up_time::Int64
        minimum_down_time::Int64
        estado_inicial::Int64
        rampa_start::Float64
        rampa::Float64
        barra::Int64
    end

    # Struct que representa a plantas renovables
    mutable struct Renovable
        nombre::String
        id::Int64
        barra::Int64
        p_pronosticada::Vector{Float64}
        p_min::Float64
        p_inicial::Float64
        rampa::Float64
        rampa_start::Float64
        minimum_up_time::Int64
        minimum_down_time::Int64
        estado_inicial::Int64
    end

    # Struct que representa a las líneas
    struct Linea
        id::String
        barra_ini::Int64
        barra_fin::Int64
        p_max::Float64
        reactancia::Float64
    end


    # Las siguientes sobrecargas de hacen para que cuando se printeen los structs no se
    # muestren todos los modulos involucrados en la generación de estos.

    # Sobrecarga de la función show para Barra
    Base.show(io::IO, b::Barra) = print(io, "Barra(id=$(b.id), demanda=$(b.demanda))")
    # Sobrecarga de la función show para Generador
    Base.show(io::IO, g::Generador) = print(io, "Generador(nombre=$(g.nombre) ,id=$(g.id), p_min=$(g.p_min), p_max=$(g.p_max), p_inicial=$(g.p_inicial), costo=$(g.costo), costo_start_up=$(g.costo_start_up), costo_no_load=$(g.costo_no_load), minimum_up_time=$(g.minimum_up_time), minimum_down_time=$(g.minimum_down_time), estado_inicial=$(g.estado_inicial), rampa_start=$(g.rampa_start), rampa=$(g.rampa), barra=$(g.barra))")
    # Sobrecarga de la función show para Linea
    Base.show(io::IO, l::Linea) = print(io, "Linea(id=$(l.id), barra_ini=$(l.barra_ini), barra_fin=$(l.barra_fin), p_max=$(l.p_max), reactancia=$(l.reactancia))")
    # Sobrecarga de la función show para Renovable
    Base.show(io::IO, r::Renovable) = print(io, "Renovable(nombre=$(r.nombre), barra=$(r.barra), id=$(r.id), p_pronosticada=$(r.p_pronosticada), p_min=$(r.p_min), p_inicial=$(r.p_inicial), rampa=$(r.rampa), rampa_start=$(r.rampa_start), minimum_up_time=$(r.minimum_up_time), minimum_down_time=$(r.minimum_down_time), estado_inicial=$(r.estado_inicial))")
    
    # Sobrecarga de la función show para un Array de Barra
    Base.show(io::IO, barras::Array{ModuloStructs.Barra}) = begin
        print(io, "[")
        for (i, barra) in enumerate(barras)
            print(io, "Barra(id=$(barra.id), demanda=$(barra.demanda))")
            if i < length(barras)
                print(io, ", ")
            end
        end
        print(io, "]")
    end


    # Sobrecarga de la función show para un Array de Linea
    Base.show(io::IO, lineas::Array{ModuloStructs.Linea}) = begin
        print(io, "[")
        for (i, linea) in enumerate(lineas)
            print(io, "Linea(id=$(linea.id), barra_ini=$(linea.barra_ini), barra_fin=$(linea.barra_fin), p_max=$(linea.p_max), reactancia=$(linea.reactancia))")
            if i < length(lineas)
                print(io, ", ")
            end
        end
        print(io, "]")
    end

    # Sobrecarga de la función show para un Array de Generador
    Base.show(io::IO, generadores::Array{ModuloStructs.Generador}) = begin
        print(io, "[")
        for (i, generador) in enumerate(generadores)
            print(io, "Generador(id=$(generador.id), p_min=$(generador.p_min), p_max=$(generador.p_max), p_inicial=$(generador.p_inicial), costo=$(generador.costo), rampa=$(generador.rampa), barra=$(generador.barra))")
            if i < length(generadores)
                print(io, ", ")
            end
        end
        print(io, "]")
    end

    # Sobrecarga de la función show para un Array de Renovable
    Base.show(io::IO, renovables::Array{ModuloStructs.Renovable}) = begin
        print(io, "[")
        for (i, renovable) in enumerate(renovables)
            print(io, "Renovable(nombre=\"$(renovable.nombre)\", barra=\"$(renovable.barra)\", id=\"$(renovable.id)\", p_pronosticada=\"$(renovable.p_pronosticada)\", p_min=\"$(renovable.p_min)\", p_inicial=\"$(renovable.p_inicial)\", rampa=\"$(renovable.rampa)\", rampa_start=\"$(renovable.rampa_start)\", minimum_up_time=\"$(renovable.minimum_up_time)\", minimum_down_time=\"$(renovable.minimum_down_time)\", estado_inicial=\"$(renovable.estado_inicial)\")")
            if i < length(renovables)
                print(io, ", ")
            end
        end
        print(io, "]")
    end

    # Sobrecarga de la función show para un diccionario de Generadores
    Base.show(io::IO, dict::Dict{Int64, Vector{ModuloStructs.Generador}}) = begin
        print(io, "Dict{Int64, Vector{Generador}}(")
        first = true
        for (key, generadores) in dict
            if !first
                print(io, ", ")
            end
            first = false
            print(io, key, " => ", generadores)
        end
        print(io, ")")
    end

    # Sobrecarga de la función show para un diccionario de Líneas
    Base.show(io::IO, dict::Dict{Int64, Vector{ModuloStructs.Linea}}) = begin
        print(io, "Dict{Int64, Vector{Linea}}(")
        first = true
        for (key, lineas) in dict
            if !first
                print(io, ", ")
            end
            first = false
            print(io, key, " => ", lineas)
        end
        print(io, ")")
    end




end
