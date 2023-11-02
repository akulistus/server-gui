import HTTP, JSON3
using StructTypes
include("models.jl")

const user = "tmp"
const FILTERS = "isoline,50Hz"
const PORT = "8089"
# const HOST = "127.0.0.1"
const HOST = "0.0.0.0"


function get_db_list()
    COMMAND = "directories"
    r = HTTP.get("http://$HOST:$PORT/$COMMAND")
    str = String(r.body)
    return JSON3.read(str,Vector{String})
end

function select_db(DIRECTORY::String)
    COMMAND = "directory"
    HTTP.post("http://$HOST:$PORT/$user/$COMMAND"; body = "C:/Server/data/$DIRECTORY")
end

function get_record_list()
    COMMAND = "records"
    r = HTTP.get("http://$HOST:$PORT/$user/$COMMAND")
    str = String(r.body)
    print(str)
    return JSON3.read(str, Vector{HeaderInfo})
end

# function select_record(COMMAND::String)
#     r = HTTP.post("http://$HOST:$PORT/open_record/$COMMAND")
#     str = String(r.body)
#     return json_to_signal_info(str)
# end

function get_signal(RECORDNAME :: String, from::Int, to::Int, filter::String, channel::String)
    query = Dict([("from", from), ("to", to), ("filter", filter), ("channel", channel)])
    r = HTTP.get("http://$(HOST):$(PORT)/$user/records/$RECORDNAME/signals"; query = query)
    str = String(r.body)
    print(str)
    ecg_file = JSON3.read(str,Vector{Vector{Float64}})
    return ecg_file
end

function get_result(RECORDNAME :: String)
    r = HTTP.get("http://$(HOST):$(PORT)/$user/records/$RECORDNAME/result")
    str = String(r.body)
    return JSON3.read(str, GuiMod.Result)
end

# function get_record_info()
#     r = HTTP.get("http://$HOST:$PORT/record_info")
#     str = String(r.body)
#     return JSON3.read(str,Dict{String, Any})
# end

function process_ecg(recordName)
    r = HTTP.get("http://$HOST:$PORT/$user/records/$recordName/process_ecg")
    str = String(r.body)
    return json_to_parameters_vec(str)
end

function save_changes(cycle, recordName)
    json_to_shift = JSON3.write(cycle)
    HTTP.post("http://$(HOST):$(PORT)/$user/records/$recordName/complexes", [("Content-Type" => "application/json")], json_to_shift, verbose=3)
    r =  HTTP.get("http://$(HOST):$(PORT)/$user/records/$recordName/complexes")
end

function get_complexes(recordName)
    r =  HTTP.get("http://$(HOST):$(PORT)/$user/records/$recordName/complexes")
    str = String(r.body)
    return json_to_parameters_vec(str)
end

# function add_new_cycle(recordName::String, newCycle::CardioCycle)
#     json_cycle = JSON3.write(newCycle)
#     HTTP.post("http://$(HOST):$(PORT)/$user/records/$recordName/complexes", [("Content-Type" => "application/json")], json_cycle, verbose=3)
# end

function undo_changes(recordName)
    r = HTTP.post("http://$(HOST):$(PORT)/$user/records/$recordName/undo")
end

function redo_changes(recordName)
    r = HTTP.post("http://$(HOST):$(PORT)/$user/records/$recordName/redo")
end

function change_settings(recordName::String, settings::Settings)
    json_settings = JSON3.write(settings)
    HTTP.post("http://$(HOST):$(PORT)/$user/records/$recordName/settings", [("Content-Type" => "application/json")], json_settings, verbose=3)
end

function get_settings(recordName::String)
    r = HTTP.get("http://$(HOST):$(PORT)/$user/records/$recordName/settings")
    return JSON3.read(r.body, AlgorithmsSettings)
end