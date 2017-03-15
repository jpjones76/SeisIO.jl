vSeisIO() = Float32(0.2)
vJulia() = parse(Float32, string(VERSION.major,".",VERSION.minor))
Blosc.set_compressor("blosclz")

# ===========================================================================
# Auxiliary file write functions
function autoname(ot::DateTime)
  s = replace(string(ot), ['-',':','T'], '.')
  (length(s) == 19) && (s*=".000")
  (length(s) < 23) && (s*="0"^(23-length(s)))
  return s
end
autoname(t::Array{Array{Int64,2}}) = autoname(isempty(t) ? u2d(0) : u2d(minimum([t[i][1,2] for i=1:length(t)])/1000000))

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
  x = Array{UInt8,1}(maximum([sizeof(S.x[i]) for i=1:1:S.n]))
  for i = 1:1:S.n
    c = get_separator(join(S.notes[i]))
    r = length(S.resp[i])
    l = Blosc.compress!(x, S.x[i], level=9)
    if l == 0
      warn(string("Compression ratio > 1.0 for channel ", i, "; are data OK?"))
      x = Blosc.compress(S.x[i], level=9)
    end

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
    write(io, l)
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
    write(io, x[1:l])

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
w_struct(io::IOStream, S::SeisChannel) = w_struct(io, SeisData(S))

# SeisEvent
w_struct(io::IOStream, S::SeisEvent) = (w_struct(io, S.hdr); w_struct(io, S.data))

