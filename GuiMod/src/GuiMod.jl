module GuiMod
    # using PrecompileTools
    import StructTypes, JSON3, Dates, HTTP, ImPlot
    import Base.EnvDict

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

    # @setup_workload begin
    #     @compile_workload begin
    #         HTTP.get("http://0.0.0.0:8089/directories")
    #         GuiMod.select_db("test_db")
    #         GuiMod.get_record_list()
    #         GuiMod.get_record_info("MO1_001")
    #         GuiMod.get_signal("MO1_001", 500, 1000, "isoline", "V1")
    #         GuiMod.get_result("MO1_001")
    #     end
    # end

end # module GuiMod
