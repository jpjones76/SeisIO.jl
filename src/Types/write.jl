# to do: Consolidate write methods for seisobj, seisdata; too much cut-and-paste
import Base:write

vSeisIO() = Float32(0.1)

# ===========================================================================
# Auxiliary file write functions
function writestr_fixlen(io::IOStream, s::AbstractString, L::Integer)
  o = (" "^L).data
  L = min(L, length(s))
  o[1:L] = s.data
  write(io, o)
  return
end

function writestr_varlen(io::IOStream, s::AbstractString)
  L = length(s)
  write(io, L)
  if L > 0
    write(io, s.data)
  end
  return
end

# I'm only allowing 12 types of values in misc; numeric arrays, string/char
# arrays, numeric values, and strings. Technically I could store these codes
# as a UInt12, but why hurt peoples' heads like that?
function getnum(a)
  isa(a, Char) && return UInt8(1)
  isa(a, Unsigned) && return UInt8(2)
  isa(a, Integer) && return UInt8(3)
  isa(a, AbstractFloat) && return UInt8(4)
  isa(a, Complex) && return UInt8(5)
  typeof(a) <: AbstractString && return UInt8(6)

  # It is intentional that this syntax causes an error for non-arrays
  t = typeof(a[1])
  u = typeof(a[end])
  t == u || error("Mixed type arrays cannot be saved")
  t <: Char && return UInt8(11)
  t <: Unsigned && return UInt8(12)
  t <: Integer && return UInt8(13)
  t <: AbstractFloat && return UInt8(14)
  isa(a[1],AbstractString) || return UInt8(15)
  t <: AbstractString && return UInt8(16)
  error("Unrecognized type")

  # Who needs "switch"
end

function get_separator(s::String)
  for i in ['\,', '\\', '!', '\@', '\#', '\$', '\%', '\^', '\&', '\*', '\(',
    '\)', '\+', '\/', '\~', '\`', '\:', '\|']
    if search(s, i) == 0
      return i
    end
  end
  error("Couldn't set separator")
end

function write_string_array(io, v::Array{String})
  nd = UInt8(ndims(v))
  if nd > 0
    d = collect(size(v))
    sep = get_separator(join(v))
    v = join(v, sep)
    write(io, nd, sep, d, length(v.data), v.data)
  else
    write(io, 0)
  end
end
write_string_array(io, v::String) = write_string_array(io, [v])

function write_misc(io::IOStream, D::Dict{String,Any})
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
      warn("Failed to write data from Misc. Screen dump of bad data follows.")
      println("Key = ", k)
      println("Value = ", D[k])
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

# ===========================================================================
# write methods

# SeisData
function w_struct(io::IOStream, S::SeisData)
  write(io, UInt32(S.n))
  for i = 1:S.n
    writestr_fixlen(io, S.name[i], 26)                                # name
    writestr_fixlen(io, S.id[i], 15)                                  # id
    writestr_fixlen(io, S.src[i], 26)                                 # src
    write(io, S.fs[i])                                                # fs
    write(io, S.gain[i])                                              # gain
    writestr_fixlen(io, S.units[i], 26)                               # units
    if !isempty(S.loc[i])
      write(io, S.loc[i])                                             # loc
    else
      write(io, zeros(Float64, 5))
    end
    R = 2*size(S.resp[i],1)                                           # resp
    write(io, UInt8(R))
    if R > 0
      write(io, real(S.resp[i][:]), imag(S.resp[i][:]))
    end
    write_misc(io, S.misc[i])                                         # misc
    write_string_array(io, S.notes[i])                                # notes
    L = size(S.t[i],1)                                                # t
    write(io, L)
    if L > 0
      write(io, S.t[i])
    end
    L = size(S.x[i],1)                                                # x
    write(io, L)
    if L > 0
      write(io, S.x[i])
    end
  end
end

# SeisHdr
function w_struct(io::IOStream, S::SeisHdr)
  write(io, getfield(S, :id))                               # id
  write(io, Int64(round(d2u(S.time)*1.0e6)))                # ot
  write(io, S.lat, S.lon, S.dep)                            # loc
  write(io, getfield(S, :mag))                              # mag
  write(io, getfield(S, :contrib_id))
  for i in [:mag_auth, :auth, :cat, :contrib, :loc_name]
    writestr_varlen(io, getfield(S, i))
  end
end

# SeisChannel
w_struct(io::IOStream, S::SeisChannel) = write(io, SeisData(S))

# SeisEvent
w_struct(io::IOStream, S::SeisEvent) = (H = deepcopy(S.hdr); D = deepcopy(S.data); w_struct(io, H); w_struct(io, D))

# ===========================================================================
# functions that invoke w_struct()
"""
    wseis(f, S)

Write SeisIO data structure(s) `S` to file `f`.
"""
function wseis(f::String, S...)
  U = Union{SeisData,SeisChannel,SeisHdr,SeisEvent}
  L = UInt64(length(S))
  for i = 1:L
    if !(typeof(S[i]) <: U)
      error(@printf("Object of incompatible type passed to wseis at %i; exit with error!", i+1))
    end
  end
  T = Array(UInt8, L)
  V = zeros(UInt64, L)
  fid = open(f, "w")

  # Write begins
  write(fid, "SEISIO".data)
  write(fid, vSeisIO())
  write(fid, L)
  skip(fid, 9*L)            # Leave blank space for an index at the start of the file

  for i = 1:L
    V[i] = position(fid)
    if typeof(S[i]) <: Union{SeisData,SeisChannel}
      T[i] = UInt8('D')
    elseif typeof(S[i]) == SeisHdr
      T[i] = UInt8('H')
    elseif typeof(S[i]) == SeisEvent
      T[i] = UInt8('E')
    end
    w_struct(fid, S[i])
  end
  seek(fid, 18)

  # Index format: array of object types, array of byte indices
  write(fid, T)
  write(fid, V)
  close(fid)
end
wseis(S::Union{SeisData,SeisChannel,SeisHdr,SeisEvent}, f::String) = wseis(f, S)
