using CImGui
using ImPlot
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using Base.Iterators: partition

include("src/Renderer.jl")
# include("src/GuiMod.jl")
using .Renderer
using GuiMod

# using Pkg
# Pkg.add(name="ImPlot", rev="main")
# Pkg.add(name="LibCImGui", version="1.82.2")

tableParser = GuiMod.JSON3.read("src/tableHeader.json", Dict)

ecgChannelsNames = ["I", "II", "III", "aVR", "aVL", "aVF", "V1", "V2", "V3", "V4", "V5", "V6"]

tableFlags = CImGui.ImGuiTableFlags_SizingStretchSame | 
            CImGui.ImGuiTableFlags_Resizable | 
            CImGui.ImGuiTableFlags_ContextMenuInBody | 
            CImGui.ImGuiTableFlags_Borders | 
            CImGui.ImGuiTableFlags_RowBg | 
            CImGui.ImGuiTableFlags_NoHostExtendX |
            CImGui.ImGuiTableFlags_SizingFixedFit

Color = Dict(
    :Q_onset => CImGui.ImVec4(1.0, 0.5, 0.33, 1.0),
    :Q_end => CImGui.ImVec4(1.0, 0.5, 0.33, 1.0),
    :R1_onset => CImGui.ImVec4(0.75, 0.0, 0.95, 1.0),
    :R1_end => CImGui.ImVec4(0.75, 0.0, 0.95, 1.0),
    :R2_onset => CImGui.ImVec4(0.0, 0.71, 1.0, 1.0),
    :R2_end => CImGui.ImVec4(0.0, 0.71, 1.0, 1.0),
    :S_onset => CImGui.ImVec4(0.0, 1.0, 0.33, 1.0),
    :S_end => CImGui.ImVec4(0.0, 1.0, 0.33, 1.0)
)

state = GuiMod.PlotState(
    [zeros(Float64,9600), zeros(Float64,9600)],
    0,
    [0],
    [0],
    [0],
    [0],
    [0],
    GuiMod.HeaderInfo(),
    GuiMod.Result(
        GuiMod.Settings(),
        [GuiMod.Complexes(
            GuiMod.GlobalParams(),
            GuiMod.GlobalBounds(),
            GuiMod.ChannelBounds(),
            GuiMod.ChannelParams())],
            0,
            GuiMod.HeaderInfo(),
            GuiMod.ChunkParams(),
            [0]
            ),
    (min = 1, max = 9600),
    (min = -12*2000, max = 1))
const USERDATA = Dict{String, Any}(
    "AvailableDataBases" => [""],
    "AvailableRecords" => [GuiMod.HeaderInfo()],
    "ActiveComplexInd" => 1,
    "ActiveChannel" => [""],
    "ActiveCursor" =>[""],
    "ActiveMark" =>[""],
    "ActiveFilters" => [false, false, false],
    "ActiveSettings" => GuiMod.Settings(),
    "RepresentativeCompInd" => 1,
    "Cursor" => GuiMod.Cursor(100,100),
    "Range" => [Cint(1), Cint(200)],
    "Record" => [""],
    "N_of_pix" => 700 
)

try
    USERDATA["AvailableDataBases"] = GuiMod.get_db_list()
catch
end

# хранилище, привязанное к ID виджетов
const STORAGE = Dict{UInt32, Any}()
get_uistate(key::String, default = nothing) = get(STORAGE, CImGui.GetID(key), default)
set_uistate(key::String, value) = STORAGE[CImGui.GetID(key)] = value

function change_ecg_scan(state::GuiMod.PlotState, mm_per_sec::Int)
    res = read(`wmic desktopmonitor get pixelsperxlogicalinch`, String)
    m = match(r"[0-9]+", res)
    pix_per_mm = parse(Int, m.match)/25.4
    sec = state.record_info.length/state.record_info.freq
    n_of_pix = round(Int, sec*mm_per_sec*pix_per_mm)
    return n_of_pix
end

function find_chosen_complex(state :: GuiMod.PlotState, cursor::GuiMod.Cursor)
    for i in eachindex(state.result.complexes)
        ibeg = get_ibeg_or_iend(state.result.complexes[i].bounds, true)
        iend = get_ibeg_or_iend(state.result.complexes[i].bounds, false)
        #!isdisjoint(cursor.leftBorder:cursor.rightBorder, ibeg:iend) - if we need to check whether ibeg:iend is inside
        #left:right border or vice verca
        if ibeg <= cursor.pos <= iend
            return i
        end
    end
    return nothing
