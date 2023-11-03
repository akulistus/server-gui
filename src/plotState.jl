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

function find_complex()
    
end


function find_mark(cycle :: GlobalBounds, delta :: Int)
    mousePosition = ImPlot.GetPlotMousePos()
    xpos = mousePosition.x

    field_names = propertynames(cycle)

    arr = []
    for name in field_names
        field = getfield(cycle, name)
        if !isa(field, Nothing)
            append!(arr, field - delta - xpos)
        end
    end
    
    if isempty(arr)
        return 1
    end

    return findmin(arr)[2]

end

function move_mark(cycle::GlobalBounds, minInd::Int, delta :: Int, lastindex :: Int)
    mousePosition = ImPlot.GetPlotMousePos()
    xpos = mousePosition.x
    fieldNames = propertynames(cycle)

    if trunc(Int, xpos + delta) < 1
        newPos = 1
    elseif trunc(Int, xpos + delta) > lastindex
        newPos = lastindex
    else
        newPos = trunc(Int, xpos + delta)
    end

    setfield!(cycle,fieldNames[minInd], newPos)
end