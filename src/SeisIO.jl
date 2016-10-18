VERSION >= v"0.4.0" && __precompile__(true)
module SeisIO

export SeisChannel, SeisData, findname, findid, hasid, hasname,# Types/SeisData.jl
SeisHdr, SeisEvent, note,                                      # Types/SeisHdr.jl
wseis, writesac,                                               # Types/write.jl
rseis,                                                         # Types/read.jl
samehdr, pull, getbandcode, prune!, purge, purge!, gapfill!,   # Types/misc.jl
gapfill, ungap!, ungap, sync!, sync, autotap!,                 #
batch_read,                                                    # Formats/BatchProc.jl
parsemseed, readmseed, parsesl, readmseed, parserec,           # Formats/mSEED.jl
rlennasc,                                                      # Formats/LennartzAsc.jl
prunesac!, psac, r_sac, sacwrite, chksac, sachdr,              # Formats/SAC.jl
get_sac_keys, get_sac_fw, get_sac_iw, sactoseis,               #
readsac, writesac, sac_bat,                                    #
readsegy, segyhdr, pruneseg, segytosac, segytoseis, r_segy,    # Formats/SEGY.jl
readuwpf, readuwdf, readuw, uwtoseis, r_uw,                    # Formats/UW.jl
readwin32, win32toseis, r_win32,                               # Formats/Win32.jl
FDSNget,                                                       # Web/FDSN.jl
IRISget, irisws,                                               # Web/IRIS.jl
SeedLink,                                                      # Web/SeedLink.jl
get_uhead, GetSta,                                             # Web/WebMisc.jl
evq, gcdist, distaz!, getpha, getevt,                          # Utils/event_utils.jl
randseisobj, randseisdata,                                     # Utils/randseis.jl
fctopz,                                                        # Utils/resp.jl
parsetimewin, j2md, md2j, sac2epoch, u2d, d2u, tzcorr,         # Utils/time_aux.jl
t_expand, xtmerge, xtjoin!

# SeisData is designed as a universal, gap-tolerant "working" format for
# geophysical timeseries data
include("Types/SeisData.jl")      # SeisData, SeisChan classes for channel data
include("Types/SeisHdr.jl")       # Class for headers of discrete events (SeisHdr)
include("Types/composite.jl")     # Composite types (SeisEvent, SeisCat)
include("Types/read.jl")          # Read
include("Types/write.jl")         # Write
include("Types/show.jl")          # Display

# Auxiliary time and file functions
include("Utils/randseis.jl")      # Create random SeisData for testing purposes
include("Utils/misc.jl")          # Utilities that don't fit elsewhere
include("Utils/time_aux.jl")      # Time functions
include("Utils/file_aux.jl")      # Misc. file function
include("Utils/resp.jl")          # Instrument response
include("Utils/event_utils.jl")   # Event utilities

# Data converters
include("Formats/SAC.jl")         # SAC is the old IRIS standard; very easy to use, almost universally readable
include("Formats/SEGY.jl")        # SEG Y, standard of the Society for Exploration Geophysicists
include("Formats/mSEED.jl")       # SEED has become the worldwide seismic data standard despite being monolithic
include("Formats/UW.jl")          # University of Washington: used at UW 1970s through mid-2000s
include("Formats/Win32.jl")       # Win32: standard Japanese seismic data format
include("Formats/LennartzAsc.jl") # Lennartz ASCII: a cheap wrapper to readdlm
include("Formats/BatchProc.jl")   # SAC is the old IRIS standard; very easy to use, almost universally readable

# Web clients
include("Web/IRIS.jl")
include("Web/FDSN.jl")
include("Web/SeedLink.jl")
include("Web/WebMisc.jl")             # Common functions for web data access

# Submodule SeisPol
module SeisPol
export seispol, seisvpol, polhist, gauss, gdm, chi2d, qchd
include("Submodules/hist_utils.jl")
include("Submodules/seis_pol.jl")
end

end
