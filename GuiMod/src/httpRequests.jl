function get_db_list()
    PATH = NativeFileDialog.pick_folder()
    return PATH
end

function select_db(DIRECTORY::String)
    HTTP.post("http://$HOST:$PORT/$USER/directory"; body = DIRECTORY)
end

function get_record_list()
    r = HTTP.get("http://$HOST:$PORT/$USER/records")
    str = String(r.body)
    return JSON3.read(str, Vector{HeaderInfo})
end

function get_signal(record_name::String, from::Int, to::Int, filter::String = FILTERS, channel::String = CHANNELS)
    if isempty(filter)
        query = Dict([("from", from), ("to", to), ("channel", channel)])
    else
        query = Dict([("from", from), ("to", to), ("filter", filter), ("channel", channel)])
    end
    r = HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/signals"; query = query)
    str = String(r.body)
    ecg_file = JSON3.read(str,Vector{Vector{Float64}})
    return ecg_file
end

function get_result(record_name :: String)
    r = HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/result")
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
    r = HTTP.post("http://$HOST:$PORT/$USER/records/$record_name/complexes", [("Content-Type" => "application/json")], json_complex, verbose=3)
end

function get_complexes(record_name)
    r =  HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/complexes")
    str = String(r.body)
    return JSON3.read(str, Vector{Complexes})
end

function change_settings(record_name::String, settings::Settings)
    json_settings = JSON3.write(settings)
    HTTP.post("http://$HOST:$PORT/$USER/records/$record_name/settings", [("Content-Type" => "application/json")], json_settings, verbose=3)
end

function get_settings(record_name::String)
    r = HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/settings")
    return JSON3.read(r.body, Settings)
end

function get_representative(record_name::String)
    r = HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/representative")
    return JSON3.read(r.body, Int)
end

function get_chunk_params(record_name::String, from::Int, to:: Int)
    query = Dict([("from", from), ("to", to)])
    r = HTTP.get("http://$HOST:$PORT/$USER/records/$record_name/chunk_params"; query = query)
    return JSON3.read(r.body, ChunkParams)
end

function get_params_preview(record_name::String, complex::GlobalBounds, representative::Int)
    json_complex = JSON3.write(complex)
    query = Dict([("from", 1), ("to", 500), ("representative", representative)])
    r = HTTP.post("http://$HOST:$PORT/$USER/records/$record_name/params_preview", [("Content-Type" => "application/json")], json_complex, verbose=3; query = query)
    return JSON3.read(r.body, Preview)
end