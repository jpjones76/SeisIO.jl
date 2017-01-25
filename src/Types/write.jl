vSeisIO() = Float32(0.2)
Blosc.set_compressor("blosclz")

# ===========================================================================
# Auxiliary file write functions

function writestr_fixlen(io::IOStream, s::String, L::Integer)
  o = (" "^L).data
  L = min(L, length(s))
  o[1:L] = s.data
  write(io, o)
  return
end

function writestr_varlen(io::IOStream, s::String)
  L = Int64(length(s))
  write(io, L)
  if L > 0
    write(io, s.data)
  end
  return
end

# allowed values in misc: char, string, numbers, and arrays of same.
tos(t::Type) = round(Int, log2(sizeof(t)))
function typ2code(t::Type)
  n = 0xff
  if t == Char
    n = 0x00
  elseif t == String
    n = 0x01
  elseif t <: Unsigned
    n = 0x10 + tos(t)
  elseif t <: Signed
    n = 0x20 + tos(t)
  elseif t <: AbstractFloat
    n = 0x30 + tos(t)-1
  elseif t <: Complex
    n = 0x40 + typ2code(real(t))
  elseif t <: Array
    n = 0x80 + typ2code(eltype(t))
  end
  return UInt8(n)
end
# Who needs "switch"...

function get_separator(s::String)
  for i = 0x00:0x01:0xff
    if search(s, Char(i)) == 0
      return Char(i)
    end
  end
  return '\n'
end

function write_string_array(io, v::Array{String})
  nd = UInt8(ndims(v))
  d = Array{Int64,1}(collect(size(v)))
  write(io, nd, d)
  if d != [0]
    sep = get_separator(join(v))
    vstr = join(v, sep)
    write(io, UInt8(sep), Int64(length(vstr.data)), vstr.data)
  end
end
write_string_array(io, v::String) = write_string_array(io, String[v])

write_misc_val(io::IOStream, K::Union{Char,AbstractFloat,Integer}) = write(io, K)
write_misc_val(io::IOStream, K::Complex) = write(io, real(K), imag(K))
write_misc_val(io::IOStream, K::String) = (write(io, Int64(length(K))); write(io, K))
function write_misc_val(io::IOStream, V::Union{Array{Integer},Array{AbstractFloat},Array{Char}})
  write(io, UInt8(ndims(V)))
  write(io, map(Int64, collect(size(V))))
  write(io, V)
end
function write_misc_val(io::IOStream, V::AbstractArray)
  write(io, UInt8(ndims(V)))
  write(io, map(Int64, collect(size(V))))
  if isreal(V)
    write(io, V)
  else
    write(io, real(V))
    write(io, imag(V))
  end
end
write_misc_val(io::IOStream, V::Array{String}) = write_string_array(io, V)

function write_misc(io::IOStream, D::Dict{String,Any})
  K = sort(collect(keys(D)))
  L = Int64(length(K))
  write(io, L)
  if !isempty(D)
    keysep = get_separator(join(K))
    kstr = join(K, keysep)
    l = Int64(length(kstr))
    write(io, l)
    write(io, keysep)
    write(io, kstr)
    [(write(io, typ2code(typeof(D[i]))); write_misc_val(io, D[i])) for i in K]
  end
  return
end

# ===========================================================================
# write methods

# SeisData
function w_struct(io::IOStream, S::SeisData)
  write(io, UInt32(S.n))
  for i = 1:1:S.n
    c = get_separator(join(S.notes[i]))
    r = length(S.resp[i])
    x = Blosc.compress(S.x[i])
    notes = join(S.notes[i], c)
    units = S.units[i].data
    src   = S.src[i].data
    name  = S.name[i].data

    # Int
    write(io, length(S.t[i]))
    write(io, r)
    write(io, length(units))
    write(io, length(src))
    write(io, length(name))
    write(io, length(notes))
    write(io, length(x))
    write(io, length(S.x[i]))

    # Int array
    write(io, S.t[i][:])

    # Float
    write(io, S.fs[i])
    write(io, S.gain[i])

    # Float arrays
    if isempty(S.loc[i]) == true
      write(io, zeros(Float64, 5))
    else
      write(io, S.loc[i])
    end
    if r > 0
      write(io, real(S.resp[i][:]))
      write(io, imag(S.resp[i][:]))
    end

    # U8
    write(io, UInt8(c))
    write(io, typ2code(eltype(S.x[i])))

    # U8 array
    writestr_fixlen(io, S.id[i], 15)
    write(io, units)
    write(io, src)
    write(io, name)
    write(io, notes)
    write(io, x)

    write_misc(io, S.misc[i])
  end
end

# SeisHdr
function w_struct(io::IOStream, H::SeisHdr)
  m = getfield(H, :mag)
  i = getfield(H, :int)
  s = getfield(H, :src).data
  a = getfield(H, :notes)
  c = get_separator(join(a))
  n = join(a,c).data
  j = i[2].data

  # int
  write(io, getfield(H, :id))                               # id
  write(io, Int64(round(d2u(getfield(H, :ot))*1.0e6)))      # ot
  write(io, Int64(length(j)))                               # length of intensity scale string
  write(io, Int64(length(s)))                               # length of src string
  write(io, Int64(length(n)))                               # length of joined notes string

  # float arrays/tuples
  write(io, m[1])                                           # mag
  write(io, getfield(H, :loc))                              # loc
  write(io, getfield(H, :mt))                               # mt
  write(io, getfield(H, :np))                               # np
  write(io, getfield(H, :pax))                              # pax

  # UInt8s
  write(io, UInt8(m[2]), UInt8(m[3]), c, i[1])

  # UInt8 arrays
  write(io, j)
  write(io, s)
  write(io, n)

  # Misc
  write_misc(io, H.misc)
end

# SeisChannel
w_struct(io::IOStream, S::SeisChannel) = write(io, SeisData(S))

# SeisEvent
w_struct(io::IOStream, S::SeisEvent) = (w_struct(io, S.hdr); w_struct(io, S.data))

# ===========================================================================
# functions that invoke w_struct()
"""
    wseis(f, S)

Write SeisIO data structure(s) `S` to file `f`.
"""
function wseis(f::String, S...)
  U = Union{SeisData,SeisChannel,SeisHdr,SeisEvent}
  L = Int64(length(S))
  (L == 0) && return
  T = Array(UInt8, L)
  V = zeros(UInt64, L)
  fid = open(f, "w")

  # Write begins
  write(fid, "SEISIO".data)
  write(fid, vSeisIO())
  write(fid, L)
  skip(fid, 9*L)            # Leave blank space for an index at the start of the file

  for i = 1:L
    if !(typeof(S[i]) <: U)
      warn(string("Object of incompatible type passed to wseis at ",i+1,"; skipped!"))
    else
      V[i] = Int64(position(fid))
      if typeof(S[i]) == SeisChannel
        seis = SeisData(S[i])
      else
        seis = S[i]
      end
      if typeof(S[i]) == SeisData
        T[i] = UInt8('D')
      elseif typeof(S[i]) == SeisHdr
        T[i] = UInt8('H')
      elseif typeof(S[i]) == SeisEvent
        T[i] = UInt8('E')
      end
      w_struct(fid, seis)
    end
  end
  seek(fid, 18)

  # Index format: array of object types, array of byte indices
  write(fid, T)
  write(fid, V)
  close(fid)
end
wseis(S::Union{SeisData,SeisChannel,SeisHdr,SeisEvent}, f::String) = wseis(f, S)
