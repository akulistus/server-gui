module GuiMod
    import StructTypes, JSON3, Dates, HTTP, ImPlot

    const USER = "tmp"
    const FILTERS = "isoline,50Hz"
    const PORT = "8089"
    const HOST = "0.0.0.0"
    const CHANNELS = "I,II,III,aVR,aVL,aVF,V1,V2,V3,V4,V5,V6"
    # path to directory that contains all the db's
    const PATH = "C:/Users/8cara/OneDrive/Documents/Projects/Server/data/"

    include("models.jl")
    include("Cursor.jl")
    include("HttpRequests.jl")
    include("plotState.jl")

end # module GuiMod
