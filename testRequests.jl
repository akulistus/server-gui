@time using GuiMod
using ImPlot, HTTP, JSON3

const USER = "tmp"
const FILTERS = "isoline,50Hz"
const PORT = "8089"
const HOST = "0.0.0.0"
const CHANNELS = "I,II,III,aVR,aVL,aVF,V1,V2,V3,V4,V5,V6"
# path to directory that contains all the db's
const PATH = "C:/Users/8cara/OneDrive/Documents/Projects/Server/data/"
COMMAND = "directories"

@time r = GuiMod.HTTP.get("http://$HOST:$PORT/$COMMAND")
@time GuiMod.get_db_list()
@time GuiMod.select_db("test_db")
@time GuiMod.get_record_info("MO1_001")
@time GuiMod.get_record_list()
@time GuiMod.get_signal("MO1_001", 1, 4000, "isoline", "V1")
@time GuiMod.get_result("MO1_001")

GuiMod.change_settings("MO1_001", GuiMod.Settings(0.7, true))
print(GuiMod.get_settings("MO1_001"))
GuiMod.get_complexes("MO1_001")

