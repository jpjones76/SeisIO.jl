printstyled("SeisIO.Nodal submodule\n", color=:light_green)

function pop_nodal_dict!(info:: Dict{String, Any}; n::Int64=12, kmax::Int64=32)
  for i in 1:n
    k = randstring(rand(1:kmax))
    t = rand([0x00000001,
              0x00000002,
              0x00000003,
              0x00000004,
              0x00000005,
              0x00000006,
              0x00000007,
              0x00000008,
              0x00000009,
              0x0000000a,
              0x00000020])
    T = get(SeisIO.Nodal.tdms_codes, t, UInt8)
    v = T == Char ? randstring(rand(1:256)) : rand(T)
    info[k] = v
  end
  return nothing
end

fstr = path*"/SampleFiles/Nodal/Node1_UTC_20200307_170738.006.tdms"
fref = path*"/SampleFiles/Nodal/silixa_vals.dat"
io = open(fref, "r")
YY = Array{UInt8, 1}(undef, 39518815)
readbytes!(io, YY)
XX = reshape(decompress(Int16, YY), 60000, :)