end

function select_base(selected_db_name::String, dataBases::Vector{String})

    CImGui.Text("Базы:")

    for dB in dataBases

        label = dB

        if CImGui.Selectable(label, selected_db_name == dB)

            set_uistate("selected_database",dB)
            GuiMod.select_db(dB)
            USERDATA["AvailableRecords"] = GuiMod.get_record_list()

        end


    end

end

function select_records(selected_record_name, records::Vector{GuiMod.HeaderInfo})

    CImGui.Text("Записи:")

    for record in records

        record = record.filename
        label = record

        if CImGui.Selectable(label, selected_record_name == record)

            set_uistate("selected_record",record)
            USERDATA["Record"] = record
            USERDATA["ActiveComplexInd"] = GuiMod.get_representative(record) + 1 # zero-based.
            USERDATA["RepresentativeCompInd"] = GuiMod.get_representative(record) + 1
            USERDATA["ActiveSettings"] = [false, false]
            state.record_info = GuiMod.get_record_info(record)
            USERDATA["Range"][2] = Cint(state.record_info.length)
            state.signal = GuiMod.get_signal(record, 1, state.record_info.length)
            state.result = GuiMod.get_result(record)
            USERDATA["ActiveSettings"] = GuiMod.get_settings(record)
            state.numChn = length(keys(state.signal))
            GuiMod.vector_of_structs_to_struct_vector(state)

        end

    end
end

function show_stats(wigit_name::String, info::GuiMod.HeaderInfo)

    CImGui.Text("Stats:")
    CImGui.BeginTable(wigit_name,2, tableFlags)

    for property in propertynames(info)
        CImGui.TableNextRow()
        CImGui.TableSetColumnIndex(0)
        CImGui.Text("$(String(property))")
        CImGui.TableSetColumnIndex(1)
        CImGui.Text("$(getfield(info,property))")
    end

    CImGui.EndTable()
end

function parse_process_data(data :: Any)
    if isa(data, Float64)
        return trunc(data; digits = 2)
    elseif isa(data, Vector{Float64})
        return join(map(x -> trunc(x, digits = 2), data), "\n")
    elseif isa(data, Vector) 
        return join(data, "\n")
    elseif isa(data, Int)
        return data 
    elseif isa(data, String)
        return data
    end 
end

function show_parameters(wigitName :: String, complexes :: Vector{GuiMod.Complexes}, applySelection::Bool)

    params = complexes[1].params

    propNames = propertynames(params)
    num_of_strs_in_one_col = ceil(Int,length(propNames)/3)
    propNames = collect(partition(propNames, num_of_strs_in_one_col))

    CImGui.Columns(7, wigitName)
    CImGui.Separator()
    CImGui.Text("#"); CImGui.NextColumn()
    for _ in range(1,6)
        CImGui.Text("Параметры"); CImGui.NextColumn()
    end
    CImGui.Separator()

    for complex_ind in eachindex(complexes)

        # Как лучше - создать отдельную таблицу или добавить усвловия в эту?...
        num = complex_ind
        if length(complexes) == 1
            num = USERDATA["ActiveComplexInd"]
        end

        if CImGui.Selectable("$num"*repeat("\n", num_of_strs_in_one_col), complex_ind == USERDATA["ActiveComplexInd"], CImGui.ImGuiSelectableFlags_SpanAllColumns)
            USERDATA["ActiveComplexInd"] = num
        end
        CImGui.NextColumn()
        params = complexes[complex_ind].params
        for headers in propNames

            str = join(collect(map(x -> String(x), headers)), "\n")
            CImGui.Text("$str")
            CImGui.NextColumn()
            str = join(collect(map(x -> parse_process_data(getfield(params, x)), headers)), "\n")
            CImGui.Text("$str")
            CImGui.NextColumn()

        end
        CImGui.Separator()
    end
    CImGui.Columns()
    CImGui.Separator()
end

function get_ibeg_or_iend(cycle::GuiMod.GlobalBounds, min::Bool)
    propertys = propertynames(cycle)
    arr = []
    for property in propertys
        element = getfield(cycle, property)
        if !isa(element, Nothing)
            append!(arr, element)
        end
    end

    if isempty(arr)
        return 1
    end

    if min
        return minimum(arr)
    else
        return maximum(arr)
    end
end

