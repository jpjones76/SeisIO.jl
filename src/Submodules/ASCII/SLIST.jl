function read_slist!(S::GphysData, fname::String, lennartz::Bool, memmap::Bool, strict::Bool, v::Integer)
  # file read
  io = memmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  hdr = readline(io)
  mark(io)
  nx = countlines(io)
  reset(io)
  X = Array{Float32,1}(undef, nx)
  i = 0
  while i < nx
    i += 1
    y = stream_float(io, 0x00)
    setindex!(X, y, i)
  end
  close(io)

  # header
  if lennartz
    id_sep = "."
    h = split(hdr)
    sta = replace(h[3], "\'" => "")
    cmp = last(split(fname, id_sep))
    id = *(id_sep, sta, id_sep, id_sep, cmp)
    ts = (Date(h[8]).instant.periods.value)*86400000000 +
          div(Time(h[9]).instant.value, 1000) -
          dtconst
    fs = 1000.0 / parse(Float64, h[5])
  else
    h = split(hdr, ',')
    id = join(split_id(split(h[1])[2], c="_"), ".")
    ts = 1000*DateTime(lstrip(h[4])).instant.periods.value - dtconst
    fs = parse(Float64, split(h[3])[1])
  end

  # Check for existing channel with same fs
  i = findid(S, id)
  if strict
    i = channel_match(S, i, fs)
  end
  if (i > 0)
    check_for_gap!(S, i, ts, nx, v)
    append!(S.x[i], X)
  else
    # New channel
    push!(S, SeisChannel(id = id, fs = fs, t = mk_t(nx, ts), x = X))
  end
  return nothing
end
