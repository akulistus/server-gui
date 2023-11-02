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

    function HeaderInfo(filename::String = "0", timestart::String = "0",
        length::Int = 0, freq::Float64 = 0.0, channels::Vector{String} = ["0"],)
        new(filename, timestart, length, freq, channels, nothing, nothing, nothing)
    end
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
    Q_onset::Vector{Int64}
    Q_end::Vector{Int64}
    R_onset::Vector{Int64}
    R_end::Vector{Int64}
    S_onset::Vector{Int64}
    S_end::Vector{Int64}
end

mutable struct GlobalBounds{T <: Union{Int64, Nothing}}
    P_onset::T
    P_end::T
    QRS_onset::T
    QRS_end::T
    T_end::T
end

mutable struct ChannelParams
    ST40 :: Vector{Int}
    ST80 :: Vector{Int}
    S_amp :: Vector{Int}
    name :: Vector{String}
    P_amp :: Vector{Int}
    Q_dur :: Vector{Int}
    T_amp :: Vector{Int}
    R_amp :: Vector{Int}
    Q_amp :: Vector{Int}
    ST20 :: Vector{Int}
    ST60 :: Vector{Int}
    R_dur :: Vector{Int}
    S_dur :: Vector{Int}
end

mutable struct GlobalParams
    P_dur :: Int
    PQ_dur :: Int
    QRS_dur :: Int
    QT_dur :: Int

    QT_type :: String
    QTc_Framingham :: Int
    QTc_MortaraVeritas :: Int
    QTc_Bazett :: Int
    QTc_Fridericia :: Int
    QTc_Hodges :: Int
    
    lead_depression :: String
    max_depression :: Int
    lead_elevation :: String
    max_elevatoin :: Int
    
    RR :: Int
    P_angle :: Int
    T_angle :: Int
    QRS_angle :: Int
    trance_zone :: String
    SokolowLyon_ind :: Int
end

mutable struct Complexes
    params :: GlobalBounds
    bounds :: GlobalParams
    channel_bounds :: ChannelBounds
    channel_params :: ChannelParams
end

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