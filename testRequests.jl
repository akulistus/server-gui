# include("src/GuiMod.jl")
# using .GuiMod

# GuiMod.get_db_list()
# GuiMod.select_db("test_db")
# GuiMod.get_record_list()
# GuiMod.get_signal("MO1_001", 500, 1000, "isoline", "V1")
# GuiMod.get_result("MO1_001")


using CImGui
using ImPlot
include("src/Renderer.jl")
using .Renderer
function ui()
    if CImGui.Begin("Te")
        if ImPlot.BeginPlot("Test")
            ImPlot.PlotScatter([1,2,4,5], [10,12,4,2]; label_id = "name")
            ImPlot.PlotScatter([1,2,4,5], [11,14,5,4]; label_id = "guest")
        end
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