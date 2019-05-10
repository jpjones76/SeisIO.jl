export rseis

Blosc.set_num_threads(Sys.CPU_THREADS)

# ===========================================================================
# Auxiliary file read functions
chk_seisio(io::IOStream, f_ok::Array{UInt8,1} =
  UInt8[0x53, 0x45, 0x49, 0x53, 0x49, 0x4f]) =
  (read(io, 6) == f_ok ? true : false)

# Don't do this! It breaks the scoping of A for reasons unknown (bug in Julia)
# function read_preamble(io::IOStream)
#   r = read(io, Float32)
#   j = read(io, Float32)
#   L = read(io, Int64)
#   C = Array{UInt8,1}(undef, L)
#   B = copy(C)
#   read!(io, C)
#   read!(io, B)
#   return (r, j, L, C, B)
# end

function read_string_array(io::IOStream)
  nd = Int64(read(io, UInt8))
  d = read!(io, Array{Int64}(undef, nd))
  sep = Char(read(io, UInt8))
  l = read(io, Int64)
  S = reshape([String(j) for j in split(String(read!(io, Array{UInt8}(undef, l))), sep)], tuple(d[:]...))
  return S
end

function read_misc(io::IOStream)
  D = Dict{String,Any}()
  L = read(io, Int64)
  if L > 0
    l = read(io, Int64)
    ksep = Char(read(io, UInt8))
    kstr = String(read!(io, Array{UInt8,1}(undef, l))) #kstr = String(read(io, UInt8, l))
    K = collect(split(kstr, ksep))
    for i in K
      t = read(io, UInt8)
      T = code2typ(t)
      if t == 0x81
        D[i] = read_string_array(io)
      elseif T <: Array
        N = read(io, UInt8)
        d = tuple(read!(io, Array{Int64}(undef, N))[:]...) #d = tuple(read(io, Int64, N)[:]...)
        t = eltype(T)
        if t <: Complex
          τ = eltype(real(t))
          D[i] = complex.(read!(io, Array{τ}(undef, d)), read!(io, Array{τ}(undef, d)))
        else
          D[i] = read!(io, Array{t}(undef,  d)) #D[i] = read(io, t, d)
        end
      elseif T == String
        n = read(io, Int64)
        D[i] = String(read!(io, Array{UInt8}(undef, n))) #D[i] = String(read(io, UInt8, n))
      else
        D[i] = read(io, T)
      end
    end
  end
  return D
end

# ===========================================================================
# r_struct methods

# SeisHdr
function rhdr(io::IOStream)
  H = SeisHdr()

  i64   = read!(io, Array{Int64, 1}(undef, 8))
  L_mt  = i64[7]
  L_ax  = i64[8]
  m     = read(io, Float32)
  mt    = Array{Float64, 1}(undef, L_mt)
  ax    = Array{Float64, 1}(undef, L_ax)
  if L_mt > 0
    read!(io, mt)
  end
  if L_ax > 0
    read!(io, ax)
  end
  u8    = read!(io, Array{UInt8, 1}(undef, 2 + sum(i64[3:6])))

  Loc = EQLoc()
  readloc!(io, Loc)
  setfield!(H, :loc, Loc)                                           # Loc
  setfield!(H, :misc, read_misc(io))                                # Misc

  # First two u8s are separator and intensity value
  c = u8[1]
  i0 = u8[2]

  # parse i64 array
  j = 3; k = 2 + i64[3]
  setfield!(H, :id, i64[1])                                         # Event id
  setfield!(H, :ot, u2d(i64[2]*μs))                                 # Origin time
  setfield!(H, :mag, (m, String(u8[j:k])))                          # Magnitude
  j = k + 1
  k = k + i64[4]
  setfield!(H, :int, (i0, String(u8[j:k])))                         # Intensity
  j = k + 1
  k = k + i64[5]
  setfield!(H, :src, String(u8[j:k]))                               # Data source
  if i64[6] > 0
      j = k + 1
      k = k + i64[6]
      setfield!(H, :notes, String.(split(String(u8[j:k]), Char(c))))# Notes
  end
  setfield!(H, :mt, mt)                                             # Moment tensor
  axes = Array{NTuple{3,Float64},1}(undef, 0)                       # Axes
  j = 0
  while j < L_mt
    push!(axes, (ax[j+1], ax[j+2], ax[j+3]))
    j += 3
  end
  setfield!(H, :axes, axes)
  return H
end