# ===========================================================================
# functions that invoke w_struct()
"""
    wseis(S, T)

Write SeisIO objects `S, T ∈ Union{SeisData,SeisChannel,SeisHdr,SeisEvent}` to multi-record file. Accepts the same naming keywords as `wseis`, but the default `pref` string is the file write time followed by `.m`.

    wseis(A...)

Use "splat" notation for an array `A` of SeisIO objects.

    `wseis(F::String, A...)`

Write SeisIO objects `A...` to filename `F`. This syntax ignores the keywords of wseis.

    `wseis(A..., sf=true)`

Specify `sf=true` for single-object files; each SeisIO object in `A` will be written to its own file.

#### File Naming Conventions
* Filenames are written [path]/[pref].[name].[suff]. Each of these can be set with a keyword, e.g. `wseis(A..., pref="foo")`.
* For multi-object files, the defaults are:
  - `pref`: time of write, specified YYYY.MM.DD.hh.mm.ss.nnn.
  - `name`: types of objects in lowercase with "seis" omitted, separated by underscores: e.g. "data_event" for a file that contains both SeisData and SeisEvent objects.
  - `suff`: ".seis"
* For single-object files, the defaults are:
  - `pref`: for a SeisHdr or SeisEvent object, the origin time; for a SeisData object, the earliest start time, defined ``minimum([S.t[i][1,2] for i=1:S.n])`` for a SeisData object ``S``.
  - `name`: type of object in lowercase with "seis" omitted: "data" for SeisData, "event" for SeisEvent, "hdr" for SeisHdr.
  - `suff`: ".seis"

*Caution*: Although extremely unlikely, if multiple SeisData objects with identical start times are passed to a single ``wseis`` call with ``sf=true``, they will overwrite each other.
"""
function wseis(S...; sf=false::Bool, path="./"::String, pref=""::String, name=""::String, suff="seis"::String)
  U = Union{SeisData,SeisChannel,SeisHdr,SeisEvent}
  L = Int64(length(S))
  (L == 0) && return
  fname = ""

  # try to find a string to set as a filename
  b = trues(L)
  for i = 1:1:L
    if (typeof(S[i]) <: U) == false
      b[i] = false
      if isa(S[i], String) && fname == ""
        fname = S[i]
      else
        warn(string("Object of incompatible type passed to wseis at ", i, "; skipped!"))
      end
    end
  end
  S = S[b]
  L = Int64(length(S))

  # Second pass: open file for writing
  if !sf
    C = Array{UInt8,1}(L)                                         # Codes
    B = zeros(UInt64, L)                                          # Byte indices
    ID = Array{UInt8,1}()                                         # IDs
    TS = Array{Int64,1}()                                         # Start times
    TE = Array{Int64,1}()                                         # End times

    # File name
    if isempty(fname)
      f0 = isempty(pref) ? autoname(now()) : pref
      if isempty(name)
        n0 = replace(join(unique([lowercase(split(string(typeof(i)),"Seis")[end]) for i in S]), "_"), "string_", "")
        fname = join([f0, n0, suff],'.')
      elseif isempty(pref) && isempty(suff)
        fname = name
      else
        if isempty(fname)
          n0 = name
          fname = join([f0, n0, suff],'.')
        end
      end
    end

    # fname → IO stream
    io = open(path*"/"*fname, "w")
    write(io, "SEISIO".data)
    write(io, vSeisIO())
    write(io, vJulia())
    write(io, L)
    p = position(io)
    skip(io, sizeof(C)+sizeof(B))
  end

  for i = 1:1:L
    seis = (typeof(S[i]) == SeisChannel) ? SeisData(S[i]) : S[i]

    if sf
      n0 = isempty(name) ? lowercase(split(string(typeof(seis)),"Seis")[end]) : name
      if typeof(seis) == SeisData
        f0 = isempty(pref) ? autoname(getfield(seis,:t)) : pref
        C = UInt8['D']
        ID = join(seis.id,'\0').data
        TS = vcat([seis.t[j][1,2] for j=1:1:seis.n]...)
        TE = TS .+ vcat([seis.t[j][2:end,2] for j=1:1:seis.n]...) .+ map(Int64, round(1.0e6.*[length(seis.x[j]) for j=1:1:seis.n]./seis.fs))

      elseif typeof(seis) == SeisHdr
        f0 = isempty(pref) ? autoname(getfield(seis),:ot) : pref
        C = UInt8['H']
        ID = Array{UInt8,1}()
        TS = Array{Int64,1}()
        TE = Array{Int64,1}()

      elseif typeof(seis) == SeisEvent
        f0 = isempty(pref) ? (d2u(seis.hdr.ot) == 0.0 ? autoname(getfield(getfield(seis,:data),:t)) : autoname(getfield(getfield(seis,:hdr),:ot))) : pref
        C = UInt8['E']
        ID = join(seis.data.id,'\0').data
        TS = vcat([seis.data.t[j][1,2] for j=1:1:seis.data.n]...)
        TE = TS .+ vcat([seis.data.t[j][2:end,2] for j=1:1:seis.data.n]...) .+ map(Int64, round(1.0e6.*[length(seis.data.x[j]) for j=1:1:seis.data.n]./seis.data.fs))

      end
      io = open(path*"/"*join([f0, n0, suff],'.'), "w")
      write(io, "SEISIO".data)
      write(io, vSeisIO())
      write(io, vJulia())
      write(io, Int64(1))
      write(io, C)
      write(io, UInt64(position(io)+8))
      w_struct(io, seis)

      # File appendix added 2017-02-23
      x = Int64(position(io)); write(io, ID)
      y = Int64(position(io)); write(io, TS)
      z = Int64(position(io)); write(io, TE)
      write(io, x, y, z)
      close(io)
    else
      B[i] = UInt64(position(io))
      seis = (typeof(S[i]) == SeisChannel) ? SeisData(S[i]) : S[i]
      if typeof(seis) == SeisData
        C[i] = UInt8('D')
        id = join(seis.id,'\0').data
        ts = vcat([seis.t[j][1,2] for j=1:1:seis.n]...)
        te = ts .+ vcat([sum(seis.t[j][2:end,2]) for j=1:1:seis.n]...) + map(Int64, round(1.0e6.*[length(seis.x[j]) for j=1:1:seis.n]./seis.fs))
      elseif typeof(seis) == SeisHdr
        C[i] = UInt8('H')
        id = Array{UInt8,1}()
        ts = Array{Int64,1}()
        te = Array{Int64,1}()
      elseif typeof(seis) == SeisEvent
        C[i] = UInt8('E')
        id = join(seis.data.id,'\0').data
        ts = vcat([seis.data.t[j][1,2] for j=1:1:seis.data.n]...)
        te = ts .+ vcat([sum(seis.data.t[j][2:end,2]) for j=1:1:seis.data.n]...) + map(Int64, round(1.0e6.*[length(seis.data.x[j]) for j=1:1:seis.data.n]./seis.data.fs))
      end
      append!(TS, ts)
      append!(TE, te)
      append!(ID, id)
      w_struct(io, seis)
      if i < L
        push!(ID, 0x0a)
      end
    end
  end

  if !sf
    # TOC format: array of object types, array of byte indices
    seek(io, p)
    write(io, C)
    write(io, B)

    # File appendix added 2017-02-23
    # appendix format: ID, TS, TE, position(ID), position(TS), position(TE)
    seekend(io)
    x = Int64(position(io)); write(io, ID)
    y = Int64(position(io)); write(io, TS)
    z = Int64(position(io)); write(io, TE)
    write(io, x, y, z)
    close(io)
  end
end
# wseis(f::String, S...) = wseis(path=dirname(relpath(f)), pref="", name=basename(relpath(f)), suff="", S...)
