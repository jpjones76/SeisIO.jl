printstyled("SeisIO.Nodal submodule\n", color=:light_green)

fstr = path*"/SampleFiles/Nodal/Node1_UTC_20200307_170738.006.tdms"
fref = path*"/SampleFiles/Nodal/silixa_vals.dat"
io = open(fref, "r")
YY = Array{UInt8, 1}(undef, 39518815)
readbytes!(io, YY)
XX = reshape(decompress(Int16, YY), 60000, :)
