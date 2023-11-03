using StructTypes

mutable struct HeaderInfo
    filename :: String
    timestart :: String
    length :: Int
    freq :: Float64
    channels :: Vector{String}
    monitorNumber :: Union{Int, Nothing}
    monitorType :: Union{Int, Nothing}
    stimuls :: Union{String, Nothing}

    # function HeaderInfo(filename::String = "0", timestart::String = "0",
    #     length::Int = 0, freq::Float64 = 0.0, channels::Vector{String} = ["0"],)
    #     new(filename, timestart, length, freq, channels, nothing, nothing, nothing)
    # end
end
JSON3.StructTypes(::Type{HeaderInfo}) = JSON3.Mutable()

mutable struct Settings
    QRSsensitivity :: Float64
    isspikes :: Bool

    function Settings(QRSsensitivity::Float64 = 0.5, isspikes::Bool =false)
        new(QRSsensitivity, isspikes)
    end
end
StructTypes.StructTypes(::Type{Settings}) = StructTypes.Struct()

mutable struct ChannelBounds
    Q_onset::Vector{Union{Int, Nothing}}
    Q_end::Vector{Union{Int, Nothing}}
    R1_onset::Vector{Union{Int, Nothing}}
    R1_end::Vector{Union{Int, Nothing}}
    R2_onset::Vector{Union{Int, Nothing}}
    R2_end::Vector{Union{Int, Nothing}}
    S_onset::Vector{Union{Int, Nothing}}
    S_end::Vector{Union{Int, Nothing}}
end

mutable struct GlobalBounds
    P_onset :: Union{Int64, Nothing}
    P_end :: Union{Int64, Nothing}
    QRS_onset :: Union{Int64, Nothing}
    QRS_end :: Union{Int64, Nothing}
    T_end :: Union{Int64, Nothing}
end

mutable struct ChannelParams
    P_amp :: Vector{Union{Int, Nothing}}
    Q_amp :: Vector{Union{Int, Nothing}}
    R_amp :: Vector{Union{Int, Nothing}}
    S_amp :: Vector{Union{Int, Nothing}}
    T_amp :: Vector{Union{Int, Nothing}}

    ST20 :: Vector{Union{Int, Nothing}}
    ST40 :: Vector{Union{Int, Nothing}}
    ST60 :: Vector{Union{Int, Nothing}}
    ST80 :: Vector{Union{Int, Nothing}}

    Q_dur :: Vector{Union{Int, Nothing}}
    R_dur :: Vector{Union{Int, Nothing}}
    S_dur :: Vector{Union{Int, Nothing}}

    name :: Vector{Union{String, Nothing}}
end

mutable struct GlobalParams
    P_dur :: Union{Int, Nothing}
    PQ_dur :: Union{Int, Nothing}
    QRS_dur :: Union{Int, Nothing}
    QT_dur :: Union{Int, Nothing}

    RR :: Union{Int, Nothing}
    P_angle :: Union{Int, Nothing}
    QRS_angle :: Union{Int, Nothing}
    T_angle :: Union{Int, Nothing}
    trans_zone :: Union{String, Nothing}
    
    QTc_Fridericia :: Union{Int, Nothing}
    QTc_Bazett :: Union{Int, Nothing}
    QTc_Hodges :: Union{Int, Nothing}
    QTc_Framingham :: Union{Int, Nothing}
    QTc_MortaraVeritas :: Union{Int, Nothing}
    
    SokolowLyon_ind :: Union{Int, Nothing}

    max_depression :: Union{Int, Nothing}
    lead_depression :: Union{String, Nothing}
    max_elevation :: Union{Int, Nothing}
    lead_elevation :: Union{String, Nothing}
    
end

mutable struct Complexes
    params :: GlobalParams
    bounds :: GlobalBounds
    channel_bounds :: ChannelBounds
    channel_params :: ChannelParams
end

StructTypes.StructTypes(::Type{Complexes}) = StructTypes.Mutable()

mutable struct ChunkParams
    HR :: Int
    RRmean :: Int
    RRmax :: Int
    RRmin :: Int
end

mutable struct Result
    settings :: Settings
    complexes :: Vector{Complexes}
    representative :: Int
    info :: HeaderInfo
    chunk_params :: ChunkParams
    spikes :: Vector{Int}
end
StructTypes.StructTypes(::Type{Result}) = StructTypes.Mutable()