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
        length::Int = 0, freq::Float64 = 0.0, channels::Vector{String} = ["0"],
        monitorNumber::Union{Int, Nothing} = 1, monitorType::Union{Int, Nothing} = 1, stimuls::Union{String, Nothing} = "1")
        new(filename, timestart, length, freq, channels, monitorNumber, monitorType, stimuls)
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
    Q_onset::Vector{Union{Int, Nothing}}
    Q_end::Vector{Union{Int, Nothing}}
    R1_onset::Vector{Union{Int, Nothing}}
    R1_end::Vector{Union{Int, Nothing}}
    R2_onset::Vector{Union{Int, Nothing}}
    R2_end::Vector{Union{Int, Nothing}}
    S_onset::Vector{Union{Int, Nothing}}
    S_end::Vector{Union{Int, Nothing}}

    function ChannelBounds(Q_onset::Vector{Union{Int, Nothing}} = [1, nothing], Q_end::Vector{Union{Int, Nothing}} = [1, nothing],
        R1_onset::Vector{Union{Int, Nothing}} = [1, nothing], R1_end::Vector{Union{Int, Nothing}} = [1, nothing],
        R2_onset::Vector{Union{Int, Nothing}} = [1, nothing], R2_end::Vector{Union{Int, Nothing}} = [1, nothing],
        S_onset::Vector{Union{Int, Nothing}} = [1, nothing], S_end::Vector{Union{Int, Nothing}} = [1, nothing])
        new(Q_onset, Q_end, R1_onset, R1_end, R2_onset, R2_end, S_onset, S_end)
    end
end

mutable struct GlobalBounds
    P_onset :: Union{Int64, Nothing}
    P_end :: Union{Int64, Nothing}
    QRS_onset :: Union{Int64, Nothing}
    QRS_end :: Union{Int64, Nothing}
    T_end :: Union{Int64, Nothing}

    function GlobalBounds(P_onset::Union{Int64, Nothing} = 100, P_end::Union{Int64, Nothing} = 1,
        QRS_onset::Union{Int64, Nothing} = 1, QRS_end::Union{Int64, Nothing} = 1,
        T_end::Union{Int64, Nothing} = 200)
        new(P_onset, P_end, QRS_onset, QRS_end, T_end)
    end
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

    function ChannelParams(P_amp::Vector{Union{Int, Nothing}} = [1, nothing], Q_amp::Vector{Union{Int, Nothing}} = [1, nothing],
        R_amp::Vector{Union{Int, Nothing}} = [1, nothing], S_amp::Vector{Union{Int, Nothing}} = [1, nothing], 
        T_amp::Vector{Union{Int, Nothing}} = [1, nothing], ST20::Vector{Union{Int, Nothing}} = [1, nothing],
        ST40::Vector{Union{Int, Nothing}} = [1, nothing], ST60::Vector{Union{Int, Nothing}} = [1, nothing], 
        ST80::Vector{Union{Int, Nothing}} = [1, nothing], Q_dur::Vector{Union{Int, Nothing}} = [1, nothing], 
        R_dur::Vector{Union{Int, Nothing}} = [1, nothing], S_dur::Vector{Union{Int, Nothing}} = [1, nothing], 
        name::Vector{Union{String, Nothing}} = ["1", nothing])
        new(P_amp, Q_amp, R_amp, S_amp, T_amp,
        ST20, ST40, ST60, ST80, Q_dur, R_dur, S_dur, name)
        
    end
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

    function GlobalParams(P_dur::Union{Int, Nothing} = 1, PQ_dur::Union{Int, Nothing} = 1, QRS_dur::Union{Int, Nothing} = 1, QT_dur::Union{Int, Nothing} = 1,
        RR::Union{Int, Nothing} = 1, P_angle::Union{Int, Nothing} = 1, QRS_angle::Union{Int, Nothing} = 1, T_angle::Union{Int, Nothing} = 1, trans_zone::Union{String, Nothing} = "1",
        QTc_Fridericia::Union{Int, Nothing} = 1, QTc_Bazett::Union{Int, Nothing} = 1, QTc_Hodges::Union{Int, Nothing} = 1, QTc_Framingham::Union{Int, Nothing} = 1, QTc_MortaraVeritas::Union{Int, Nothing} = 1,
        SokolowLyon_ind::Union{Int, Nothing} = 1,
        max_depression::Union{Int, Nothing} = 1, lead_depression::Union{String, Nothing} = "1", max_elevation::Union{Int, Nothing} = 1, lead_elevation::Union{String, Nothing} = "1"
        )
        new(P_dur, PQ_dur, QRS_dur, QT_dur,
        RR, P_angle, QRS_angle, T_angle, trans_zone,
        QTc_Fridericia, QTc_Bazett, QTc_Hodges, QTc_Framingham, QTc_MortaraVeritas,
        SokolowLyon_ind,
        max_depression, lead_depression, max_elevation, lead_elevation)
    end
    
end

mutable struct Complexes
    params :: GlobalParams
    bounds :: GlobalBounds 
    channel_bounds :: ChannelBounds
    channel_params :: ChannelParams
end

StructTypes.names(::Type{Complexes}) = (
    (:bounds, :bounds),
    (:params, :params),
    (:channel_bounds, :channel_bounds),
    (:channel_params, :channel_params)
)
StructTypes.StructTypes(::Type{Complexes}) = StructTypes.Mutable()

mutable struct ChunkParams
    HR :: Union{Int,Nothing}
    QTcFormula :: String
    RRmean :: Union{Int,Nothing}
    RRmax :: Union{Int,Nothing}
    RRmin :: Union{Int,Nothing}

    function ChunkParams(HR::Union{Int,Nothing} = 1, QTcFormula :: String = "1",
        RRmean::Union{Int,Nothing} = 1, RRmax::Union{Int,Nothing} = 1,
        RRmin::Union{Int,Nothing} = 1)
        new(HR, strip(QTcFormula,['\n']), RRmean, RRmax, RRmin)
        
    end
end
StructTypes.StructTypes(::Type{ChunkParams}) = StructTypes.Mutable()

mutable struct Result
    settings :: Settings
    complexes :: Vector{Complexes}
    representative :: Int
    info :: HeaderInfo
    chunk_params :: ChunkParams
    spikes :: Vector{Int}
end
StructTypes.StructTypes(::Type{Result}) = StructTypes.Mutable()

mutable struct Preview
    params :: GlobalParams
    chunk_params :: ChunkParams
end

StructTypes.StructTypes(::Type{Preview}) = StructTypes.Mutable()