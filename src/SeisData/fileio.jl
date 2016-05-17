# to do: Consolidate write methods for seisobj, seisdata; too much cut-and-paste
import Base:write

"""
    wsac(S::SeisData; ts=false, v=true)

Write all data in S to auto-generated SAC files.
"""
function wsac(S::SeisData; ts=true, v=true)
  (sacFloatKeys,sacIntKeys, sacCharKeys) = get_sac_keys()
  if ts
    iftype = Float32(4); leven = Float32(0)
  else
    iftype = Float32(1); leven = Float32(1)
  end
  tdata = Array{Float32}(0)
  for i = 1:1:S.n
    # Initialize values
    sacFloatVals = Float32(-12345).*ones(Float32, 70)
    sacIntVals = Int32(-12345).*ones(Int32, 40)
    sacCharVals = repmat("-12345  ".data, 24)
    sacCharVals[17:24] = (" "^8).data

    # Prep time info
    t = u2d(S.t[i][1,2])
    y = parse(Int32, Dates.format(t, "yyyy"))
    m = parse(Int32, Dates.format(t, "mm"))
    d = parse(Int32, Dates.format(t, "dd"))
    j = Int32(md2j(y,m,d))
    H = parse(Int32, Dates.format(t, "H"))
    M = parse(Int32, Dates.format(t, "M"))
    sec = parse(Int32, Dates.format(t, "S"))
    ms = parse(Int32, Dates.format(t, "sss"))

    # Floats
    dt = 1/S.fs[i]
    sacFloatVals[1] = Float32(dt)
    sacFloatVals[4] = Float32(S.gain[i])
    sacFloatVals[6] = Float32(0)
    sacFloatVals[7] = Float32(dt*length(S.x[i]) + sum(S.t[i][2:end,2]))
    sacFloatVals[32] = S.loc[i][1]
    sacFloatVals[33] = S.loc[i][2]
    sacFloatVals[34] = S.loc[i][3]

    # Ints
    sacIntVals[1] = y
    sacIntVals[2] = j
    sacIntVals[3] = H
    sacIntVals[4] = M
    sacIntVals[5] = sec
    sacIntVals[6] = ms
    sacIntVals[7] = 6
    sacIntVals[10] = Int32(length(S.x[i]))
    sacIntVals[16] = iftype
    sacIntVals[36] = leven

    # Chars (ugh...)
    # Station name
    id = split(S.id[i],'.')
    st = ascii(id[2])
    L = length(st)
    sacCharVals[1:8] = cat(1, st.data, repmat(" ".data, 8-L))

    # Channel name
    ch = ascii(id[4])
    L = length(ch)
    sacCharVals[161:168] = cat(1, ch.data, repmat(" ".data, 8-L))

    # Network name
    nn = ascii(id[1])
    L = length(nn)
    sacCharVals[169:176] = cat(1, nn.data, repmat(" ".data, 8-L))

    # Guess filename
    fname = @sprintf("%04i.%03i.%02i.%02i.%02i.%04i.%s.%s..%s.R.SAC", y, j, H, M, sec, ms, nn, st, ch)

    # Data
    x = map(Float32, S.x[i])
    ts && (tdata = map(Float32, t_expand(S.t[i], dt)))

    # Write to file
    sacwrite(fname, sacFloatVals, sacIntVals, sacCharVals, x, t=tdata, ts=ts)
    v && @printf(STDOUT, "%s: Wrote file %s from SeisData channel %i\n", string(now()), fname, i)
  end
end

# Write methods
function writestr_fixlen(io::IOStream, s::AbstractString, L::Integer)
  o = (" "^L).data
  L = min(L, length(s))
  o[1:L] = s.data
  write(io, o)
  return
end

# I'm only allowing 12 types of values in misc; numeric arrays, string/char
# arrays, numeric values, and strings. Technically I could store these codes
# as a UInt12, but why hurt people like that?
function getnum(a)
  isa(a, Char) && return UInt8(1)
  isa(a, Unsigned) && return UInt8(2)
  isa(a, Integer) && return UInt8(3)
  isa(a, AbstractFloat) && return UInt8(4)
  isa(a, Complex) && return UInt8(5)
  typeof(a) <: DirectIndexString && return UInt8(6)

  # It is intentional that this syntax causes an error for non-arrays
  t = typeof(a[1])
  u = typeof(a[end])
  t == u || error("Mixed type arrays cannot be saved")
  t <: Char && return UInt8(11)
  t <: Unsigned && return UInt8(12)
  t <: Integer && return UInt8(13)
  t <: AbstractFloat && return UInt8(14)
  iscomplex(a[1]) && return UInt8(15)
  t <: DirectIndexString && return UInt8(16)
  error("Unrecognized type")
  # Who needs "switch"
end

function get_separator(s::AbstractString)
  for i in ['\,', '\\', '!', '\@', '\#', '\$', '\%', '\^', '\&', '\*', '\(',
    '\)', '\+', '\/', '\~', '\`', '\:', '\|']
    search(s, i) == 0 && return i
  end
  error("Couldn't set separator")
