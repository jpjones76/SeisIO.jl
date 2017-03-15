# ===========================================================================
# Auxiliary file read functions
function readstr_varlen(io::IOStream)
  L = read(io, Int64)
  if L > 0
    str = String(read(io, UInt8, L))
  else
    str = ""
  end
  return str
end

function read_string_array(io::IOStream)
  nd = Int64(read(io, UInt8))
  d = read(io, Int64, nd)
  if d==[0]
    S = Array{String,1}()
  else
    sep = Char(read(io, UInt8))
    l = read(io, Int64)
    S = reshape([String(j) for j in split(String(read(io, UInt8, l)), sep)], tuple(d[:]...))
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
    t = Any
  end
  return t
end

function read_misc(io::IOStream)
  D = Dict{String,Any}()
  L = read(io, Int64)
  if L > 0
    l = read(io, Int64)
    ksep = Char(read(io, UInt8))
    kstr = String(read(io, UInt8, l))
    K = collect(split(kstr, ksep))
    for i in K
      t = read(io, UInt8)
      T = code2typ(t)
      if t == 0x81
        D[i] = read_string_array(io)
      elseif T <: Array
        N = read(io, UInt8)
        d = tuple(read(io, Int64, N)[:]...)
        t = eltype(T)
        if t <: Complex
          τ = eltype(real(t))
          D[i] = complex(read(io, τ, d), read(io, τ, d))
        else
          D[i] = read(io, t, d)
        end
      elseif T == String
        n = read(io, Int64)
        D[i] = String(read(io, UInt8, n))
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
  i64 = read(io, Int64, 5)
  m = read(io, Float32)
  f64 = read(io, Float64, 26)
  u8 = read(io, UInt8, 4+sum(i64[3:5]))
  misc = read_misc(io)

  setfield!(H, :id, i64[1])
  setfield!(H, :ot, u2d(i64[2]*μs))
  setfield!(H, :mag, (m, Char(u8[1]), Char(u8[2])))
  c = u8[3]
  k = 4+i64[3]
  setfield!(H, :int, (u8[4], String(u8[5:k])))
  setfield!(H, :src, String(u8[k+1:k+i64[4]]))
  if i64[5] > 0
    k += i64[4]
    n = u8[k+1:k+i64[5]]
    setfield!(H, :notes, [String(j) for j in split(String(n),Char(c))])
  end
  setfield!(H, :loc, f64[1:3])
  setfield!(H, :mt, f64[4:11])
  setfield!(H, :np, [(f64[12], f64[13], f64[14]), (f64[15], f64[16], f64[17])])
  setfield!(H, :pax, [(f64[18], f64[19], f64[20]), (f64[21], f64[22], f64[23]), (f64[24], f64[25], f64[26])])
  setfield!(H, :misc, misc)
  return H
end

# SeisData, SeisChannel
function rdata(io::IOStream)
  Base.gc_enable(false)
  N = convert(Int64, read(io, UInt32))
  S = SeisData(N)
  for i = 1:1:N

    # int
    i64 = read(io, Int64, 8)
    if i64[1] > 0
      S.t[i] = reshape(read(io, Int64, i64[1]), div(i64[1],2), 2)
    end

    # float
    S.fs[i] = read(io, Float64)
    S.gain[i] = read(io, Float64)

    # float arrays
    S.loc[i] = read(io, Float64, 5)
    if i64[2] > 0
      S.resp[i] = reshape(complex(read(io, Float64, i64[2]), read(io, Float64, i64[2])), div(i64[2],2), 2)
    end

    # U8
    c = read(io, UInt8)
    y = read(io, UInt8)

    # U8 array
    S.id[i]   = strip(String(read(io, UInt8, 15)))
    S.units[i]= String(read(io, UInt8, i64[3]))
    S.src[i]  = String(read(io, UInt8, i64[4]))
    S.name[i] = String(read(io, UInt8, i64[5]))
    if i64[6] > 0
      S.notes[i] = map(String, split(String(read(io, UInt8, i64[6])), Char(c)))
    else
      S.notes[i] = Array{String,1}([""])
    end
    if y == 0x32
      S.x[i]  = Blosc.decompress(Float64, read(io, UInt8, i64[7]))
    elseif y == 0x31
      S.x[i]  = Blosc.decompress(Float32, read(io, UInt8, i64[7]))
    else
      S.x[i]  = Blosc.decompress(code2typ(y), read(io, UInt8, i64[7]))
    end
    S.misc[i] = read_misc(io)
  end
  Base.gc_enable(true)
  return S
end

revent(io::IOStream) = (
  S = SeisEvent();
  setfield!(S, :hdr, rhdr(io));
  setfield!(S, :data, rdata(io));
  return S
  )


"""
    rseis(fstr::String)

Read SeisIO files matching file string ``fstr`` into memory.

"""
function rseis(files::Array{String,1}; v=0::Int)
  A = Array{Any,1}(0)

  for f in files
    io = open(f, "r")
    (String(read(io, UInt8, 6)) == "SEISIO") || (close(io); error("Not a SeisIO file!"))
    r = read(io, Float32)
    j = read(io, Float32)
    L = read(io, Int64)
    C = read(io, UInt8, L)
    B = read(io, UInt64, L)
    (v > 0) && @printf(STDOUT, "Reading %i total objects from file %s.\n", L, f)
    for i = 1:1:L
      if C[i] == 0x48
        push!(A, rhdr(io))
      elseif C[i] == 0x45
        push!(A, revent(io))
      else
        push!(A, rdata(io))
      end
      (v > 0) && @printf(STDOUT, "Read %s object from %s, bytes %i:%i.\n", typeof(A[end]), f, B[i], ((i == L) ? position(io) : B[i+1]))
    end
    close(io)
  end
  return A
end
rseis(fstr::String; v=0::Int) = rseis(ls(fstr), v=v)

"""
    rseis(fstr::String)

Read SeisIO files matching file string ``fstr`` into memory.

"""
function rseis(files::Array{String,1}, c::Array{Int,1}; v=0::Int)
  A = Array{Any,1}(0)

  for f in files
    io = open(f, "r")
    (String(read(io, UInt8, 6)) == "SEISIO") || (close(io); error("Not a SeisIO file!"))
    r = read(io, Float32)
    j = read(io, Float32)
    L = read(io, Int64)
    C = read(io, UInt8, L)
    B = read(io, UInt64, L)
    (v > 0) && @printf(STDOUT, "Reading %i total objects from file %s.\n", L, f)
    for k = 1:1:length(c)
      if c[k] > length(L)
        warn(string("Skipped file=", f, ", k=", c[k], " (no such record \#)"))
        continue
      else
        i = c[k]
        seek(io, B[i])
        if C[i] == 0x48
          push!(A, rhdr(io))
        elseif C[i] == 0x45
          push!(A, revent(io))
        else
          push!(A, rdata(io))
        end
        (v > 0) && @printf(STDOUT, "Read %s object from %s, bytes %i:%i.\n", typeof(A[end]), f, B[i], ((i == L) ? position(io) : B[i+1]))
      end
    end
    close(io)
  end
  return A
end
rseis(fstr::Array{String,1}, c::Int; v=0::Int) = rseis(fstr, Int[c], v=v)
rseis(fstr::String, c::Int; v=0::Int) = rseis(ls(fstr), Int[c], v=v)
