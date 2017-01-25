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

findtype(c::UInt8, T::Array{Type,1}) = T[findfirst([sizeof(i)==2^c for i in T])]
function code2typ(c::UInt8)
  t = Any::Type
  if c >= 0x80
    t = Array{code2typ(c-0x80)}
  elseif c >= 0x40
    t = Complex{code2typ(c-0x40)}
  elseif c >= 0x30
    t = findtype(c-0x2f, Array{Type,1}(subtypes(AbstractFloat)))
  elseif c >= 0x20
    t = findtype(c-0x20, Array{Type,1}(subtypes(Signed)))
  elseif c >= 0x10
    t = findtype(c-0x10, Array{Type,1}(subtypes(Unsigned)))
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
    m=0
    for i in K
      m+=1
      T = code2typ(read(io, UInt8))
      if T <: Array{String}
        D[i] = read_string_array(io)
      elseif T <: Array
        N = read(io, UInt8)
        d = tuple(read(io, Int64, N)[:]...)
        t = eltype(T)
        if t <: Complex
          τ = eltype(real(t))
          rr = read(io, τ, d)
          ii = read(io, τ, d)
          D[i] = rr + ii.*im
        else
          D[i] = read(io, t, d)
        end
      elseif T == String
        n = read(io, Int64)
        D[i] = join(String(read(io, UInt8, n)))
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
function r_seishdr(io::IOStream)
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
function r_seisdata(io::IOStream)
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
      rr = read(io, Float64, i64[2])
      ri = read(io, Float64, i64[2])
      S.resp[i] = reshape(complex(rr,ri), div(i64[2],2), 2)
    end

    # U8
    c = read(io, UInt8)
    y = read(io, UInt8)

    # U8 array
    S.id[i]   = strip(String(read(io, UInt8, 15)))
    S.units[i]= String(read(io, UInt8, i64[3]))
    S.src[i]  = String(read(io, UInt8, i64[4]))
    S.name[i] = String(read(io, UInt8, i64[5]))
    notes     = String(read(io, UInt8, i64[6]))
    xz         = read(io, UInt8, i64[7])
    S.misc[i] = read_misc(io)

    # Postprocessing
    Y = code2typ(y)
    S.x[i] = Array{Y,1}(i64[8])
    Blosc.decompress!(S.x[i], xz)
    if length(notes) > 0
      S.notes[i] = [String(j) for j in split(String(notes),Char(c))]
    else
      S.notes[i] = Array{String,1}()
    end
  end
  return S
end

r_seisevt(io::IOStream) = (
  S = SeisEvent();
  setfield!(S, :hdr, r_seishdr(io));
  setfield!(S, :data, r_seisdata(io));
  return S
  )


"""
    rseis(FNAME::String)

Read SeisIO file FNAME.

"""
function rseis(fname::String; v=false::Bool)
  io = open(fname, "r")
  c = String(read(io, UInt8, 6))
  c == "SEISIO" || (close(io); error("Not a SeisIO file!"))
  ver = read(io, Float32)
  L = read(io, Int64)
  T = String(read(io, UInt8, L))
  V = read(io, UInt64, L)
  A = Array{Union{SeisData,SeisChannel,SeisHdr,SeisEvent},1}()
  if v
    @printf(STDOUT, "Reading %i total objects from file %s.\n", L, fname)
  end
  for i = 1:1:L
    if T[i] == 'D'
      S = r_seisdata(io)
    elseif T[i] == 'H'
      S = r_seishdr(io)
    elseif T[i] == 'E'
      S = r_seisevt(io)
    end
    if v
      if i == L
        ei = position(io)
      else
        ei = V[i+1]
      end
      @printf(STDOUT, "Read type %s object, bytes %i:%i.\n", typeof(S), V[i], ei)
    end
    push!(A, S)
  end
  close(io)
  return A
end