# SeisData, SeisChannel
function rdata(io::IOStream, ver::Float32)
  Base.GC.enable(false)
  N = convert(Int64, read(io, UInt32))
  y_code = read(io, UInt8)
  if y_code == 0x01
    S = EventTraceData(N)
  else
    S = SeisData(N)
  end
  for i = 1:N

    # int
    i64 = read!(io, Array{Int64, 1}(undef, 8))
    if i64[1] > 0
      S.t[i] = reshape(read!(io, Array{Int64, 1}(undef, i64[1])), div(i64[1],2), 2)
    end

    # float
    S.fs[i] = read(io, Float64)
    S.gain[i] = read(io, Float64)

    # U8
    c = read(io, UInt8)
    y = read(io, UInt8)
    loc_c = read(io, UInt8)
    resp_c = read(io, UInt8)

    # U8 array
    S.id[i]     = String(read!(io, Array{UInt8, 1}(undef, i64[8])))
    S.units[i]  = String(read!(io, Array{UInt8, 1}(undef, i64[2])))
    S.src[i]    = String(read!(io, Array{UInt8, 1}(undef, i64[3])))
    S.name[i]   = String(read!(io, Array{UInt8, 1}(undef, i64[4])))
    if i64[5] > 0
      S.notes[i] = map(String, split(String(read!(io, Array{UInt8, 1}(undef, i64[5]))), Char(c)))
    else
      S.notes[i] = Array{String,1}(undef, 0)
    end
    S.x[i]  = Blosc.decompress(code2typ(y), read!(io, Array{UInt8, 1}(undef, i64[6])))

    # loc
    Loc = code2loctype(loc_c)()
    readloc!(io, Loc)
    setindex!(getfield(S, :loc), Loc, i)

    # resp
    if resp_c == 0x01 || resp_c == 0x02
      R = readPZResp(io)
    else
      R = readGenResp(io)
    end
    setindex!(getfield(S, :resp), R, i)

    # misc
    S.misc[i] = read_misc(io)

    # extras for EventTraceData
    if y_code == 0x01
      S.az[i] = read(io, Float64)
      S.baz[i] = read(io, Float64)
      S.dist[i] = read(io, Float64)
      S.pha[i] = read(io, PhaseCat)
    end
  end
  Base.GC.enable(true)
  return S
end

revent(io::IOStream, ver::Float32) = SeisEvent(hdr = rhdr(io), data = rdata(io, ver))

function build_file_list(patts::Union{String,Array{String,1}})
  if isa(patts, String)
    patts = [patts]
  end
  file_list = String[]
  for pat in patts
    files = ls(pat)
    for f in files
      if safe_isfile(f)
        push!(file_list, f)
      end
    end
  end
  return file_list
end

function read_rec(io::IOStream, r::Float32, u::UInt8)
  if u == 0x48
    return rhdr(io)
  elseif u == 0x45
    return revent(io, r)
  else
    return rdata(io, r)
  end
end
"""
    rseis(fstr::String[, c=C::Array{Int64,1}, v=0::Int])
Read SeisIO files matching file pattern ``fstr`` into memory.
If an array of record indices is passed to keyword c, only those record indices
are read from each file.
Set v>0 to control verbosity.
"""
function rseis(patts::Union{String,Array{String,1}};
  c::Union{Int64,Array{Int64,1}}  = Int64[],
  v::Int64                        = KW.v)

  A = Array{Any,1}(undef, 0)
  files = build_file_list(patts)
  if isa(c, Int64)
    c = [c]
  end
  for f in files
    io = open(f, "r")
    if chk_seisio(io) == false
      (v > 0) && @warn string("Skipped ", f, ": invalid SeisIO file!")
      close(io)
      continue
    end
    r = read(io, Float32)   # SeisIO file format version
    L = read(io, Int64)
    C = read!(io, Array{UInt8, 1}(undef, L))
    B = read!(io, Array{UInt64, 1}(undef, L))
    if r > 0.3
      Nc = read!(io, Array{Int64, 1}(undef, L))
    end
    if isempty(c)
      (v > 1) && @printf(stdout, "Reading %i total objects from file %s.\n", L, f)
      for n = 1:L
        push!(A, read_rec(io, r, C[n]))
        (v > 1) && @printf(stdout, "Read object %i/%i of type %s.\n", n, L, typeof(A[n]))
      end
    else
      if minimum(c) > L
        (v > 0) && @info string("Skipped ", f, ": file contains none of the record numbers given.")
        close(io)
        continue
      end
      RNs = collect(1:1:L)
      for k = 1:length(c)
        n = c[k]
        if n in RNs
          seek(io, B[n])
          push!(A, read_rec(io, r, C[n]))
          (v > 1) && @printf(stdout, "Read %s object from %s, bytes %i:%i.\n", typeof(A[end]), f, B[n], ((n == L) ? position(io) : B[n+1]))
        else
          (v > 0) && @info(string((n > L ? "No" : "Skipped"), " record ", c[k], " in ", f))
        end
      end
    end
    close(io)
  end
  return A
end
