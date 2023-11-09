import HTTP, JSON3, StructTypes, Dates
using CImGui
using ImPlot
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using Base.Iterators: partition

include("src/Renderer.jl")
include("src/GuiMod.jl")
using .Renderer
using .GuiMod

# using Pkg
# Pkg.add(name="ImPlot", rev="main")
# Pkg.add(name="LibCImGui", version="1.82.2")

tableParser = JSON3.read("src/tableHeader.json", Dict)

ecgChannelsNames = ["I", "II", "III", "aVR", "aVL", "aVF", "V1", "V2", "V3", "V4", "V5", "V6"]

tableFlags = CImGui.ImGuiTableFlags_SizingStretchSame | 
            CImGui.ImGuiTableFlags_Resizable | 
            CImGui.ImGuiTableFlags_ContextMenuInBody | 
            CImGui.ImGuiTableFlags_Borders | 
            CImGui.ImGuiTableFlags_RowBg | 
            CImGui.ImGuiTableFlags_NoHostExtendX |
            CImGui.ImGuiTableFlags_SizingFixedFit

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
    "ActiveMark" => [""],
    "ActiveComplexInd" => 1,
    "ActiveChannel" => [""],
    "ActiveCursor" =>[""],
    "ActiveFilters" => [false, false, false],
    "Record" => [""],
    "ActiveSettings" => GuiMod.Settings(),
    "Cursor" => GuiMod.Cursor(100,100),
    "flag" => CImGui.ImGuiCond_Once
)

try
    USERDATA["AvailableDataBases"] = GuiMod.get_db_list()
catch
end

# хранилище, привязанное к ID виджетов
const STORAGE = Dict{UInt32, Any}()
get_uistate(key::String, default = nothing) = get(STORAGE, CImGui.GetID(key), default)
set_uistate(key::String, value) = STORAGE[CImGui.GetID(key)] = value

function find_chosen_complex(state :: GuiMod.PlotState, cursor::GuiMod.Cursor)
    for i in eachindex(state.processRes.complexes)
        ibeg = get_ibeg_or_iend(state.processRes.complexes[i].bounds, true)
        iend = get_ibeg_or_iend(state.processRes.complexes[i].bounds, false)
        if !isdisjoint(cursor.leftBorder:cursor.rightBorder, ibeg:iend)
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
            if selected_db_name != "None"
                GuiMod.select_db(selected_db_name)
                USERDATA["AvailableRecords"] = GuiMod.get_record_list()
            end
        
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
            USERDATA["ActiveSettings"] = [false, false]
            state.signal = GuiMod.get_signal(record, 1, 5000)
            state.processRes = GuiMod.get_result(record)
            state.recordInfo = GuiMod.get_record_info(record)
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
        
        if CImGui.Selectable("$complex_ind"*repeat("\n", num_of_strs_in_one_col), complex_ind == USERDATA["ActiveComplexInd"], CImGui.ImGuiSelectableFlags_SpanAllColumns)
            USERDATA["ActiveComplexInd"] = complex_ind
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

    CImGui.Columns(13,"#shifts")
    CImGui.Separator()
    headers = ecgChannelsNames
    for header in ["Параметры"; headers]
        CImGui.Text("$header"); CImGui.NextColumn()
    end
    CImGui.Separator()


    for complexInd in eachindex(complexes)
        s = ""

        for item in propertys
            s *= "$(String(item))\n"
        end
        if CImGui.Selectable("$s#$complexInd", complexInd == USERDATA["ActiveComplexInd"], CImGui.ImGuiSelectableFlags_SpanAllColumns)
            USERDATA["ActiveComplexInd"] = complexInd
        end
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
                
                show_stats("BaseStats", state.recordInfo)

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

    RepresentatieveComplexParamsTable(state, USERDATA["ActiveComplexInd"])
end

