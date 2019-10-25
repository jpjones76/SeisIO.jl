# FIX

function read_slist!(S::SeisData, f::String; lennartz::Bool=false)
  fname = realpath(f)
  nx = countlines(fname) - 1
  i = 1
  X = Array{Float32,1}(undef, nx)

  # file read
  io = open(fname, "r")
  h_line = readline(io)
  while i ≤ nx
    v = stream_float(io, 0x00)
    setindex!(X, v, i)
    i += 1
  end
  close(io)

  # header
  if lennartz
    id_sep = "."
    h = split(h_line)
    sta = replace(h[3], "\'" => "")
    cmp = last(split(fname, id_sep))
    ts = (Date(h[8]).instant.periods.value)*86400000000 +
          div(Time(h[9]).instant.value, 1000) -
          dtconst
    C = SeisChannel(*(id_sep, sta, id_sep, id_sep, cmp),
                    "",
                    GeoLoc(),
                    1000.0 / parse(Float64, h[5]),
                    1.0,
                    PZResp(),
                    "",
                    fname,
                    Dict{String, Any}(),
                    String[],
                    mk_t(nx, ts),
                    X)
  else
    h = split(h_line, ',')
    id = split_id(split(h[1])[2], c="_")
    C = SeisChannel(join(id, "."),
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
  end
  push!(S, C)
  return nothing
end
