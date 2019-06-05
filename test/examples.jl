using SeisIO, SeisIO.Quake
import Printf
# US FDSNget example: 5 stations, 2 networks, all channels, last 600 seconds
println(stdout, "Beginning real \"use case\" examples...\n\n",
  "Note: ALL data from these examples can be written to file; \n",
  "type `wseis(object_name)` to save to native SeisIO format, \n",
  "type `writesac(object_name)` to write to SAC files,\n",
  "or rerun the data request with added keyword \"w=true\" to\n",
  "write mseed.")

println(stdout, "FDSN: see structure seis_fdsn")
CHA = "CC.PALM, UW.HOOD, CC.TIMB, CC.HIYU, UW.TDH"
s = -600
t = u2d(time())
println(stdout, "Command: seis_fdsn = get_data(\"FDSN\", \"", CHA, "\", src=\"IRIS\", s=", s, ", t=", t)
seis_fdsn = get_data("FDSN", CHA, src="IRIS", s=s, t=t)

# IRISWS example: 6 channels, 30 minutes, synchronized, saved to SAC format"
println(stdout, "IRISWS timeseries: see structure seis_iris")
STA = ["CC.TIMB..EHE", "CC.TIMB..EHN", "CC.TIMB..EHZ", "UW.HOOD..HHE", "UW.HOOD..HHN", "UW.HOOD..HHZ"]
st = -3600
en = -1800
println(stdout, "Command: seis_iris = get_data(\"IRIS\", ", STA, ", s=", st, ", t=", en)
seis_iris = get_data("IRIS", STA, s=st, t=en)

# The Tohoku-Oki great earthquake, from IRIS FDSN, recorded by boreholes in WA (USA)
println(stdout, "FDSN event example: see structure seis_evt")
println(stdout, "seis_evt = FDSNevt(\"201103110547\", \"PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?\")")
seis_evt = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
show(seis_evt)

# IRIS SeedLink session in TIME mode
println(stdout, "SeedLink example (part 1): see structure seis_sl")
sta = "UW.GRUT,UW.H1K,UW.MDW"
s1 = -120
t1 = 120
println(stdout, "seis_sl = SeedLink(\"", sta, "\", mode=\"TIME\", s=", s1, ", t=", t1, ")")
seis_sl = SeedLink(sta, mode="TIME", s=s1, t=t1)

# IRIS SeedLink session in DATA mode, to same structure
println(stdout, "SeedLink example (part 2): adds to structure seis_sl")
println(stdout, "SeedLink!(seis_sl, \"SampleFiles/SL_long_test.conf\", mode=\"DATA\")")
SeedLink!(seis_sl, "SampleFiles/SL_long_test.conf", mode="DATA")
println(stdout, "When finished, close connections with command \"for conn in seis_sl.c; close(conn); end\"")
