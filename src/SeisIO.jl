VERSION >= v"0.5.0" && __precompile__(true)
module SeisIO

export SeisChannel, SeisData, findname, findid, hasid, hasname,# Types/SeisData.jl
SeisHdr, SeisEvent,                                            # Types/SeisHdr.jl
wseis,                                                         # Types/write.jl
rseis,                                                         # Types/read.jl
parsemseed, readmseed, parsesl, readmseed, parserec,           # Formats/mSEED.jl
rlennasc,                                                      # Formats/LennartzAsc.jl
get_sac_keys, prunesac!, chksac, sachdr, sactoseis,            # Formats/SAC.jl
psac, rsac, readsac, wsac, writesac,                           #
readsegy, segyhdr, pruneseg, segytosac, segytoseis, r_segy,    # Formats/SEGY.jl
readuwpf, readuwdf, readuw, uwtoseis, r_uw,                    # Formats/UW.jl
readwin32, win32toseis, r_win32,                               # Formats/Win32.jl
batch_read,                                                    # Formats/BatchProc.jl
FDSNget,                                                       # Web/FDSN.jl
IRISget, irisws,                                               # Web/IRIS.jl
SeedLink, SeedLink!, has_sta, SLinfo,                          # Web/SeedLink.jl
GetSta, chparse,                                               # Web/WebMisc.jl
evq, gcdist, distaz!, getpha, getevt,                          # Utils/event_utils.jl
pull, getbandcode, prune!, purge, purge!, chan_sort, note,     # Utils/misc.jl
gapfill, ungap!, ungap, sync!, sync, gapfill!,                 # Utils/sync.jl
randseischa, randseisdata, randseisevent, randseishdr,         # Utils/randseis.jl
fctopz,                                                        # Utils/resp.jl
parsetimewin, j2md, md2j, sac2epoch, u2d, d2u, tzcorr,         # Utils/time_aux.jl
t_expand, xtmerge, xtjoin!

# SeisData is designed as a universal, gap-tolerant "working" format for
# geophysical timeseries data
include("Types/SeisData.jl")      # SeisData, SeisChan classes for channel data
include("Types/SeisHdr.jl")       # Headers for discrete events (SeisHdr)
include("Types/composite.jl")     # Composite types (SeisEvent)
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
include("Utils/event_utils.jl")   # Event utilities

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
include("Web/WebMisc.jl")         # Common functions for web data access

# Submodule SeisPol
module Polarization
export seispol, polhist, gauss, gdm, chi2d, qchd, seispol!
include("Submodules/Histograms.jl")
include("Submodules/Polarization.jl")
end

module Preprocessing
export autotap!, autotuk
include("Submodules/Preprocessing.jl")
end

end
