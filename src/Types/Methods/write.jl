export wseis
Blosc.set_compressor("blosclz")
Blosc.set_num_threads(Sys.CPU_THREADS)

# SeisIO file format version changes
# 0.5 :loc, :resp are now custom types with their own io subroutines
#     Julia version is no longer written to file
# 0.4 SeisData.id[i] no longer needs to be a length ≤ 15 ASCII string
#     seis files have a new file TOC field: number of channels in each record
# 0.3 SeisData.loc[i] no longer is assumed to be length 5
# 0.2 First stable

# ===========================================================================
# Auxiliary file write functions
sa2u8(s::Array{String,1}) = map(UInt8, collect(join(s,'\0')))

function get_separator(s::String)
    for i = 0x00:0x01:0xff
        c = Char(i)
        occursin(c, s) == false && return(c)
    end
    error("No valid separators!")
end


# ============================================================================
# Write functions

function write_string_array(io, v::Array{String})
  nd = UInt8(ndims(v))
  d = Array{Int64, 1}(collect(size(v)))
  write(io, nd, d)
  if d != [0]
    sep = get_separator(join(v))
    vstr = join(v, sep)
    u = UInt8.(codeunits(vstr))
    write(io, UInt8(sep), Int64(length(u)), u)
  end
end

write_misc_val(io::IOStream, K::Union{Char,AbstractFloat,Integer}) = write(io, K)
write_misc_val(io::IOStream, K::Complex) = write(io, real(K), imag(K))
write_misc_val(io::IOStream, K::String) = (u = UInt8.(codeunits(K)); write(io, Int64(length(u))); write(io, u))
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
    karr = UInt8.(codeunits(join(K, keysep)))
    l = Int64(length(karr))
    write(io, l)
    write(io, keysep)
    write(io, karr)
    for i in K
      c = typ2code(typeof(D[i]))
      write(io, c)
      write_misc_val(io, D[i])
    end
  end
  return
end

# ===========================================================================
# write methods

# SeisData
function w_struct(io::IOStream, S::T) where {T<:GphysData}
  write(io, UInt32(S.n))
  if T == EventTraceData
    write(io, 0x01)
  else
    write(io, 0x00)
  end
  x = Array{UInt8,1}(undef, max(0, maximum([sizeof(S.x[i]) for i=1:S.n])))
  for i = 1:S.n
    c = get_separator(join(S.notes[i]))
    X = getindex(getfield(S, :x), i)
    Loc = getindex(getfield(S, :loc), i)
    Resp = getindex(getfield(S, :resp), i)

    # compress X
    l = Blosc.compress!(x, X, level=9)
    if l == 0
      @warn(string("Compression ratio > 1.0 for channel ", i, "; are data OK?"))
      x = Blosc.compress(X, level=9)
      l = length(x)
    end

    id    = codeunits(S.id[i])
    notes = codeunits(join(S.notes[i], c))
    units = codeunits(S.units[i])
    src   = codeunits(S.src[i])
    name  = codeunits(S.name[i])

    # Int
    write(io, length(S.t[i]))
    write(io, length(units))
    write(io, length(src))
    write(io, length(name))
    write(io, length(notes))
    write(io, l)
    write(io, length(S.x[i]))
    write(io, length(S.id[i]))

    # Int array
    write(io, S.t[i][:])

    # Float
    write(io, S.fs[i])
    write(io, S.gain[i])

    # U8
    write(io, UInt8(c))
    write(io, typ2code(eltype(X)))
    write(io, loctype2code(Loc))
    write(io, resptype2code(Resp))

    # U8 array
    write(io, id)
    write(io, units)
    write(io, src)
    write(io, name)
    write(io, notes)
    write(io, x[1:l])

    # loc
    writeloc(io, Loc)

    # resp
    write_resp(io, Resp)

    # misc
    write_misc(io, S.misc[i])

    # Additional things for EventTraceData
    if T == EventTraceData
      write(io, S.az[i])
      write(io, S.baz[i])
      write(io, S.dist[i])
      write(io, S.pha[i])
    end
  end
end

