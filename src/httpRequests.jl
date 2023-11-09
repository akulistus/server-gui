import HTTP, JSON3
using StructTypes
include("models.jl")

const USER = "tmp"
const FILTERS = "isoline,50Hz"
const PORT = "8089"
const HOST = "0.0.0.0"
const CHANNELS = "I,II,III,aVR,aVL,aVF,V1,V2,V3,V4,V5,V6"
# path to directory that contains all the db's
const PATH = "C:/Users/8cara/OneDrive/Documents/Projects/Server/data/"


function get_db_list()
    COMMAND = "directories"
    r = HTTP.get("http://$HOST:$PORT/$COMMAND")
    str = String(r.body)
    return JSON3.read(str,Vector{String})
end

function select_db(DIRECTORY::String)
    COMMAND = "directory"
    HTTP.post("http://$HOST:$PORT/$USER/$COMMAND"; body = join([PATH, DIRECTORY]))
end

function get_record_list()
    COMMAND = "records"
    r = HTTP.get("http://$HOST:$PORT/$USER/$COMMAND")
    str = String(r.body)
    return JSON3.read(str, Vector{HeaderInfo})
end

function get_signal(record_name::String, from::Int, to::Int, filter::String = FILTERS, channel::String = CHANNELS)
    query = Dict([("from", from), ("to", to), ("filter", filter), ("channel", channel)])
    r = HTTP.get("http://$(HOST):$(PORT)/$USER/records/$record_name/signals"; query = query)
    str = String(r.body)
    ecg_file = JSON3.read(str,Vector{Vector{Float64}})
    return ecg_file
end

function get_result(record_name :: String)
    r = HTTP.get("http://$(HOST):$(PORT)/$USER/records/$record_name/result")
    str = String(r.body)
    return JSON3.read(str, GuiMod.Result)
end

function get_record_info(record_name::String)
    r = HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/info")
    str = String(r.body)
    return JSON3.read(str,HeaderInfo)
end

function post_complex(record_name::String, complex::GlobalBounds)
    json_complex = JSON3.write(complex)
    r = HTTP.post("http://$(HOST):$(PORT)/$USER/records/$record_name/complexes", [("Content-Type" => "application/json")], json_complex, verbose=3)
end

function get_complexes(record_name)
    r =  HTTP.get("http://$(HOST):$(PORT)/$USER/records/$record_name/complexes")
    str = String(r.body)
    return JSON3.read(str, Vector{Complexes})
end

function change_settings(record_name::String, settings::Settings)
    json_settings = JSON3.write(settings)
    HTTP.post("http://$(HOST):$(PORT)/$USER/records/$record_name/settings", [("Content-Type" => "application/json")], json_settings, verbose=3)
end

function get_settings(record_name::String)
    r = HTTP.get("http://$(HOST):$(PORT)/$USER/records/$record_name/settings")
    return JSON3.read(r.body, Settings)
end

function get_representative(record_name::String)
    r = HTTP.get("http://$(HOST):$(PORT)/$USER/records/$record_name/representative")
    return JSON3.read(r.body, Int)
end