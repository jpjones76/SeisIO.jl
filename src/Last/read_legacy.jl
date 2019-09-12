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
    S.resp .= R
    setfield!(S, :units, read_string_vec(io, Z))
    setfield!(S, :src, read_string_vec(io, Z))
    setfield!(S, :misc, [read_misc(io, Z) for i = 1:N])
    setfield!(S, :notes, [read_string_vec(io, Z) for i = 1:N])
    setfield!(S, :t, [read!(io, Array{Int64, 2}(undef, getindex(L, i), 2)) for i = 1:N])
    setfield!(S, :x,
    FloatArray[cmp ?
    (readbytes!(io, Z, getindex(nx, i)); Blosc.decompress(getindex(y,i), Z)) :
    read!(io, Array{getindex(y,i), 1}(undef, getindex(nx, i))) for i = 1:N])
  elseif ver < 0.53
    #=  Read process for 0.51 and 0.52 is identical; 0.52 added two Types <:
        InstrumentResponse that v0.51 doesn't know about, so this is a safe
        procedure =#
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
      if T in (PZResp, PZResp64, GenResp)
        push!(R, read(io, T))

      # This leaves us with CoeffResp and MultiStageResp
      elseif T == CoeffResp
        # skip these
        for j = 1:2
          n = read(io, Int64)
          skip(io, n)
        end
        push!(R, CoeffResp(
                            read!(io, Array{Float64,1}(undef, read(io, Int64))),
                            read!(io, Array{Float64,1}(undef, read(io, Int64)))
                          ))
      elseif T == MultiStageResp
        K = read(io, Int64)
        codes = read(io, K)
        M = MultiStageResp(K)
        A = Array{RespStage,1}(undef, 0)
        for j = 1:K
          c = codes[j]
          if c == 0x03
            units_out = String(read(io, read(io, Int64)))
            units_in = String(read(io, read(io, Int64)))
            M.i[j] = units_in
            M.o[j] = units_out
            if j == 2
              M.i[1] = units_out
            end
            CR = CoeffResp(
                       read!(io, Array{Float64,1}(undef, read(io, Int64))),
                       read!(io, Array{Float64,1}(undef, read(io, Int64)))
                       )
            push!(A, CR)
          else
            push!(A, read(io, code2resptyp(c)))
          end
        end
        M.stage .= A
        read!(io, M.fs)
        read!(io, M.gain)
        read!(io, M.fg)
        read!(io, M.delay)
        read!(io, M.corr)
        read!(io, M.fac)
        read!(io, M.os)
        push!(R, M)
      end
    end
    S.resp .= R
    setfield!(S, :units, read_string_vec(io, Z))
    for i = 1:N
      if typeof(S.resp[i]) == MultiStageResp
        K = length(S.resp[i].fs)
        if K > 0
          S.resp[i].o[1] = S.units[i]
        end
      end
    end
    setfield!(S, :src, read_string_vec(io, Z))
    setfield!(S, :misc, [read_misc(io, Z) for i = 1:N])
    setfield!(S, :notes, [read_string_vec(io, Z) for i = 1:N])
    setfield!(S, :t, [read!(io, Array{Int64, 2}(undef, getindex(L, i), 2)) for i = 1:N])
    setfield!(S, :x,
    FloatArray[cmp ?
    (readbytes!(io, Z, getindex(nx, i)); Blosc.decompress(getindex(y,i), Z)) :
    read!(io, Array{getindex(y,i), 1}(undef, getindex(nx, i))) for i = 1:N])
  end
  return S
end