end

function write_string_array(io, v)
  nd = UInt8(ndims(v))
  d = collect(size(v))
  sep = get_separator(join(v))
  v = join(v, sep)
  write(io, sep, nd, d, length(v.data), v.data)
end

function write_misc(io::IOStream, D::Dict{ASCIIString,Any})
  P = position(io)
  isempty(D) && (write(io, Int64(0), position(io)+8); return)
  K = collect(keys(D))
  ksep = string(get_separator(join(K)))
  kstr = ""
  skip(io, 16)
  n_writes = 0
  for (i,k) in enumerate(K)
    v = D[k]
    p = position(io)
    #println("Beginning write at ", position(io), " for key ", k)
    try
      id = getnum(v)
      write(io, id)
      id == 1 && write(io, v)
      Base.in(id,2:4) && write(io, UInt8(sizeof(v)), v)
      id == 5 && write(io, UInt8(sizeof(v)), real(v), imag(v))
      id == 6 && write(io, length(v), v.data)

      id == 11 && write(io, UInt8(ndims(v)), collect(size(v)), v)
      Base.in(id,12:14) && write(io, UInt8(sizeof(v[1])), UInt8(ndims(v)),
        collect(size(v)), v)
      id == 15 && write(io, UInt8(sizeof(v[1])/2), UInt8(ndims(v)),
        collect(size(v)), real(v), imag(v))
      id == 16 && write_string_array(io, v)
      kstr *= k
      kstr *= ksep
      n_writes += 1
    catch err
      warn(err)
      seek(io, p)
    end
  end
  Q = position(io)
  seek(io, P)
  write(io, n_writes, Q)
  seek(io, Q)
  kstr = kstr[1:end-1]
  write(io, ksep, length(kstr), kstr)
  #println("Wrote ", n_writes, " items from misc.")
  #println(kstr)
  return
end

function whdr(io, n::Integer)
  write(io, "SEISDATA".data)    # it's seisdata
  write(io, UInt8(0))           # version
  write(io, UInt32(n))          # number of SeisData objects to be written
end

function write(io::IOStream, S::SeisData)
  write(io, S.n)
  for i = 1:S.n
    name = writestr_fixlen(io, S.name[i], 26)                           # name
    id = writestr_fixlen(io, S.id[i], 15)                               # id
    src = writestr_fixlen(io, S.id[i], 26)                              # src
    write(io, S.fs[i])                                                  # fs
    write(io, S.gain[i])                                                # gain
    units = writestr_fixlen(io, S.units[i], 26)                         # units
    if !isempty(S.loc[i])                                               # loc
      write(io, S.loc[i])
    else
      skip(io, 40)
    end
    R = 2*size(S.resp[i],1)                                             # resp
    write(io, UInt8(R))
    R > 0 && write(io, real(S.resp[i][:]), imag(S.resp[i][:]))
    write_misc(io, S.misc[i])                                           # misc
    write_string_array(io, S.notes[i])                                  # notes
    T = size(S.t[i],1)                                                  # t
    write(io, T)
    T > 0 && write(io, S.t[i])
    X = size(S.x[i],1)                                                  # x
    write(io, X)
    X > 0 && write(io, S.x[i])
  end
end

function write(io::IOStream, S::SeisObj)
  write(io, Int64(1))
  name = writestr_fixlen(io, S.name, 26)                           # name
  id = writestr_fixlen(io, S.id, 15)                               # id
  src = writestr_fixlen(io, S.id, 26)                              # src
  write(io, S.fs)                                                  # fs
  write(io, S.gain)                                                # gain
  units = writestr_fixlen(io, S.units, 26)                         # units
  if !isempty(S.loc)                                               # loc
    write(io, S.loc)
  else
    write(io, [0.0,0.0,0.0,0.0,0.0])
  end
  R = 2*size(S.resp,1)                                             # resp
  write(io, UInt8(R))
  R > 0 && write(io, real(S.resp[:]), imag(S.resp[:]))
  write_misc(io, S.misc)                                           # misc
  write_string_array(io, S.notes)                                  # notes
  T = size(S.t,1)                                                  # t
  write(io, T)
  T > 0 && write(io, S.t)
  X = size(S.x,1)                                                  # x
  write(io, X)
  X > 0 && write(io, S.x)
end

"""
    wseis(S, f)

Write SeisData or SeisObj structure `S` to file `f`.
"""
wseis(f::ASCIIString, S::SeisData) = (fid = open(f, "w"); whdr(fid, 1);
  write(fid, S); close(fid))
wseis(S::SeisData, f::ASCIIString) = wseis(f::ASCIIString, S::SeisData)
wseis(f::ASCIIString, S::SeisObj) = (fid = open(f, "w"); whdr(fid, 1);
  write(fid, S); close(fid))
