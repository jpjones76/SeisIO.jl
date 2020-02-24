function read_slist!(S::GphysData, fname::String, lennartz::Bool, mmap::Bool)
  # file read
  io = mmap ? IOBuffer(Mmap.mmap(fname)) : open(fname, "r")
  hdr = readline(io)
  mark(io)
  nx = countlines(io)
  reset(io)
  X = Array{Float32,1}(undef, nx)
  i = 0
  while i < nx
    i += 1
    v = stream_float(io, 0x00)
    setindex!(X, v, i)
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
  if (i > 0) && (fs == S.fs[i])
    T = S.t[i]
    Nt = size(T, 1)

    # Channel has some data already
    if Nt > 0
      Δ = round(Int64, 1.0e6/fs)
      if T[Nt, 2] == 0
        T = T[1:Nt-1,:]
      end
      S.t[i] = vcat(T, [1+length(S.x[i]) ts-endtime(S.t[i], Δ)-Δ; nx+length(S.x[i]) 0])
      append!(S.x[i], X)

    # Channel exists but is empty
    else
      S.t[i] = mk_t(nx, ts)
      S.x[i] = X
    end
  else
    # New channel
    push!(S, SeisChannel(id = id, fs = fs, t = mk_t(nx, ts), x = X))
  end
  return nothing
end
