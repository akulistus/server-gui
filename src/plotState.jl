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
    fieldNames = propertynames(vector_of_structs[1].params)
    for name in fieldNames
        setfield!(state, name, [getfield(x.params, name) for x in vector_of_structs])
    end
end

function move_coursor()
    mousePosition = ImPlot.GetPlotMousePos()
    xpos = mousePosition.x

    cursor = trunc(Int, xpos)
end

function find_complex()
    
end


# function find_mark(cycle :: CardioCycle, delta :: Int)
#     mousePosition = ImPlot.GetPlotMousePos()
#     xpos = mousePosition.x

#     fieldNames = propertynames(cycle)

#     minInd = ([abs(getfield(cycle, x) -delta -xpos) for x in fieldNames] |> findmin)[2]
    
#     return minInd

# end

# function move_mark(cycle::CardioCycle, minInd::Int, delta :: Int, lastindex :: Int)
#     mousePosition = ImPlot.GetPlotMousePos()
#     xpos = mousePosition.x
#     fieldNames = propertynames(cycle)

#     if trunc(Int, xpos + delta) < 1
#         newPos = 1
#     elseif trunc(Int, xpos + delta) > lastindex
#         newPos = lastindex
#     else
#         newPos = trunc(Int, xpos + delta)
#     end

#     setfield!(cycle,fieldNames[minInd], newPos)
# end