module SeisIO
using Blosc
using DSP
using LightXML
using Requests: get
VERSION >= v"0.5.0" && __precompile__(true)

const datafields = [:name, :id, :fs, :gain, :loc, :misc, :notes, :resp, :src, :units, :t, :x]
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]

export SeisChannel, SeisData, SeisEvent, SeisHdr,              # Data Types
batch_read,                                                    # Formats/batch_read.jl
readmseed,                                                     # Formats/mSEED.jl
rlennasc,                                                      # Formats/LennartzAsc.jl
readsac, rsac, sachdr, writesac, wsac,                         # Formats/SAC.jl
readsegy, segyhdr,                                             # Formats/SEGY.jl
readuw, uwdf, uwpf, uwpf!,                                     # Formats/UW.jl
readwin32,                                                     # Formats/Win32.jl
rseis,                                                         # Types/read.jl
ungap, ungap!, sync, sync!,                                    # Types/sync.jl
wseis,                                                         # Types/write.jl
findid, note!, pull,                                           # Types/SeisData.jl
FDSNevq, FDSNevt, FDSNget, FDSNsta,                            # Web/FDSN.jl
IRISget, irisws,                                               # Web/IRIS.jl
SeedLink, SeedLink!, SL_info, has_sta, has_live_stream,        # Web/SeedLink.jl
chanspec, webhdr,                                              # Web/WebMisc.jl
gcdist, getbandcode,                                           # Utils/
fctopz, translate_resp,                                        # Utils/resp.jl
d2u, j2md, md2j, parsetimewin, timestamp, u2d,                 # Utils/time.jl
distaz!,                                                       # Misc/event_misc.jl
autotap!, equalize_resp!, namestrip!,                          # Misc/processing.jl
pol_sort, purge!,
randseischannel, randseisdata, randseisevent, randseishdr      # Misc/randseis.jl

# Everything depends on time.jl
include("Utils/time.jl")

# Utilities that don't require SeisIO types to work
include("Utils/autotuk.jl")
include("Utils/bandcode.jl")
include("Utils/gcdist.jl")
include("Utils/lsw.jl")
include("Utils/gap.jl")
include("Utils/resp.jl")
include("Utils/tnote.jl")

# Types and core type functionality
include("Types/SeisData.jl")
include("Types/SeisChannel.jl")
include("Types/SeisHdr.jl")
include("Types/SeisEvent.jl")
include("Types/read.jl")
include("Types/show.jl")
include("Types/sync.jl")
include("Types/write.jl")

# Miscellaneous SeisIO-dependent functions
include("Misc/event_misc.jl")
include("Misc/processing.jl")
include("Misc/randseis.jl")

# Data formats
include("Formats/batch_read.jl")
include("Formats/mSEED.jl")
include("Formats/LennartzAsc.jl")
include("Formats/SAC.jl")
include("Formats/SEGY.jl")
include("Formats/UW.jl")
include("Formats/Win32.jl")

# Web clients
include("Web/parse_chstr.jl")
include("Web/WebMisc.jl")         # Common functions for web data access

include("Web/FDSN.jl")
include("Web/IRIS.jl")            # IRISws command line client
include("Web/SeedLink.jl")
# include("Web/SLConfig.jl")

module Polarization
export seispol, polhist, seispol!, seis_orient!
include("Submodules/Histograms.jl")
include("Submodules/Polarization.jl")
end

module Histograms
export whist, chi2d, gdm, qchd, gauss
include("Submodules/Histograms.jl")
end
end
