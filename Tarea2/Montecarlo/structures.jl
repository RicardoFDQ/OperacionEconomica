
module Structures
    # structures.jl
    using XLSX
    using DataFrames

    export Gen, Bus, Demand, Line, REnergy
    export read_excel_generators, read_excel_demand, read_excel_bus, read_excel_line, read_excel_RE, get_list_id, is_equal

    # Gen (GENERATOR) C = Cost; P = Power; Q = Reactive
    struct Gen
        id::String
        Bus::String
        Pmax::Real
        Pmin::Real
        Qmax::Real
        Qmin::Real
        Ramp::Real
        SRamp::Real
        MinUP::Real
        MinDW::Real
        InitS::Real
        InitP::Real
        StartUpC::Real
        FixedC::Real
        VarC::Real
        Type::String
    end

    # Bus (NODE) #Voltage max - min, Gs, Bs, Demand
    struct Bus
        id::String
        Vmax::Real
        Vmin::Real
        Gs::Real
        Bs::Real
        #Gens::Vector{String}
    end

    struct Demand
        id::String
        Pd::Vector{Real}
        Qd::Vector{Real}
    end

    struct Line
        id::String
        Bus::Vector{String} #Bus conections
        R::Real     #Resistance
        X::Real #Reactance
        LineC::Real #Line Charging
        MaxF::Real  #Max Flow
    end

    struct REnergy #Renovables Energy
        id::String
        Pd::Vector{Real}
    end

    # Función para leer un archivo .xlsx y crear una lista de MyStruct
    function read_excel_generators(file_path::String, sheet_name::String)
        xf = XLSX.readxlsx(file_path)
        sh = xf[sheet_name]
        init = false
        lista_gen = Vector{Gen}()
        for r in XLSX.eachrow(sh)
            rn = XLSX.row_number(r)
            cA = r[1]
            if cA == "END"
                init = false
                return lista_gen
            end
            if init
                r1 = string(r[1])
                r2 = string(r[2])
                r3 = Float64(r[3])
                r4 = Float64(r[4])
                r5 = Float64(r[5])
                r6 = Float64(r[6])
                r7 = Float64(r[7])
                r8 = Float64(r[8])
                r9 = Float64(r[9])
                r10 = Float64(r[10])
                r11 = Float64(r[11])
                r12 = Float64(r[12])
                r13 = Float64(r[13])
                r14 = Float64(r[14])
                r15 = Float64(r[15])
                r16 = string(r[16])
                generator = Gen(r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,r16)
                push!(lista_gen, generator)
            end
            if cA == "Generator"
                init = true
            end
        end

        return lista_gen
    end

    function read_excel_bus(file_path::String, sheet_bus::String)
        xf = XLSX.readxlsx(file_path)
        shb = xf[sheet_bus]
        init = false
        lista_bus = Vector{Bus}()
        for r in XLSX.eachrow(shb)
            rn = XLSX.row_number(r)
            cA = r[1]
            if cA == "END"
                init = false
                return lista_bus
            end
            if init
                r1 = string(r[1])
                r2 = Float64(r[2])
                r3 = Float64(r[3])
                r4 = Float64(r[4])
                r5 = Float64(r[5])
                bus = Bus(r1,r2,r3,r4,r5)
                push!(lista_bus, bus)
            end
            if cA == "Bus"
                init = true
            end
        end

        return lista_bus
    end

    function read_excel_demand(file_path::String, sheet_dm::String)
        xf = XLSX.readxlsx(file_path)
        sh = xf[sheet_dm]

        first_row = sh[1,:]
        pd_index = findall(n -> is_equal(n, "Pd [MW]"), first_row)
        qd_index = findall(n -> is_equal(n, "Qd [MVAR]"), first_row)
        pd_index = pd_index[1][2]
        qd_index = qd_index[1][2]

        init = false
        lista_dm = Vector{Demand}()
        for r in XLSX.eachrow(sh)
            rn = XLSX.row_number(r)
            cA = r[1]
            if cA == "END"
                init = false
                return lista_dm
            end
            if init
                r1 = string(r[1])
                r2 = Vector{Real}()
                r3 = Vector{Real}()
                for i in range(1,24)
                    push!(r2, r[pd_index+i])
                    push!(r3, r[qd_index+i])
                end
                dm = Demand(r1,r2,r3)
                push!(lista_dm, dm)
            elseif cA == "Bus/Hour"
                init = true
            end
        end

        return lista_dm
    end

    function read_excel_line(file_path::String, sheet_ln::String)
        xf = XLSX.readxlsx(file_path)
        sh = xf[sheet_ln]

        init = false
        lista_ln = Vector{Line}()
        for r in XLSX.eachrow(sh)
            rn = XLSX.row_number(r)
            cA = r[1]
            if cA == "END"
                init = false
                return lista_ln
            end
            if init
                r1 = string(r[1])
                r2 = string(r[2])
                r3 = string(r[3])
                r4 = Float64(r[4])
                r5 = Float64(r[5])
                r6 = Float64(r[6])
                r7 = Float64(r[7])
                bus = Vector{String}()
                push!(bus, r2)
                push!(bus, r3)
                ln = Line(r1,bus,r4,r5,r6,r7)
                push!(lista_ln, ln)
            elseif cA == "Branch Name"
                init = true
            end
        end

        return lista_ln
    end

    function read_excel_RE(file_path::String, sheet_RE::String)
        xf = XLSX.readxlsx(file_path)
        sh = xf[sheet_RE]

        init = false
        lista_RE = Vector{REnergy}()
        for r in XLSX.eachrow(sh)
            rn = XLSX.row_number(r)
            cA = r[1]
            if cA == "END"
                init = false
                return lista_RE
            end
            if init
                r1 = string(r[1])
                r2 = Vector{Real}()
                for i in range(2,25)
                    push!(r2, r[i])
                end
                re = REnergy(r1,r2)
                push!(lista_RE, re)
            elseif cA == "Gen/Hour"
                init = true
            end
        end

        return lista_RE
    end

    function get_list_id(id::String, list::Vector{})
        index = findall(g -> g.id == id, list)
        index =  isempty(index) ? 1 : index[1]
        return list[index]
    end

    function is_equal(value, target)
        return !ismissing(value) && value == target
    end

    #Seccion de pruebas
    function pruebas_excel()
        file_path = "Datos/Case118.xlsx"
        sheet_gen = "Generators"

        G = read_excel_generators(file_path, sheet_gen)
        select = get_list_id("G2", G)
        println(select)

        sheet_bus = "Buses"
        B = read_excel_bus(file_path, sheet_bus)
        select = get_list_id("Bus2", B)
        println(select)

        sheet_dm = "Demand"
        D = read_excel_demand(file_path, sheet_dm)
        select = get_list_id("Bus2", D)
        #println(select)

        sheet_ln = "Lines"
        D = read_excel_line(file_path, sheet_ln)
        select = get_list_id("Line1To2", D)
        println(select)

        sheet_RE = "Renewables"
        RE = read_excel_RE(file_path, sheet_RE)
        select = get_list_id("Wind2", RE)
        println(select)
    end
end