wseis(S::SeisObj, f::ASCIIString) = wseis(f::ASCIIString, S::SeisObj)
function wseis(f::ASCIIString, S...)
  L = length(S)
  fid = open(f, "w")
  skip(fid, 13)
  n = 0
  for i = 1:L
    if isa(S[i], Union{SeisData,SeisObj})
      write(fid, S[i])
      n+=1
    else
      warn(@sprintf("Incompatible object passed to wseis (arg %i); skipped", i))
    end
  end
  seekstart(fid)
  whdr(fid, n)
  close(fid)
end

# Read methods
function read_string_array(io)
  #println("Beginning read at ", position(io))
  sep = Char(read(io, UInt8))
  nd = read(io, UInt8)
  d = read(io, Int64, nd)
  l = read(io, Int64)
  A = reshape(collect(split(ascii(read(io, UInt8, l)), sep)), tuple(d[:]...))
  #println(A[1])
  return A
end

function read_misc(io::IOStream)
  n_reads = read(io, Int64)
  D = Dict{ASCIIString,Any}()
  n_reads == 0 && (skip(io, 8); return D)
  Q = read(io, Int64)
  P = position(io)
  seek(io, Q)
  ksep = Char(read(io, UInt8))
  N = read(io, Int64)
  kstr = ascii(read(io, UInt8, N))
  K = split(kstr, ksep)
  Q = position(io)
  seek(io, P)
  for nnn = 1:n_reads
    #println("Beginning read at ", position(io), " for key ", K[nnn])
    id = read(io, UInt8)
    id == 1 && (v = read(io, Char))
    if id == 2
      p == 1 && (v = read(io, UInt8))
      p == 2 && (v = read(io, UInt16))
      p == 4 && (v = read(io, UInt32))
      p == 8 && (v = read(io, UInt64))
      p == 16 && (v = read(io, UInt128))
    end
    if id == 3
      p == 1 && (v = read(io, Int8))
      p == 2 && (v = read(io, Int16))
      p == 4 && (v = read(io, Int32))
      p == 8 && (v = read(io, Int64))
      p == 16 && (v = read(io, Int128))
    end
    if id == 4
      p == 2 && (v = read(io, Float16))
      p == 4 && (v = read(io, Float32))
      p == 8 && (v = read(io, Float64))
    end
    if id == 5
      p == 4 && (r = read(io, Float16); i = read(io, Float16))
      p == 8 && (r = read(io, Float32); i = read(io, Float32))
      p == 16 && (r = read(io, Float32); i = read(io, Float64))
      v = complex(r,i)
    end
    id == 6 && (l = read(io, Int64); v = ascii(read(io, UInt8, l)))

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
      p == 2 && (v = read(io, Float16, tuple(d[:]...)))
      p == 4 && (v = read(io, Float32, tuple(d[:]...)))
      p == 8 && (v = read(io, Float64, tuple(d[:]...)))
    end
    if id == 15
      p == 2 && (r = read(io, Float16, tuple(d[:]...));
        i = read(io, Float16, tuple(d[:]...)))
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

function r_seisobj(io::IOStream)
  name = strip(ascii(read(io, UInt8, 26)))
  id = strip(ascii(read(io, UInt8, 15)))
  src = strip(ascii(read(io, UInt8, 26)))
  fs = read(io, Float64)
  gain = read(io, Float64)
  units = strip(ascii(read(io, UInt8, 26)))
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
    ti = read(io, Float64, T)
    tv = read(io, Float64, T)
    t = [ti tv]
  else
    t = Array{Float64,2}()
  end
  X = read(io, Int64)
  if X > 0
    x = read(io, Float64, X)
  else
    x = Array{Float64,1}()
  end
  T = SeisObj(name=name, id=id, fs=fs, gain=gain, units=units, loc=loc,
    resp=resp, misc=misc, notes=notes, t=t, x=x)
  return T
end

function rseis(fname::ASCIIString; v=false::Bool)
  io = open(fname, "r")
  c = ascii(read(io, UInt8, 8))
  c == "SEISDATA" || (close(io); error("Not a SeisData file!"))
  ver = read(io, UInt8)
  n_seis = read(io, UInt32)
  if v
    println("SeisData version = ", ver)
    println("SeisData objects to read = ", n_seis)
  end
  S = Array{Union{SeisData,SeisObj}}(n_seis)
  for i = 1:n_seis
    n_chan = read(io, Int64)
    v && println("To read: ", n_chan, " channels")
    if n_chan == 1
      s = r_seisobj(io)
    else
      s = SeisData()
      for n = 1:n_chan
        push!(s, r_seisobj(io), n=false)
        v && println("...read ", n, "/", n_chan)
      end
    end
    S[i] = deepcopy(s)
    v && println("...done ", i, "/", n_seis, " (", round(Int,
      position(io)/1024), "kB read)")
  end
  close(io)
  if n_seis == 1
    return S[1]
  else
    return S
  end
end
