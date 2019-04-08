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
  if d==[0]
    S = Array{String,1}()
  else
    sep = Char(read(io, UInt8))
    l = read(io, Int64)
    S = reshape([String(j) for j in split(String(read!(io, Array{UInt8}(undef, l))), sep)], tuple(d[:]...))
  end
  return S
end

findtype(c::UInt8, N::Array{Int64,1}) = findfirst(N.==2^c)
function code2typ(c::UInt8)
  t = Any::Type
  if c >= 0x80
    t = Array{code2typ(c-0x80)}
  elseif c >= 0x40
    t = Complex{code2typ(c-0x40)}
  elseif c >= 0x30
    T = Array{Type,1}([BigFloat, Float16, Float32, Float64])
    N = Int[24, 2, 4, 8]
    t = T[findtype(c-0x2f, N)]
  elseif c >= 0x20
    T = Array{Type,1}([Int128, Int16, Int32, Int64, Int8])
    N = Int[16, 2, 4, 8, 1]
    t = T[findtype(c-0x20, N)]
  elseif c >= 0x10
    T = Array{Type,1}([UInt128, UInt16, UInt32, UInt64, UInt8])
    N = Int[16, 2, 4, 8, 1]
    t = T[findtype(c-0x10, N)]
  elseif c == 0x01
    t = String
  elseif c == 0x00
    t = Char
  else
    throw(TypeError)
  end
  return t
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

  i64   = read!(io, Array{Int64, 1}(undef, 6))
  m     = read(io, Float32)
  f64   = read!(io, Array{Float64, 1}(undef, 26))
  u8    = read!(io, Array{UInt8, 1}(undef, 2 + sum(i64[3:6])))
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
  setfield!(H, :loc, f64[1:3])                                      # Event location
  setfield!(H, :mt, f64[4:11])                                      # Moment tensor
  setfield!(H, :np, [(f64[12], f64[13], f64[14]),
                    (f64[15], f64[16], f64[17])])                   # Nodal planes
  setfield!(H, :pax, [(f64[18], f64[19], f64[20]),
                      (f64[21], f64[22], f64[23]),
                      (f64[24], f64[25], f64[26])])                 # Pricinpal axes
  return H
end

# SeisData, SeisChannel
function rdata(io::IOStream, ver::Float32)
  Base.GC.enable(false)
  N = convert(Int64, read(io, UInt32))
  S = SeisData(N)
  for i = 1:N

    # int
    if ver < 0.4f0
      i64 = read!(io, Array{Int64, 1}(undef, 9))
    else
      i64 = read!(io, Array{Int64, 1}(undef, 10))
    end
    if i64[1] > 0
      S.t[i] = reshape(read!(io, Array{Int64, 1}(undef, i64[1])), div(i64[1],2), 2)
    end

    # float
    S.fs[i] = read(io, Float64)
    S.gain[i] = read(io, Float64)

    # float arrays
    S.loc[i] = read!(io, Array{Float64, 1}(undef, i64[9]))
    if i64[2] > 0
      test_read_1 = read!(io, Array{Float64, 1}(undef, i64[2]))
      test_read_2 = read!(io, Array{Float64, 1}(undef, i64[2]))
      S.resp[i] = reshape(complex.(test_read_1, test_read_2), div(i64[2],2), 2)
    end

    # U8
    c = read(io, UInt8)
    y = read(io, UInt8)

    # U8 array
    S.id[i] = String(read!(io, Array{UInt8, 1}(undef, i64[10])))
    S.units[i]= String(read!(io, Array{UInt8, 1}(undef, i64[3])))
    S.src[i]  = String(read!(io, Array{UInt8, 1}(undef, i64[4])))
    S.name[i] = String(read!(io, Array{UInt8, 1}(undef, i64[5])))
    if i64[6] > 0
      S.notes[i] = map(String, split(String(read!(io, Array{UInt8, 1}(undef, i64[6]))), Char(c)))
    else
      S.notes[i] = Array{String,1}(undef, 0)
    end
    S.x[i]  = Blosc.decompress(code2typ(y), read!(io, Array{UInt8, 1}(undef, i64[7])))
    S.misc[i] = read_misc(io)
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

function read_rec(io::IOStream, r::Float32, u::UInt8; v=0::Int)
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
    j = read(io, Float32)   # Julia version
    L = read(io, Int64)
    C = read!(io, Array{UInt8, 1}(undef, L))
    B = read!(io, Array{UInt64, 1}(undef, L))
    if r > 0.3
      Nc = read!(io, Array{Int64, 1}(undef, L))
    end
    if isempty(c)
      (v > 1) && @printf(stdout, "Reading %i total objects from file %s.\n", L, f)
      for n = 1:L
        push!(A, read_rec(io, r, C[n], v=v))
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
          push!(A, read_rec(io, r, C[n], v=v))
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
