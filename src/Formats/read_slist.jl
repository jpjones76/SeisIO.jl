function read_slist!(S::SeisData, f::String)
  fname = realpath(f)
  id_sep = "_"
  C = SeisChannel()
  nx = countlines(fname) - 1
  i = 1
  X = Array{Float32,1}(undef, nx)

  # file read
  io = open(fname, "r")
  h_line = readline(io)
  while !eof(io)
    v = stream_float(io, 0x00)
    setindex!(X, v, i)
    i += 1
  end
  close(io)
  # file read

  # header
  h = split(h_line, ',')
  slist_id = split(h[1], '_')
  slist_id[1] = split(slist_id[1])[2]
  sta = slist_id[2]
  loc = slist_id[3]
  cha = slist_id[4]
  C = SeisChannel(join(slist_id, '.'),
                  "",
                  GeoLoc(),
                  parse(Float64, split(h[3])[1]),
                  1.0,
                  PZResp(),
                  "",
                  fname,
                  Dict{String, Any}(),
                  String[],
                  mk_t(nx, 1000*(DateTime(lstrip(h[4])).instant.periods.value - div(dtconst, 1000))),
                  X)
  push!(S, C)
  return nothing
end
