VERSION >= v"0.4.0" && __precompile__(true)
module SeisIO
export SeisObj, SeisData, findname, findid, hasid, hasname,    # SeisData/SeisData.jl
samehdr, t_expand, t_collapse, pull, note,
wseis, rseis, writesac,                                        # SeisData/fileio.jl
getbandcode, prune!, purge, purge!, gapfill!,                  # SeisData/misc.jl
gapfill, ungap!, ungap, sync!, sync, autotap!,
randseisobj, randseisdata,                                     # SeisData/randseis.jl
batch_read,                                                    # FileFormats/BatchProc.jl
parsemseed, readmseed, parsesl, readmseed, parserec,           # FileFormats/mSEED.jl
rlennasc,                                                      # FileFormats/LennartzAsc.jl
prunesac!, psac, r_sac, sacwrite, chksac, sachdr,              # FileFormats/SAC.jl
get_sac_keys, get_sac_fw, get_sac_iw, sactoseis,
readsac, writesac, sac_bat,
readsegy, segyhdr, pruneseg, segytosac, segytoseis, r_segy,    # FileFormats/SEGY.jl
readuwpf, readuwdf, readuw, uwtoseis, r_uw,                    # FileFormats/UW.jl
readwin32, win32toseis, r_win32,                               # FileFormats/Win32.jl
FDSNget,                                                       # Web/FDSN.jl
IRISget, irisws,                                               # Web/IRIS.jl
SeedLink,                                                      # Web/SeedLink.jl
get_uhead, GetSta,                                             # Web/WebMisc.jl
evq, getPha, gcdist, distaz!, getP,                            # Utils/event_utils.jl
fctopz,                                                        # Utils/resp.jlr
parsetimewin, j2md, md2j, sac2epoch, u2d, d2u, tzcorr,         # Utils/time_aux.jl
xtmerge, xtjoin!,
SeisHdr, SeisEvent                                             # SeisEvent.jl

# SeisData is designed as a universal, gap-tolerant "working" format for
# geophysical timeseries data
include("SeisData/SeisData.jl")
include("SeisData/show.jl")
include("SeisData/fileio.jl")
include("SeisData/misc.jl")
include("SeisData/randseis.jl")
include("SeisEvent.jl")               # Classes for discrete events and event headers

# Auxiliary time and file functions
include("Utils/time_aux.jl")
include("Utils/file_aux.jl")
include("Utils/resp.jl")
include("Utils/event_utils.jl")

# Data converters
include("FileFormats/SAC.jl")         # SAC is the old IRIS standard; very easy to use, almost universally readable
include("FileFormats/SEGY.jl")        # SEG Y, standard of the Society for Exploration Geophysicists
include("FileFormats/mSEED.jl")       # SEED has become the worldwide seismic data standard despite being monolithic
include("FileFormats/UW.jl")          # University of Washington: used at UW 1970s through mid-2000s
include("FileFormats/Win32.jl")       # Win32: standard Japanese seismic data format
include("FileFormats/LennartzAsc.jl") # Lennartz ASCII: a cheap wrapper to readdlm
include("FileFormats/BatchProc.jl")   # SAC is the old IRIS standard; very easy to use, almost universally readable

# Web clients
include("Web/IRIS.jl")
include("Web/FDSN.jl")
include("Web/SeedLink.jl")
include("Web/WebMisc.jl")             # Common functions for web data access

include("Utils/resp.jl")              # Instrument response


end
