VERSION >= v"0.4.0" && __precompile__(true)
module SeisIO
export SeisObj, SeisData, findname, findid, hasid, hasname,    # SeisData/SeisData.jl
samehdr, t_expand, t_collapse, pull, note,
getbandcode, prune!, purge, purge!, gapfill!,                  # SeisData/utils.jl
gapfill, ungap!, ungap, sync!, sync, autotap!,
randseisobj, randseisdata,                                     # SeisData/randseis.jl
wseis, rseis, writesac,                                        # SeisData/fileio.jl
FDSNget, IRISget, irisws, SeedLink,                            # Web services
readuwpf, readuwdf, readuw, uwtoseis, r_uw,                    # UW
prunesac!, psac, r_sac, sacwrite, chksac, sachdr,              # SAC
get_sac_keys, get_sac_fw, get_sac_iw, sactoseis,
readsac, writesac,
readsegy, segyhdr, pruneseg, segytosac, segytoseis, r_segy,    # SEG Y
readwin32, win32toseis, r_win32,                               # Win 32
parsemseed, readmseed, parsesl, readmseed, parserec,           # mini-SEED
rlennasc,                                                      # Lennartz ASCII
plotseis,                                                      # Plotting/plotseis.jl
parsetimewin, j2md, md2j, sac2epoch,                           # time_aux.jl
seisio_notes                                                   # this file

# Auxiliary time functions
include("Utils/time_aux.jl")

# SeisData is designed as a universal, gap-tolerant "working" format for
# geophysical timeseries data
include("SeisData/SeisData.jl")
include("SeisData/show.jl")
include("SeisData/fileio.jl")
include("SeisData/utils.jl")
include("SeisData/randseis.jl")

# Data converters
include("FileFormats/SAC.jl")         # SAC is the old IRIS standard; very easy to use, almost universally readable
include("FileFormats/SEGY.jl")        # SEG Y, standard of the Society for Exploration Geophysicists
include("FileFormats/mSEED.jl")       # SEED has become the worldwide seismic data standard despite being monolithic
include("FileFormats/UW.jl")          # University of Washington: used at UW 1970s through mid-2000s
include("FileFormats/Win32.jl")       # Win32: standard Japanese seismic data format
include("FileFormats/LennartzAsc.jl") # Lennartz ASCII: a cheap wrapper to readdlm

# Web clients
include("WebClients/IRIS.jl")
include("WebClients/FDSN.jl")
include("WebClients/SeedLink.jl")

# Plotting
include("Utils/plotseis.jl")

"""
seisio_notes()

* mSEED: limited blockette, encoding support at present
* SEG Y: supports standard rev0/rev1 and the modified rev0 used by PASSCAL/NMT
* UW: works with UW-2 format; untested on UW-1 format (≤ 1990)
* WIN32: works with win32 format; untested on win format (≤ 2000)
"""
function seisio_notes()
  println("mSEED: limited blockette, encoding support at present")
  println("SEG Y: supports standard rev0/rev1 and the modified rev0 used by PASSCAL/NMT")
  println("UW: works with UW-2 format; untested on UW-1 format (≤ 1990)")
  println("WIN32: works with win32 format; untested on win format (≤ 2000)")
end
end
