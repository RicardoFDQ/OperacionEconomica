
# Módulo con los structs que representan a los elementos del sistema
module ModuloStructs

   export  Barra, Generador, Linea, Bateria


    # Struct que representa a las barras
    struct Barra
        id::Int64
        demanda::Vector{Int64}
    end

    # Struct que representa a los generadores
    struct Generador
        id::Int64
        p_min::Int64
        p_max::Int64
        costo::Int64
        rampa::Int64
        barra::Int64
    end

    # Struct que representa a las líneas
    struct Linea
        id::Int64
        barra_ini::Int64
        barra_fin::Int64
        p_max::Int64
        reactancia::Float64
    end

    # Struct que representa a las baterías
    struct Bateria
        id::Int64
        cap_potencia::Int64
        cap_energia::Int64
        rend::Float64
        barra::Int64
        energia_inicial::Float64
        energia_final::Float64
    end

    # Las siguientes sobrecargas de hacen para que cuando se printeen los structs no se
    # muestren todos los modulos involucrados en la generación de estos.

    # Sobrecarga de la función show para Barra
    Base.show(io::IO, b::Barra) = print(io, "Barra(id=$(b.id), demanda=$(b.demanda))")

    # Sobrecarga de la función show para Generador
    Base.show(io::IO, g::Generador) = print(io, "Generador(id=$(g.id), p_min=$(g.p_min), p_max=$(g.p_max), costo=$(g.costo), rampa=$(g.rampa), barra=$(g.barra))")

    # Sobrecarga de la función show para Linea
    Base.show(io::IO, l::Linea) = print(io, "Linea(id=$(l.id), barra_ini=$(l.barra_ini), barra_fin=$(l.barra_fin), p_max=$(l.p_max), reactancia=$(l.reactancia))")

    # Sobrecarga de la función show para Bateria
    Base.show(io::IO, ba::Bateria) = print(io, "Bateria(id=$(ba.id), cap=$(ba.cap), rend=$(ba.rend), barra=$(ba.barra))")

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

    # Sobrecarga de la función show para un Array de Bateria
    Base.show(io::IO, baterias::Array{ModuloStructs.Bateria}) = begin
        print(io, "[")
        for (i, bateria) in enumerate(baterias)
            print(io, "Bateria(id=$(bateria.id), cap=$(bateria.cap), rend=$(bateria.rend), barra=$(bateria.barra))")
            if i < length(baterias)
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
            print(io, "Generador(id=$(generador.id), p_min=$(generador.p_min), p_max=$(generador.p_max), costo=$(generador.costo), rampa=$(generador.rampa), barra=$(generador.barra))")
            if i < length(generadores)
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

    # Sobrecarga de la función show para un diccionario de Baterías
    Base.show(io::IO, dict::Dict{Int64, Vector{ModuloStructs.Bateria}}) = begin
        print(io, "Dict{Int64, Vector{Bateria}}(")
        first = true
        for (key, baterias) in dict
            if !first
                print(io, ", ")
            end
            first = false
            print(io, key, " => ", baterias)
        end
        print(io, ")")
    end


end
