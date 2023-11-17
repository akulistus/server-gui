module GuiMod
import StructTypes, JSON3, Dates, HTTP, ImPlot

    include("models.jl")
    include("Cursor.jl")
    include("HttpRequests.jl")
    include("plotState.jl")

    precompile(HTTP.get, (String,))

end # module GuiMod