# SeisHdr
function w_struct(io::IOStream, H::SeisHdr)
  m = getfield(H, :mag)                             # magnitude
  i = getfield(H, :int)                             # intensity
  s = map(UInt8, collect(getfield(H, :src)))        # source string as char array
  a = getfield(H, :notes)
  mt = getfield(H, :mt); L_mt = length(mt)
  ax = getfield(H, :axes); L_ax = 3*length(ax)

  c = Char('\0')
  n = Array{UInt8,1}(undef,0)
  if !isempty(a)
      c = get_separator(join(a))                    # this should always be true
      n = map(UInt8, collect(join(a,c)))            # notes as UInt8 array
  end
  j = codeunits(i[2])                               # magnitude scale as char array
  k = codeunits(m[2])                               # intensity scale as char array

  loc = getfield(H, :loc)

  # Write begins here -------------------------------------------------------
  # 8 Int64
  write(io, getfield(H, :id))                               # numeric event ID, already an Int64
  write(io, round(Int64, d2u(getfield(H, :ot))*1.0e6))      # event ot in integer μs from Unix epoch
  write(io, Int64(length(k)))                               # length of magnitude scale string
  write(io, Int64(length(j)))                               # length of intensity scale string
  write(io, Int64(length(s)))                               # length of src string
  write(io, Int64(length(n)))                               # length of joined notes string
  write(io, Int64(L_mt))                                    # length of moment tensor vector
  write(io, Int64(L_ax))                                    # length of moment tensor vector

  # 1 Float32
  write(io, m[1])                                           # mag

  # Float64s (Moment Tensor, Axes)
  if L_mt > 0
    write(io, mt)                                           # mt
  end
  if L_ax > 0
    write(io, ax)                                           # ax
  end

  # 2 + length(k) + length(j) + length(s) + length(n) UInt8s
  write(io, c, i[1])

  # 4 UInt8 arrays
  write(io, k)          # mag scale chars
  write(io, j)          # int scale chars
  write(io, s)          # source string chars
  if !isempty(a)
      write(io, n)      # notes chars
  end

  # Loc
  writeloc(io, loc)     # SeisHdr only allows GeoLoc in :loc

  # Misc
  write_misc(io, getfield(H, :misc))
end

# SeisEvent
w_struct(io::IOStream, S::SeisEvent) = (w_struct(io, S.hdr); w_struct(io, S.data))

# ===========================================================================
# functions that invoke w_struct()
"""
    wseis(fname, S)

Write SeisIO objects S to file. S can be a single object, multiple comma-delineated objects, or an array of objects.
"""
function wseis(fname::String, S...)
    L = Int64(length(S))
    (L == 0) && return

    # check that everything in S is a valid SeisIO object
    b = falses(L)
    for i = 1:L
        b[i] = (typeof(S[i]) <: Union{SeisData,SeisChannel,SeisHdr,SeisEvent})
        if b[i] == false
            @warn(string("Object of incompatible type passed to wseis at ", i, "; skipped!"))
        end
    end
    S = S[b]
    L = Int64(length(S))

    # open file for writing
    C = Array{UInt8,1}(undef,L)                                   # Codes
    B = zeros(UInt64, L)                                          # Byte indices
    Nc = zeros(Int64, L)                                          # Number of channels
    ID = Array{UInt8,1}()                                         # IDs
    TS = Array{Int64,1}()                                         # Start times
    TE = Array{Int64,1}()                                         # End times

    # fname → IO stream
    io = open(fname, "w")
    write(io, map(UInt8, collect("SEISIO")))
    write(io, vSeisIO)
    write(io, L)
    p = position(io)
    skip(io, sizeof(C) + sizeof(B) + sizeof(Nc))

    # Write all objects
    for i = 1:L
        seis = (typeof(S[i]) == SeisChannel) ? SeisData(S[i]) : S[i]
        B[i] = UInt64(position(io))
        seis = (typeof(S[i]) == SeisChannel) ? SeisData(S[i]) : S[i]
        if typeof(seis) == SeisData
            C[i] = UInt8('D')
            id = sa2u8(seis.id)
            ts, te = mk_end_times(seis)
            Nc[i] = seis.n
        elseif typeof(seis) == SeisHdr
            C[i] = UInt8('H')
            id = Array{UInt8,1}()
            ts = Array{Int64,1}()
            te = Array{Int64,1}()
        elseif typeof(seis) == SeisEvent
            C[i] = UInt8('E')
            id = sa2u8(seis.data.id)
            ts, te = mk_end_times(seis.data)
            Nc[i] = seis.data.n
        end
        append!(TS, ts)
        append!(TE, te)
        append!(ID, id)
        w_struct(io, seis)
        if i < L
            push!(ID, 0x0a)
        end
    end

    # Write TOC.
    # format: array of object types, array of byte indices, array of number of channels in each record
    seek(io, p)
    write(io, C)
    write(io, B)
    write(io, Nc)

    # File appendix added 2017-02-23
    # appendix format: ID, TS, TE, position(ID), position(TS), position(TE)
    seekend(io)
    x = Int64(position(io)); write(io, ID)
    y = Int64(position(io)); write(io, TS)
    z = Int64(position(io)); write(io, TE)
    write(io, x, y, z)
    close(io)
end