# need to check if ibeg is > then the smallest value of cycle somehow...
function get_begin_end_marks(cycle_bound::GuiMod.GlobalBounds, cycle_main::GuiMod.GlobalBounds, min::Bool)
    propertys = propertynames(cycle_bound)
    arr_bound = []
    arr_main = []
    for property in propertys
        element = getfield(cycle_bound,property)
        if !isa(element, Nothing)
            append!(arr_bound,element)
        end

        element = getfield(cycle_main,property)
        if !isa(element, Nothing)
            append!(arr_main,element)
        end
    end

    if isempty(arr_bound)
        return 1
    end

    if min
        sort!(arr_bound)
        for item in arr_bound
            if item > maximum(arr_main)
                return item
            end
        end
    else
        sort!(arr_bound, rev = true)
        for item in arr_bound 
            if item < minimum(arr_main)
                return item
            end
        end
    end
end

function show_shifts(propertys::Vector{Symbol}, complexes :: Vector{GuiMod.Complexes}, applySelection::Bool)

    CImGui.Columns(length(ecgChannelsNames)+2,"#shifts")
    CImGui.Separator()
    headers = ecgChannelsNames
    for header in [["Номер","Параметры"]; headers]
        CImGui.Text("$header"); CImGui.NextColumn()
    end
    CImGui.Separator()

    for complexInd in eachindex(complexes)
        num = complexInd
        if length(complexes) == 1
            num = USERDATA["ActiveComplexInd"]
        end
        s = ""

        for item in propertys
            s *= "$(String(item))\n"
        end
        if CImGui.Selectable("#$num"*repeat("\n", length(propertys)), complexInd == USERDATA["ActiveComplexInd"], CImGui.ImGuiSelectableFlags_SpanAllColumns)
            USERDATA["ActiveComplexInd"] = num
        end
        CImGui.NextColumn()
        CImGui.Text("$s")
        CImGui.NextColumn()

        for ind in eachindex(getfield(complexes[complexInd].channel_params, propertys[1]))
            s = ""
            for item in propertys
                s *= "$(parse_process_data(getfield(complexes[complexInd].channel_params, item)[ind]))\n"
            end
            CImGui.Text("$s")
            CImGui.NextColumn()
        end
        CImGui.Separator()

    end
    CImGui.Columns()
    CImGui.Separator()
end

function show_chunk_params(params::GuiMod.ChunkParams)

    param_values = ""
    CImGui.Columns(2,"#chunk")
    CImGui.Separator()
    for header in ["Параметры","Значения"]
        CImGui.Text("$header"); CImGui.NextColumn()
    end
    CImGui.Separator()

    propertys = propertynames(params)
    param_names = join(propertys, "\n")
    for item in propertys
        param_values = "$param_values"*"$(getfield(params, item))\n"
    end

    CImGui.Text("$param_names"); CImGui.NextColumn()
    CImGui.Text("$param_values")
    CImGui.Separator()
end

