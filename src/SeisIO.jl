module SeisIO
using Blosc, DSP, LightXML, Requests.get
__precompile__(true)
path = Base.source_dir()
const datafields = [:id, :name, :loc, :fs, :gain, :resp, :units, :src, :notes, :misc, :t, :x]
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]

export SeisChannel, SeisData, SeisEvent, SeisHdr,             # Data Types
wseis, wseism,                                                # Types/write.jl
rseis, rseism,                                                # Types/read.jl
mseis!,                                                       # Types/merge.jl
ungap, ungap!, sync, sync!,                                   # Types/sync.jl
batch_read,                                                   # Formats/batch_read.jl
readmseed, seeddef,                                           # Formats/mSEED.jl
rlennasc,                                                     # Formats/LennartzAsc.jl
readsac, rsac, sachdr, writesac, wsac,                        # Formats/SAC.jl
readsegy, segyhdr,                                            # Formats/SEGY.jl
readuw, uwdf, uwpf, uwpf!,                                    # Formats/UW.jl
readwin32,                                                    # Formats/Win32.jl
findid, note!, pull,                                          # Types/SeisData.jl
FDSNevq, FDSNevt, FDSNget, FDSNsta,                           # Web/FDSN.jl
IRISget, irisws,                                              # Web/IRIS.jl
SeedLink, SeedLink!, SL_info, has_sta, has_live_stream,       # Web/SeedLink.jl
chanspec, webhdr,                                             # Web/WebMisc.jl
gcdist, getbandcode, lcfs,                                    # Utils/
fctopz, translate_resp, equalize_resp!,                       # Utils/resp.jl
d2u, j2md, md2j, parsetimewin, timestamp, u2d,                # CoreUtils/time.jl
t_win, w_time,
ls,                                                           # CoreUtils/ls.jl
distaz!,                                                      # Misc/event_misc.jl
autotap!, namestrip!, purge!, unscale!, demean!,              # Misc/processing.jl
env, env!,                                                    # Misc/env.jl
del_sta!,                                                     # Misc/del_sta.jl
randseischannel, randseisdata, randseisevent, randseishdr     # Misc/randseis.jl

# Everything depends on these
include("CoreUtils/ls.jl")
include("CoreUtils/time.jl")

# Utilities that don't require SeisIO types to work
for i in readdir(path*"/Utils")
  include(joinpath("Utils",i))
end

# Types and core type functionality
include("Types/SEED.jl")
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")
include("Types/SeisHdr.jl")
include("Types/SeisEvent.jl")
include("Types/merge.jl")
include("Types/read.jl")
include("Types/show.jl")
include("Types/sync.jl")
include("Types/write.jl")

# Miscellaneous SeisIO-dependent functions
for i in readdir(path*"/Misc")
  include(joinpath("Misc",i))
end

# Data formats
for i in readdir(path*"/Formats")
  if endswith(i, ".jl")
    include(joinpath("Formats",i))
  end
end

# Web clients
include("Web/parse_chstr.jl")
include("Web/WebMisc.jl")         # Common functions for web data access

include("Web/FDSN.jl")
include("Web/IRIS.jl")            # IRISws command line client
include("Web/SeedLink.jl")
end
