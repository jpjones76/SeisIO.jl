using SeisIO, SeisIO.Quake, SeisIO.SeisHDF
import Printf

# US FDSN example: 5 stations, 2 networks, all channels, last 600 seconds
println(stdout, "Some real data acquisition examples...\n\n")

println(stdout, "preliminary: change directory")
path = Base.source_dir()
println(stdout, "cd(", path, ")")
cd(path)

printstyled(stdout, "FDSN get_data\n", color=:green, bold=true)
CHA = "CC.PALM, UW.HOOD, CC.TIMB, CC.HIYU, UW.TDH"
s = -600
t = u2d(time())
printstyled(stdout, "Command: ", color=:green)
println(stdout, "S_fdsn = get_data(\"FDSN\", \"", CHA, "\", src=\"IRIS\", s=", s, ", t=", t, ")")
S_fdsn = get_data("FDSN", CHA, src="IRIS", s=s, t=t)
printstyled(stdout, "Results: ", color=:green)
println(stdout, "S_fdsn")
show(S_fdsn)

# IRIS example: 6 channels, 30 minutes
printstyled(stdout, "\n\nIRIS get_data\n", color=:green, bold=true)
STA = ["CC.TIMB..BHE", "CC.TIMB..BHN", "CC.TIMB..BHZ", "UW.HOOD..HHE", "UW.HOOD..HHN", "UW.HOOD..HHZ"]
st = -3600
en = -1800
printstyled(stdout, "Command: ", color=:green)
println(stdout, "S_iris = get_data(\"IRIS\", ", STA, ", s=", st, ", t=", en, ")")
S_iris = get_data("IRIS", STA, s=st, t=en)
printstyled(stdout, "Results: ", color=:green)
println(stdout, "S_iris")
show(S_iris)

# The Tohoku-Oki great earthquake, from IRIS FDSN, recorded by boreholes in WA (USA)
printstyled(stdout, "\n\nFDSNevt\n", color=:green, bold=true)
printstyled(stdout, "Command: ", color=:green)
println(stdout, "S_evt = FDSNevt(\"201103110547\", \"PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?\")")
S_evt = FDSNevt("201103110547", "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?")
printstyled(stdout, "Results: ", color=:green)
println(stdout, "S_evt")
show(S_evt)

# SeisComp3 SeedLink session, IRIS server, TIME mode
printstyled(stdout, "\n\nSeedLink\n", color=:green, bold=true)
sta = "UW.GRUT,UW.H1K,UW.MDW"
s1 = -120
t1 = 120

printstyled(stdout, "Commands: ", color=:green)

println(stdout, "S_sl = seedlink(\"TIME\", \"", sta, "\", s=", s1, ", t=", t1, ")")
S_sl = seedlink("TIME", sta, s=s1, t=t1)

println(stdout, "          seedlink!(S_sl, \"DATA\", \"SampleFiles/SL_long_test.conf\")")
seedlink!(S_sl, "DATA", "SampleFiles/SL_long_test.conf")

println(stdout, "          sleep(30)")
sleep(30)

println(stdout, "          for conn in S_sl.c; close(conn); end")
for conn in S_sl.c; close(conn); end

printstyled(stdout, "Results: ", color=:green)
println(stdout, "S_sl")
show(S_sl)

printstyled(stdout, "\n\n\nNote: ", color=:white, bold=true)
println(stdout, "ALL data from these examples can be written to file.")
printstyled(stdout, "wseis(\"fname.seis\", S)", color=7)
println(stdout, "       write S to low-level SeisIO native format in file fname.seis")
printstyled(stdout, "writesac(S)", color=7)
println(stdout, "                  write S to SAC files with auto-generated names")
printstyled(stdout, "write_hdf5(\"fname.h5\", S)", color=7)
println(stdout, "    write S to ASDF (HDF5) file \"fname.h5\"")