function plot_repr_graph(ch::Vector{Float64}, state::GuiMod.PlotState, counter::Int)

    flags = ImPlotAxisFlags_NoTickLabels | ImPlotAxisFlags_NoDecorations
    chosenComplexInd = USERDATA["ActiveComplexInd"]
    cursor = USERDATA["Cursor"]
    ecg = state.signal
    ymin = minimum(minimum.(ecg))
    ymax = maximum(maximum.(ecg))
    
    ImPlot.PushStyleVar(ImPlotStyleVar_PlotPadding, CImGui.ImVec2(0,0))
    ImPlot.SetNextPlotLimits(1, state.xlim.max, ymin, ymax, CImGui.ImGuiCond_Always)
    
    if ImPlot.BeginPlot("#Plot"*"$counter","","",CImGui.ImVec2(-1,ceil(CImGui.GetWindowHeight()/6));
        flags = ImPlotFlags_CanvasOnly|ImPlotFlags_NoChild,
        x_flags = flags, y_flags = flags)
    
        if !isnothing(chosenComplexInd)
    
            chBounds = state.result.complexes[chosenComplexInd].channel_bounds
    
            if chosenComplexInd == 1
                ibeg = 1
            else
                ibeg = get_begin_end_marks(state.result.complexes[chosenComplexInd - 1].bounds,
                state.result.complexes[chosenComplexInd].bounds, false)
            end
    
            if chosenComplexInd == length(state.result.complexes)
                iend = lastindex(ecg[1])
            else
                iend = get_begin_end_marks(state.result.complexes[chosenComplexInd + 1].bounds, 
                state.result.complexes[chosenComplexInd].bounds, true)
            end
    
            cycle = state.result.complexes[chosenComplexInd].bounds
            fields = propertynames(cycle) 
            ImPlot.PlotLine(Float64.(ch[ibeg:iend]))
            ImPlot.PlotText("$(ecgChannelsNames[counter])", 100, 0)
    
            for field in fields
                bound = getfield(cycle, field)
                if isa(bound, Nothing)
                    continue
                end
                ImPlot.PlotVLines("$field", Ref(trunc.(Int,bound) .- (ibeg)), length(bound))
            end
    
            props = propertynames(chBounds)
            for prop in props
                field = getfield(chBounds,prop)[counter]
                if isa(field, Nothing)
                    continue
                end
                ImPlot.PushStyleColor(ImPlotCol_MarkerOutline, Color[prop])
                ImPlot.PlotScatter([field - ibeg], [ch[field]]; label_id = String(prop))
                ImPlot.PopStyleColor()
            end
    
            if CImGui.IsItemHovered(CImGui.ImGuiHoveredFlags_AllowWhenBlockedByPopup) & CImGui.IsMouseClicked(1)
                USERDATA["ActiveMark"] = GuiMod.find_mark(cycle, ibeg)
            elseif CImGui.IsItemHovered(CImGui.ImGuiHoveredFlags_AllowWhenBlockedByPopup) & CImGui.IsMouseDown(1)
                actMark = USERDATA["ActiveMark"]
                GuiMod.move_mark(cycle, actMark, ibeg, lastindex(ecg[1]))
                GuiMod.vector_of_structs_to_struct_vector(state)
            else
                USERDATA["flag"] = CImGui.ImGuiCond_Once
            end
    
            else
                ibeg = (cursor.leftBorder < 0) ? 1 : cursor.leftBorder
                iend = (cursor.rightBorder > lastindex(ecg[1])) ? lastindex(ecg[1]) : cursor.rightBorder
    
                ImPlot.PlotLine(Float64.(ch[ibeg:iend]))
                ImPlot.PlotText("$(ecgChannelsNames[counter])", 100, 0)
            end
    
            state.xlim = (min = ibeg, max = iend-ibeg)
            ImPlot.EndPlot()
        end
    
    ImPlot.PopStyleVar()
end

function ui()

    dataBases = USERDATA["AvailableDataBases"]
    records = USERDATA["AvailableRecords"]
    CImGui.BeginTabBar("##Tabs")

        if CImGui.BeginTabItem("Базы и записи")

            CImGui.BeginGroup()

                CImGui.BeginChild("Bases", CImGui.ImVec2(150, -CImGui.GetFrameHeightWithSpacing()), true)

                    selected_db_name = get_uistate("selected_database", "None") 
                    select_base(selected_db_name, dataBases)

                CImGui.EndChild()

            CImGui.EndGroup()
            CImGui.SameLine()
            CImGui.BeginGroup()

                CImGui.BeginChild("Records", CImGui.ImVec2(150, -CImGui.GetFrameHeightWithSpacing()), true)

                    selected_record_name = get_uistate("selected_record", "None")
                    select_records(selected_record_name, records)

                CImGui.EndChild()

            CImGui.EndGroup()
            CImGui.SameLine()
            CImGui.BeginGroup()

                show_stats("BaseStats", state.record_info)
                CImGui.Separator()

            CImGui.EndGroup()

            if CImGui.Button("Обновить")
                dataBases = GuiMod.get_db_list()
            end

        CImGui.EndTabItem()

        end

    CImGui.EndTabBar()

    USERDATA["AvailableDataBases"] = dataBases

    Viewer(state)
    ParamsTable(state)
    AmpTable(state)
    ShiftsTable(state)
    ChunkParamsTable(state)

    RepresentatieveComplexParamsTable(state, USERDATA["ActiveComplexInd"])
end

