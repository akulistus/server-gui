mutable struct PlotState
    signal :: Vector
    numChn :: Int
    P_onset:: Any
    P_end:: Any
    QRS_onset::Any
    QRS_end::Any
    T_end::Any
    recordInfo :: HeaderInfo
    processRes :: Result
    xlim::NamedTuple{(:min, :max), NTuple{2, Float32}}
    ylim::NamedTuple{(:min, :max), NTuple{2, Float32}}
end

function vector_of_structs_to_struct_vector(state::PlotState)
    vector_of_structs = state.processRes.complexes
    field_names = propertynames(vector_of_structs[1].bounds)
    for name in field_names
        arr = []
        for complex in vector_of_structs
            field = getfield(complex.bounds, name)
            if !isa(field, Nothing)
                append!(arr, field)
            end
        end
        setfield!(state, name, arr)
    end
end

function move_coursor()
    mousePosition = ImPlot.GetPlotMousePos()
    xpos = mousePosition.x

    cursor = trunc(Int, xpos)
end


function find_mark(cycle :: GlobalBounds, delta :: Int)
    mousePosition = ImPlot.GetPlotMousePos()
    xpos = mousePosition.x

    field_names = propertynames(cycle)

    dict = Dict{Float64,Symbol}()
    for name in field_names
        field = getfield(cycle, name)
        if !isa(field, Nothing)
            dict[abs(field - delta - xpos)] = name
        end
    end
    
    if isempty(dict)
        return 1
    end

    key = findmin(collect(keys(dict)))[1]
    return dict[key]

end

function move_mark(cycle::GlobalBounds, field::Symbol, delta :: Int, lastindex :: Int)
    mousePosition = ImPlot.GetPlotMousePos()
    xpos = mousePosition.x

    if trunc(Int, xpos + delta) < 1
        newPos = 1
    elseif trunc(Int, xpos + delta) > lastindex
        newPos = lastindex
    else
        newPos = trunc(Int, xpos + delta)
    end

    setfield!(cycle, field, newPos)
end