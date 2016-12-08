VERSION >= v"0.5.0" && __precompile__(true)
module SeisIO

export SeisChannel, SeisData, findname, findid, hasid, hasname,# Types/SeisData.jl
SeisHdr,                                                       # Types/SeisHdr.jl
SeisEvent,                                                     # Types/SeisEvent.jl
wseis,                                                         # Types/write.jl
rseis,                                                         # Types/read.jl
parsemseed, readmseed, parsesl, readmseed, parserec,           # Formats/mSEED.jl
rlennasc,                                                      # Formats/LennartzAsc.jl
prunesac!, chksac, sachdr, sactoseis, get_sac_keys, parse_sac, # Formats/SAC.jl
rsac, readsac, wsac, writesac,                                 #
readsegy, segyhdr,                                             # Formats/SEGY.jl
readuw, uwdf, uwpf, uwpf!,                                     # Formats/UW.jl
readwin32, win32toseis, r_win32,                               # Formats/Win32.jl
batch_read,                                                    # Formats/BatchProc.jl
FDSNget,                                                       # Web/FDSN.jl
IRISget, irisws,                                               # Web/IRIS.jl
SeedLink, SeedLink!, has_sta, SLinfo,                          # Web/SeedLink.jl
SL_parse, min_req,                                             # Web/SL_parse.jl
get_sta,                                                       # Web/WebMisc.jl
pull, getbandcode, prune!, purge, purge!, chan_sort, note,     # Utils/misc.jl
autotap!, autotuk,                                             # Utils/processing.jl
gapfill, ungap!, ungap, sync!, sync, gapfill!,                 # Utils/sync.jl
randseischa, randseisdata, randseisevent, randseishdr,         # Utils/randseis.jl
fctopz, translate_resp, equalize_resp!,                        # Utils/resp.jl
parsetimewin, j2md, md2j, sac2epoch, u2d, d2u, tzcorr,         # Utils/time_aux.jl
t_expand, xtmerge, xtjoin!

# SeisData is designed as a universal, gap-tolerant "working" format for
# geophysical timeseries data
include("Types/SeisData.jl")      # SeisData, SeisChan classes for channel data
include("Types/SeisHdr.jl")       # Dataless headers for events (SeisHdr)
include("Types/SeisEvent.jl")     # Event header with data
include("Types/read.jl")          # Read
include("Types/write.jl")         # Write
include("Types/show.jl")          # Display

# Auxiliary time and file functions
include("Utils/randseis.jl")      # Create random SeisData for testing purposes
include("Utils/misc.jl")          # Utilities that don't fit elsewhere
include("Utils/time_aux.jl")      # Time functions
include("Utils/file_aux.jl")      # File functions
include("Utils/resp.jl")          # Instrument responses
include("Utils/sync.jl")          # Synchronization
include("Utils/processing.jl")    # Very basic processing

# Data converters
include("Formats/SAC.jl")         # IRIS/USGS standard
include("Formats/SEGY.jl")        # Society for Exploration Geophysicists
include("Formats/mSEED.jl")       # Monolithic, but a worldwide standard
include("Formats/UW.jl")          # University of Washington
include("Formats/Win32.jl")       # NIED (Japan)
include("Formats/LennartzAsc.jl") # Lennartz ASCII (mostly a readdlm wrapper)
include("Formats/BatchProc.jl")   # Batch read

# Web clients
include("Web/IRIS.jl")            # IRISws command line client
include("Web/FDSN.jl")
include("Web/SeedLink.jl")
include("Web/SL_parse.jl")
include("Web/WebMisc.jl")         # Common functions for web data access

# Submodule SeisPol
module Events
export evq, distaz!, get_pha, get_evt, get_sta
include("Submodules/Events.jl")
end

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