function Viewer(state::GuiMod.PlotState)

    ecg = state.signal
    
    if CImGui.Begin("Просмотр")

        cursor = USERDATA["Cursor"]
        counter = 1

        CImGui.Text("Настройки:")
        offset = Cfloat(USERDATA["ActiveSettings"].QRSsensitivity)
        spikes = USERDATA["ActiveSettings"].isspikes
        isoline = USERDATA["ActiveFilters"][1]
        fiftyHz = USERDATA["ActiveFilters"][2]
        thirtyfiveHz = USERDATA["ActiveFilters"][3]
        from = USERDATA["Range"][1]
        to = USERDATA["Range"][2]

        if @c CImGui.SliderFloat("Настройка чувствительности",&offset, 0, 1)
            USERDATA["ActiveSettings"].QRSsensitivity = offset
        end
        CImGui.SameLine()
        @c CImGui.Checkbox("IsSpikes", &spikes)
        CImGui.Text("Выбор фильтра:")
        @c CImGui.Checkbox("isoline", &isoline)
        @c CImGui.Checkbox("50Hz", &fiftyHz)
        @c CImGui.Checkbox("35Hz", &thirtyfiveHz)
        CImGui.Text("Выбор диапазона:")
        @c CImGui.InputInt("from", &from)
        @c CImGui.InputInt("to", &to)

        if CImGui.Button("Применить")

            filters = Vector{String}()
            if isoline
                push!(filters, "isoline")
            end

            if fiftyHz
                push!(filters, "50hz")
            end

            if thirtyfiveHz
                push!(filters, "35hz")
            end

            if from < 0
                from = 1
            end

            if to > state.record_info.length
                to = state.record_info.length
            end

            
            if !isequal(USERDATA["Record"], [""]) && !isequal(USERDATA["ActiveSettings"], [""])
                GuiMod.change_settings(USERDATA["Record"], USERDATA["ActiveSettings"])
                USERDATA["ActiveComplexInd"] = 1
                state.signal = GuiMod.get_signal(USERDATA["Record"], 1, state.record_info.length, join(filters, ","))
                try
                    state.result.chunk_params = GuiMod.get_chunk_params(USERDATA["Record"], Int64(from), Int64(to))
                catch
                end
                state.result.complexes = GuiMod.get_complexes(USERDATA["Record"])
            end
        end
        CImGui.Text("Номер представительного комплекса: $(USERDATA["RepresentativeCompInd"])")
        items = ["50","20","10"]        
        @cstatic active_scan = Cint(2) begin
            if @c CImGui.Combo("Combo", &active_scan, items, length(items))
                USERDATA["N_of_pix"] = change_ecg_scan(state, parse(Int,items[active_scan+1]))
            end
        end
        USERDATA["ActiveFilters"] = [isoline, fiftyHz, thirtyfiveHz]
        USERDATA["Range"][1] = from
        USERDATA["Range"][2] = to

        flags = ImPlotAxisFlags_NoTickLabels | ImPlotAxisFlags_NoDecorations
        ImPlot.SetNextPlotLimits(1, to, -2000*length(ecg), maximum(ecg[1]), CImGui.ImGuiCond_Always)
        if ImPlot.BeginPlot("Навигационный график","x","y",CImGui.ImVec2(USERDATA["N_of_pix"],-1);
            flags = ImPlotFlags_NoLegend|ImPlotFlags_NoChild,
            y_flags=flags)

                k = 0
                for ch in ecg
                    ImPlot.PlotLine(Float64.(ch.-k))
                    ImPlot.PlotText("$(ecgChannelsNames[counter])", 10, -k)
                    counter += 1
                    k += 2000
                end

                for name in propertynames(state.result.complexes[1].bounds)
                    bound = getfield(state, name)
                    if isa(bound, Nothing) || isa(bound, Vector{Nothing})
                        continue
                    end
                    ImPlot.PlotVLines("$name", trunc.(Int,bound), length(bound))
                end

                ImPlot.PlotVLines("Cursor", Ref(cursor.pos), 1)

                if ImPlot.IsPlotHovered() && CImGui.IsMouseClicked(1)
                    cursor.pos = GuiMod.move_coursor()
                    GuiMod.update_cursor!(cursor)
                    USERDATA["ActiveComplexInd"] = find_chosen_complex(state, cursor)
                end
                
                ImPlot.EndPlot()
        end

        USERDATA["Cursor"] = cursor
        CImGui.End()
    end

    if CImGui.Begin("Просмотр представительного комплекса")
        counter = 1
        CImGui.BeginGroup()
            CImGui.BeginChild("#Plots1", CImGui.ImVec2(CImGui.GetWindowSize().x/2,-CImGui.GetFrameHeightWithSpacing()))
                for ch in ecg
                    if counter == 7
                        break
                    end
                    plot_repr_graph(ch, state, counter)
                    counter += 1
                end
            CImGui.EndChild()
        CImGui.EndGroup()
        if counter > 6
            CImGui.SameLine()
            CImGui.BeginGroup()
                CImGui.BeginChild("#Plots2", CImGui.ImVec2(-1,-CImGui.GetFrameHeightWithSpacing()))
                    for ind in range(7,12)
                        plot_repr_graph(ecg[ind], state, counter)
                        counter += 1
                    end
                CImGui.EndChild() 
            CImGui.EndGroup()
        end
        CImGui.Separator()

        if CImGui.Button("Редактировать границы")
            CImGui.OpenPopup("edit_boundaries")
        end
        edit_boundaries(state)

        CImGui.Separator()
        chosenComplexInd = USERDATA["ActiveComplexInd"]
        if CImGui.Button("Применить изменения")
            if !isequal(USERDATA["Record"],[""])
                GuiMod.post_complex(USERDATA["Record"], state.result.complexes[chosenComplexInd].bounds)
                state.result.complexes = GuiMod.get_complexes(USERDATA["Record"])
            end
        end
    CImGui.EndChild()
    CImGui.EndGroup()
    CImGui.End()
    end
