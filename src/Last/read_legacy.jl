function read_legacy(io::IO, ver::Float32)
  Z = getfield(BUF, :buf)
  L = getfield(BUF, :int64_buf)

  # read begins ------------------------------------------------------
  N     = read(io, Int64)
  checkbuf_strict!(L, 2*N)
  readbytes!(io, Z, 3*N)
  c1    = copy(Z[1:N])
  c2    = copy(Z[N+1:2*N])
  y     = code2typ.(getindex(Z, 2*N+1:3*N))
  cmp   = read(io, Bool)
  read!(io, L)
  nx    = getindex(L, N+1:2*N)

  if cmp
    checkbuf_8!(Z, maximum(nx))
  end

  ver < 0.5f0 && error("No legacy support for SeisIO file format version < 0.5")

  # Get file creation time
  fname = split(io.name)[2][1:end-1]
  isfile(fname) || error(string("Can't stat file ", fname))
  st = stat(fname)
  t0 = st.ctime
  if ver == 0.5f0
    S = SeisData(N)
    setfield!(S, :id, read_string_vec(io, Z))
    setfield!(S, :name, read_string_vec(io, Z))
    setfield!(S, :loc, InstrumentPosition[read(io, code2loctyp(getindex(c1, i))) for i = 1:N])
    read!(io, S.fs)
    read!(io, S.gain)

    # Here is the hard part. For older files, we read a degenerate InstResp
    R = InstrumentResponse[]
    for i = 1:N
      T = code2resptyp(getindex(c2, i))
      (T == GenResp) && (push!(R, read(io, GenResp)); continue)
      et = Complex{T == PZResp ? Float32 : Float64}

      # skip :c, it was never used
      skip(io, T == PZResp ? 4 : 8)

      # read poles
      np = read(io, Int64)
      p = zeros(et, np)
      read!(io, p)

      # read zeros
      nz = read(io, Int64)
      z = zeros(et, nz)
      read!(io, z)

      # push to R
      push!(R, T(p = p, z = z))
    end
    setfield!(S, :units, read_string_vec(io, Z))
    setfield!(S, :src, read_string_vec(io, Z))
    setfield!(S, :misc, [read_misc(io, Z) for i = 1:N])
    setfield!(S, :notes, [read_string_vec(io, Z) for i = 1:N])
    setfield!(S, :t, [read!(io, Array{Int64, 2}(undef, getindex(L, i), 2)) for i = 1:N])
    setfield!(S, :x,
    FloatArray[cmp ?
    (readbytes!(io, Z, getindex(nx, i)); Blosc.decompress(getindex(y,i), Z)) :
    read!(io, Array{getindex(y,i), 1}(undef, getindex(nx, i))) for i = 1:N])

    return S
  else
    # identical to v0.51 after 20190823; I didn't increment version #
    return SeisData(N,
    read_string_vec(io, Z),
    read_string_vec(io, Z),
    InstrumentPosition[read(io, code2loctyp(getindex(c1, i))) for i = 1:N],
    read!(io, Array{Float64, 1}(undef, N)),
    read!(io, Array{Float64, 1}(undef, N)),
    InstrumentResponse[read(io, code2resptyp(getindex(c2, i))) for i = 1:N],
    read_string_vec(io, Z),
    read_string_vec(io, Z),
    [read_misc(io, Z) for i = 1:N],
    [read_string_vec(io, Z) for i = 1:N],
    [read!(io, Array{Int64, 2}(undef, getindex(L, i), 2)) for i = 1:N],
    FloatArray[cmp ?
    (readbytes!(io, Z, getindex(nx, i)); Blosc.decompress(getindex(y,i), Z)) :
    read!(io, Array{getindex(y,i), 1}(undef, getindex(nx, i)))
    for i = 1:N])
  end
end