function Viewer(state::GuiMod.PlotState)

    if CImGui.Begin("Просмотр")

        ecg = state.signal
        flag = USERDATA["flag"]
        cursor = USERDATA["Cursor"]
        counter = 1

        CImGui.Text("Настройки:")
        @cstatic( 
            offset = Cfloat(USERDATA["ActiveSettings"].QRSsensitivity),
            spikes = USERDATA["ActiveSettings"].isspikes,
            isoline = USERDATA["ActiveFilters"][1],
            fiftyHz = USERDATA["ActiveFilters"][2],
            thirtyfiveHz = USERDATA["ActiveFilters"][3],
            begin
            if @c CImGui.SliderFloat("Настройка чувствительности",&offset, 0, 1)
                USERDATA["ActiveSettings"].QRSsensitivity = offset
            end
            CImGui.SameLine()
            @c CImGui.Checkbox("IsSpikes", &spikes)
            CImGui.Text("Выбор фильтра:")
            @c CImGui.Checkbox("isoline", &isoline)
            @c CImGui.Checkbox("50Hz", &fiftyHz)
            @c CImGui.Checkbox("35Hz", &thirtyfiveHz)

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
                
                if !isequal(USERDATA["Record"], [""]) && !isequal(USERDATA["ActiveSettings"], [""])
                    GuiMod.change_settings(USERDATA["Record"], USERDATA["ActiveSettings"])
                    state.signal = GuiMod.get_signal(USERDATA["Record"], 1, 5000, join(filters, ","))
                    state.processRes.complexes = GuiMod.get_complexes(USERDATA["Record"])
                end

            end
            USERDATA["ActiveFilters"] = [isoline, fiftyHz]
        end)
    
        if ImPlot.BeginPlot("Навигационный график","x","y",CImGui.ImVec2(-1,-1))
            
                k = 0
                for ch in ecg
                    ImPlot.PlotLine(Float64.(ch.-k))
                    ImPlot.PlotText("$(ecgChannelsNames[counter])", 10, -k)
                    counter += 1
                    k += 2000
                end

                #Somehow need to fix this.
                for name in propertynames(state.processRes.complexes[1].bounds)
                    bound = getfield(state, name)
                    if isa(bound, Nothing) || isa(bound, Vector{Nothing})
                        continue
                    end
                    ImPlot.PlotVLines("$name", trunc.(Int,bound), length(bound))
                end

                for index in eachindex(state.QRS_onset)
                    k = 0
                    for ch in eachindex(ecg)
                        # ImPlot.PlotText("$index", state.QRS_onset[index], -k)
                        k += 2000
                    end
                end

                ImPlot.PlotVLines("Cursor", Ref(cursor.pos), 1)

                if ImPlot.IsPlotHovered() && CImGui.IsMouseClicked(0)
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

        chosenComplexInd = USERDATA["ActiveComplexInd"]
        cursor = USERDATA["Cursor"]
        flag = USERDATA["flag"]
        lims = (xlim = state.xlim, ylim = state.ylim)
        ecg = state.signal

        CImGui.BeginGroup()
            ImPlot.SetNextPlotLimits(lims.xlim.min, lims.xlim.max, lims.ylim.min, lims.ylim.max, flag)
            if ImPlot.BeginPlot("Представительный комплекс","x","y",CImGui.ImVec2(-1,-CImGui.GetFrameHeightWithSpacing()))
               
                counter = 1
                
                if !isnothing(chosenComplexInd)

                    chBounds = state.processRes.complexes[chosenComplexInd].channel_bounds
                    
                    if chosenComplexInd == 1
                        ibeg = 1
                    else
                        ibeg = get_begin_end_marks(state.processRes.complexes[chosenComplexInd - 1].bounds,
                        state.processRes.complexes[chosenComplexInd].bounds, false)
                    end

                    if chosenComplexInd == length(state.processRes.complexes)
                        iend = lastindex(ecg[1])
                    else
                        iend = get_begin_end_marks(state.processRes.complexes[chosenComplexInd + 1].bounds, 
                        state.processRes.complexes[chosenComplexInd].bounds, true)
                    end


                    cycle = state.processRes.complexes[chosenComplexInd].bounds
                    fields = propertynames(cycle) 
                    
                    k = 0
                    for ch in ecg
                        ImPlot.PlotLine(Float64.(ch[ibeg:iend].-k))
                        ImPlot.PlotText("$(ecgChannelsNames[counter])", 10, -k)
                        counter += 1
                        k += 2000
                    end
                    

                    for field in fields
                        bound = getfield(cycle, field)
                        if isa(bound, Nothing)
                            continue
                        end
                        ImPlot.PlotVLines("$field", Ref(trunc.(Int,bound) .- (ibeg)), length(bound))
                    end

                    props = propertynames(chBounds)
                    for prop in props
                        field = getfield(chBounds,prop)
                        arrX = Vector{Int}()
                        arrY = Vector{Float64}()
                        k = 0
                        for ind in eachindex(field)
                            item = field[ind]
                            if isa(item, Nothing)
                                continue
                            end
                            append!(arrX, trunc(Int,item) - ibeg)
                            append!(arrY, ecg[ind][item] - k)
                            k += 2000
                        end
                        ImPlot.PlotScatter(arrX, arrY; label_id = String(prop))
                    end

                    if ImPlot.IsPlotHovered() && CImGui.IsMouseClicked(0)
                        USERDATA["flag"] = CImGui.ImGuiCond_Always
                        USERDATA["ActiveMark"] = GuiMod.find_mark(cycle, ibeg)
                    elseif ImPlot.IsPlotHovered() && CImGui.IsMouseDown(0)
                        USERDATA["flag"] = CImGui.ImGuiCond_Always
                        actMark = USERDATA["ActiveMark"]
                        GuiMod.move_mark(cycle, actMark, ibeg, lastindex(ecg[1]))
                        GuiMod.vector_of_structs_to_struct_vector(state)
                    else
                        USERDATA["flag"] = CImGui.ImGuiCond_Once
                    end

                else

                    ibeg = (cursor.leftBorder < 0) ? 1 : cursor.leftBorder
                    iend = (cursor.rightBorder > lastindex(ecg[1])) ? lastindex(ecg[1]) : cursor.rightBorder

                    k = 0
                    counter = 1
                    for ch in ecg
                        ImPlot.PlotLine(Float64.(ch[ibeg:iend].-k))
                        ImPlot.PlotText("$(ecgChannelsNames[counter])", 10, -k)
                        counter += 1
                        k += 2000
                    end
                end



                limits = ImPlot.GetPlotLimits()
                x1, x2 = limits.X.Min, limits.X.Max
                y1, y2 = limits.Y.Min, limits.Y.Max

                state.xlim = (min = x1, max = x2)
                state.ylim = (min = y1, max = y2)

                if ImPlot.IsPlotHovered() && CImGui.IsMouseDoubleClicked(0)
                    state.xlim = (min = 1, max = iend-ibeg)
                    state.ylim = (min = -12*2000, max = maximum(ecg[1])*1.2)
                end

                ImPlot.EndPlot()
            end

            if CImGui.Button("Применить изменения")
                if !isequal(USERDATA["Record"],[""])
                    GuiMod.post_complex(USERDATA["Record"], state.processRes.complexes[chosenComplexInd].bounds)
                    state.processRes.complexes = GuiMod.get_complexes(USERDATA["Record"])
                end
            end
        CImGui.EndGroup()

        CImGui.End()
    end
    
end

function ParamsTable(state::GuiMod.PlotState)
    if CImGui.Begin("Параметры")
        show_parameters("#algRes", state.processRes.complexes, true)
        CImGui.End()
    end
end

function ShiftsTable(state::GuiMod.PlotState)
    if CImGui.Begin("Смещения")
        show_shifts([:ST20,:ST40,:ST60,:ST80], state.processRes.complexes, true)
        CImGui.End()
    end
end

function AmpTable(state::GuiMod.PlotState)
    if CImGui.Begin("Амплитуды")
        show_shifts([:P_amp,:Q_amp,:R_amp,:S_amp,:T_amp], state.processRes.complexes, true)
        CImGui.End()
    end
end

function RepresentatieveComplexParamsTable(state::GuiMod.PlotState, complexInd :: Union{Int, Nothing})
    
    if CImGui.Begin("Параметры комплекса")
        
        if !isnothing(complexInd)
            complex = state.processRes.complexes[complexInd]
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