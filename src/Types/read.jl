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
  nd = read(io, UInt8)
  if nd > 0
    sep = Char(read(io, UInt8))
    d = read(io, Int64, nd)
    l = read(io, Int64)
    A = reshape(collect(split(String(read(io, UInt8, l)), sep)), tuple(d[:]...))
    return A
  else
    return Array{String,1}()
  end
end

# ID codes and their meanings
# 1 	  Char
# 2     UInt (*)
# 3     Int (*)
# 4     Float (*)
# 5     Complex Float (*)
# 6     String
# 11 	  Array of Chars
# 12    Array of UInts (*)
# 13    Array of Ints (*)
# 14    Array of Floats (*)
# 15    Complex Array of Complex Float (*)
# 16    Array of Strings
#
# (*)   subcode stored as variable p = precision, in bytes
function read_misc(io::IOStream)
  n_reads = read(io, Int64)
  D = Dict{String,Any}()
  n_reads == 0 && (skip(io, 8); return D)
  Q = read(io, Int64)
  P = position(io)
  seek(io, Q)
  ksep = Char(read(io, UInt8))
  N = read(io, Int64)
  kstr = String(read(io, UInt8, N))
  K = split(kstr, ksep)
  Q = position(io)
  seek(io, P)
  for nnn = 1:n_reads
    #println("Beginning read at ", position(io), " for key ", K[nnn])
    id = read(io, UInt8)
    id == 1 && (v = read(io, Char))
    if id == 2
      # wtf is p?
      p = read(io, UInt8)
      p == 1 && (v = read(io, UInt8))
      p == 2 && (v = read(io, UInt16))
      p == 4 && (v = read(io, UInt32))
      p == 8 && (v = read(io, UInt64))
      p == 16 && (v = read(io, UInt128))
    end
    if id == 3
      p = read(io, UInt8)
      p == 1 && (v = read(io, Int8))
      p == 2 && (v = read(io, Int16))
      p == 4 && (v = read(io, Int32))
      p == 8 && (v = read(io, Int64))
      p == 16 && (v = read(io, Int128))
    end
    if id == 4
      p = read(io, UInt8)
      p == 4 && (v = read(io, Float32))
      p == 8 && (v = read(io, Float64))
    end
    if id == 5
      p = read(io, UInt8)
      p == 8 && (r = read(io, Float32); i = read(io, Float32))
      p == 16 && (r = read(io, Float32); i = read(io, Float64))
      v = complex(r,i)
    end
    id == 6 && (l = read(io, Int64); v = String(read(io, UInt8, l)))

    id == 11 && (nd = read(io, UInt8); d = read(io, Int64, nd);
      v = read(io, Char, tuple(d[:]...)))
    if Base.in(id, 12:15)
      p = read(io, UInt8)
      nd = read(io, UInt8)
      d = read(io, Int64, Int(nd))
    end
    if id == 12
      p == 1 && (v = read(io, UInt8, tuple(d[:]...)))
      p == 2 && (v = read(io, UInt16, tuple(d[:]...)))
      p == 4 && (v = read(io, UInt32, tuple(d[:]...)))
      p == 8 && (v = read(io, UInt64, tuple(d[:]...)))
      p == 16 && (v = read(io, UInt128, tuple(d[:]...)))
    end
    if id == 13
      p == 1 && (v = read(io, Int8, tuple(d[:]...)))
      p == 2 && (v = read(io, Int16, tuple(d[:]...)))
      p == 4 && (v = read(io, Int32, tuple(d[:]...)))
      p == 8 && (v = read(io, Int64, tuple(d[:]...)))
      p == 16 && (v = read(io, Int128, tuple(d[:]...)))
    end
    if id == 14
      p == 4 && (v = read(io, Float32, tuple(d[:]...)))
      p == 8 && (v = read(io, Float64, tuple(d[:]...)))
    end
    if id == 15
      p == 4 && (r = read(io, Float32, tuple(d[:]...));
        i = read(io, Float32, tuple(d[:]...)))
      p == 8 && (r = read(io, Float64, tuple(d[:]...));
        i = read(io, Float64, tuple(d[:]...)))
      v = complex(r,i)
    end
    id == 16 && (v = read_string_array(io))
    D[K[nnn]] = v
    end
  seek(io, Q)
  return D
end

# ===========================================================================
# r_struct methods

# SeisHdr
function r_seishdr(io::IOStream)
  S = SeisHdr()
  setfield!(S, :id, read(io, Int64))
  setfield!(S, :time, u2d(read(io, Int64)/1.0e6))
  for i in [:lat, :lon, :dep]
    setfield!(S, i, read(io, Float64))
  end
  setfield!(S, :mag, read(io, Float32))
  setfield!(S, :contrib_id, read(io, Int64))
  for i in [:mag_auth, :auth, :cat, :contrib, :loc_name]
    setfield!(S, i, readstr_varlen(io))
  end
  return S
end

# SeisData, SeisChannel
function r_seisdata(io::IOStream)
  S = SeisData()
  N = convert(Int64, read(io, UInt32))
  for n = 1:1:N
    name = strip(String(read(io, UInt8, 26)))
    id = strip(String(read(io, UInt8, 15)))
    src = strip(String(read(io, UInt8, 26)))
    fs = read(io, Float64)
    gain = read(io, Float64)
    units = strip(String(read(io, UInt8, 26)))
    loc = read(io, Float64, 5)
    R = read(io, UInt8)
    if R > 0
      rr = read(io, Float64, R)
      ri = read(io, Float64, R)
      resp = reshape(complex(rr,ri), Int(R/2), 2)
    else
      resp = Array{Complex{Float64},2}(0, 2)
    end
    misc = read_misc(io)
    notes = read_string_array(io)
    T = read(io, Int64)
    if T > 0
      if fs > 0.0
        ti = read(io, Int64, T)
        tv = read(io, Int64, T)
        t = [ti tv]
      else
        t = reshape(read(io, Int64, T), T, 1)
      end
    else
      t = Array{Int64,2}()
    end
    X = read(io, Int64)
    if X > 0
      x = read(io, Float64, X)
    else
      x = Array{Float64,1}()
    end
    S += SeisChannel(name=name, id=id, fs=fs, gain=gain, units=units, loc=loc, resp=resp, misc=misc, notes=notes, t=t, x=x)
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
  L = read(io, UInt64)
  T = String(read(io, UInt8, L))
  V = read(io, UInt64, L)
  A = Array{Any,1}()
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
  if L == 1
    return A[1]
  else
    return A
  end
end