end

function edit_boundaries(state::GuiMod.PlotState)

    chosenComplexInd = USERDATA["ActiveComplexInd"]

    if !isnothing(chosenComplexInd)

        if chosenComplexInd == 1
            ibeg = 1
        else
            ibeg = get_begin_end_marks(state.result.complexes[chosenComplexInd - 1].bounds,
            state.result.complexes[chosenComplexInd].bounds, false)
        end

        cylce = state.result.complexes[chosenComplexInd].bounds
        boundaries = ["P", "T"]
        if CImGui.BeginPopup("edit_boundaries")
            for boundary in boundaries
                if CImGui.Button("add $(boundary)")
                    field_onset = Symbol("$(boundary)_onset")
                    field_end = Symbol("$(boundary)_end")
                    if isnothing(getfield(cylce, field_end))
                        if hasproperty(cylce, field_onset)
                            setfield!(cylce, field_onset, ibeg)    
                        end
                        setfield!(cylce, field_end, ibeg)
                    end
                    GuiMod.vector_of_structs_to_struct_vector(state)
                end
                CImGui.SameLine()
                if CImGui.Button("del $(boundary)")
                    field_onset = Symbol("$(boundary)_onset")
                    field_end = Symbol("$(boundary)_end")
                    if !isnothing(getfield(cylce, field_end))
                        if hasproperty(cylce, field_onset)
                            setfield!(cylce, field_onset, nothing)    
                        end
                        setfield!(cylce, field_end, nothing)
                    end
                    GuiMod.vector_of_structs_to_struct_vector(state)
                end
            end
            CImGui.EndPopup()
        end
    end
end

function ParamsTable(state::GuiMod.PlotState)
    if CImGui.Begin("Параметры")
        show_parameters("#algRes", state.result.complexes, true)
        CImGui.End()
    end
end

function ShiftsTable(state::GuiMod.PlotState)
    if CImGui.Begin("Смещения")
        show_shifts([:ST20,:ST40,:ST60,:ST80], state.result.complexes, true)
        CImGui.End()
    end
end

function AmpTable(state::GuiMod.PlotState)
    if CImGui.Begin("Амплитуды")
        show_shifts([:P_amp,:Q_amp,:R_amp,:S_amp,:T_amp], state.result.complexes, true)
        CImGui.End()
    end
end

function ChunkParamsTable(state::GuiMod.PlotState)
    if CImGui.Begin("ChunkParams")
        show_chunk_params(state.result.chunk_params)
    end
end

function RepresentatieveComplexParamsTable(state::GuiMod.PlotState, complexInd :: Union{Int, Nothing})
    
    if CImGui.Begin("Параметры комплекса")

        if !isnothing(complexInd)
            complex = state.result.complexes[complexInd]
            show_parameters("#SingleParamTable", [complex], false)
            CImGui.Text("Смещения:")
            show_shifts([:ST20,:ST40,:ST60,:ST80], [complex], false)
            CImGui.Text("Амплитуды:")
            show_shifts([:P_amp,:Q_amp,:R_amp,:S_amp,:T_amp], [complex], false)
        end

        CImGui.End()
    end
end

function show_gui()
    Renderer.render(
        ui,
        width = 1360,
        height = 780,
        title = "",
        hotloading = true
    )
    return nothing
end

show_gui()