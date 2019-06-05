export EventTraceData

@doc """
    EventTraceData

A custom structure designed to describe trace data (digital seismograms)
associated with a discrete event (earthquake).

    EventChannel

A single channel of trace data (digital seismograms) associated with a
discrete event (earthquake).

## Fields: EventTraceData, EventChannel, SeisEvent.data

| **Field** | **Description** |
|:-------|:------ |
| :n     | Number of channels [^1] |
| :id    | Channel ids. use NET.STA.LOC.CHAN format when possible  |
| :name  | Freeform channel names |
| :loc   | Location (position) vector; any subtype of InstrumentPosition  |
| :fs    | Sampling frequency in Hz; set to 0.0 for irregularly-sampled data. |
| :gain  | Scalar gain  |
| :resp  | Instrument response; any subtype of InstrumentResponse |
| :units | String describing data units. UCUM standards are assumed. |
| :az    | Source azimuth  |
| :baz   | Backazimuth to source  |
| :dist  | Source-receiver distance |
| :pha   | Seismic phase catalog |
| :src   | Freeform string describing data source. |
| :misc  | Dictionary for non-critical information. |
| :notes | Timestamped notes; includes automatically-logged acquisition and |
|        | processing information. |
| :t     | Matrix of time gaps, formatted [Sample# GapLength] |
|        | gaps are in μs measured from the Unix epoch |
| :x     | Data |

[^1]: Not present in EventChannel objects.

See also: PhaseCat, SeisPha, SeisData
""" EventTraceData
mutable struct EventTraceData <: GphysData
  n     ::Int64                         # number of channels
  id    ::Array{String,1}               # id
  name  ::Array{String,1}               # name
  loc   ::Array{InstrumentPosition,1}   # loc
  fs    ::Array{Float64,1}              # fs
  gain  ::Array{Float64,1}              # gain
  resp  ::Array{InstrumentResponse,1}   # resp
  units ::Array{String,1}               # units
  az    ::Array{Float64,1}              # source azimuth
  baz   ::Array{Float64,1}              # backazimuth
  dist  ::Array{Float64,1}              # distance
  pha   ::Array{PhaseCat,1}             # phase catalog
  src   ::Array{String,1}               # src
  misc  ::Array{Dict{String,Any},1}     # misc
  notes ::Array{Array{String,1},1}      # notes
  t     ::Array{Array{Int64,2},1}       # time
  x     ::Array{FloatArray,1}           # data

  function EventTraceData()
    return new( 0,                                        # n
                Array{String,1}(undef,0),                 # id
                Array{String,1}(undef,0),                 # name
                Array{InstrumentPosition,1}(undef,0),     # loc
                Array{Float64,1}(undef,0),                # fs
                Array{Float64,1}(undef,0),                # gain
                Array{InstrumentResponse,1}(undef,0),     # resp
                Array{String,1}(undef,0),                 # units
                Array{Float64,1}(undef,0),                # az
                Array{Float64,1}(undef,0),                # baz
                Array{Float64,1}(undef,0),                # dist
                Array{PhaseCat,1}(undef,0),               # pha
                Array{String,1}(undef,0),                 # src
                Array{Dict{String,Any},1}(undef,0),       # misc
                Array{Array{String,1},1}(undef,0),        # notes
                Array{Array{Int64,2},1}(undef,0),         # t
                Array{FloatArray,1}(undef,0)              # x
                )
  end

  function EventTraceData(n::Int64,
            id::Array{String,1}                 , # id
            name::Array{String,1}               , # name
            loc::Array{InstrumentPosition,1}    , # loc
            fs::Array{Float64,1}                , # fs
            gain::Array{Float64,1}              , # gain
            resp::Array{InstrumentResponse,1}   , # resp
            units::Array{String,1}              , # units
            az::Array{Float64,1}                , # az
            baz::Array{Float64,1}               , # baz
            dist::Array{Float64,1}              , # dist
            pha::Array{PhaseCat,1}              , # pha
            src::Array{String,1}                , # src
            misc::Array{Dict{String,Any},1}     , # misc
            notes::Array{Array{String,1},1}     , # notes
            t::Array{Array{Int64,2},1}          , # time
            x::Array{FloatArray,1})

    return new(n,
      id, name, loc, fs, gain, resp, units, az, baz, dist, pha, src, misc, notes, t, x)
  end

  function EventTraceData(n::UInt)
    TD = new( n,                                          # n
                Array{String,1}(undef,n),                 # id
                Array{String,1}(undef,n),                 # name
                Array{InstrumentPosition,1}(undef,n),     # loc
                Array{Float64,1}(undef,n),                # fs
                Array{Float64,1}(undef,n),                # gain
                Array{InstrumentResponse,1}(undef,n),     # resp
                Array{String,1}(undef,n),                 # units
                Array{Float64,1}(undef,n),                # az
                Array{Float64,1}(undef,n),                # baz
                Array{Float64,1}(undef,n),                # dist
                Array{PhaseCat,1}(undef,n),               # pha
                Array{String,1}(undef,n),                 # src
                Array{Dict{String,Any},1}(undef,n),       # misc
                Array{Array{String,1},1}(undef,n),        # notes
                Array{Array{Int64,2},1}(undef,n),         # t
                Array{FloatArray,1}(undef,n)              # x
                )

    # Fill these fields with something to prevent undefined reference errors
    fill!(TD.az, 0.0)                                        # az
    fill!(TD.baz, 0.0)                                       # baz
    fill!(TD.dist, 0.0)                                      # dist
    fill!(TD.fs, 0.0)                                        # fs
    fill!(TD.gain, 1.0)                                      # gain
    fill!(TD.id, "")                                         # id
    fill!(TD.name, "")                                       # name
    fill!(TD.src, "")                                        # src
    fill!(TD.units, "")                                      # units
    for i = 1:n
      TD.loc[i]    = GeoLoc()                                # loc
      TD.misc[i]   = Dict{String,Any}()                      # misc
      TD.notes[i]  = Array{String,1}(undef,0)                # notes
      TD.resp[i]   = PZResp()                                # resp
      TD.pha[i]    = PhaseCat()                              # pha
      TD.t[i]      = Array{Int64,2}(undef,0,2)               # t
      TD.x[i]      = Array{Float32,1}(undef,0)               # x
    end
    return TD
  end
  EventTraceData(n::Int) = n > 0 ? EventTraceData(UInt(n)) : EventTraceData()
end

function sizeof(TD::EventTraceData)
  s = 144
  for f in tracefields
    if (f in unindexed_fields) == false
      V = getfield(TD, f)
      s += sizeof(V)
      for i = 1:TD.n
        v = getindex(V, i)
        s += sizeof(v)
        if f == :notes
          if !isempty(v)
            s += sum([sizeof(j) for j in v])
          end
        elseif f == :misc || f == :pha
          for i in values(v)
            s += sizeof(i)
          end
          s += sizeof(collect(keys(v)))
        end
      end
    end
  end
  return s
end


# SeisData
function write(io::IO, S::EventTraceData)
  N     = getfield(S, :n)
  LOC   = getfield(S, :loc)
  RESP  = getfield(S, :resp)
  T     = getfield(S, :t)
  X     = getfield(S, :x)
  MISC  = getfield(S, :misc)
  NOTES = getfield(S, :notes)

  cmp = false
  if KW.comp != 0x00
    nx_max = maximum([sizeof(getindex(X, i)) for i = 1:S.n])
    if (nx_max > KW.n_zip) || (KW.comp == 0x02)
      cmp = true
      Z = getfield(BUF, :buf)
      checkbuf_8!(Z, nx_max)
    end
  end

  codes = Array{UInt8,1}(undef, 3*N)
  L = Array{Int64,1}(undef, 2*N)

  # Write begins -----------------------------------------------------
  write(io, N)
  p = position(io)
  skip(io, 19*N+1)
  write_string_vec(io, S.id)                                          # id
  write_string_vec(io, S.name)                                        # name
  i = 0                                                               # loc
  while i < N
    i = i + 1
    loc = getindex(LOC, i)
    setindex!(codes, loctyp2code(loc), i)
    write(io, loc)
  end
  write(io, S.fs)                                                     # fs
  write(io, S.gain)                                                   # gain
  i = 0                                                               # resp
  while i < N
    i = i + 1
    resp = getindex(RESP, i)
    setindex!(codes, resptyp2code(resp), N+i)
    write(io, resp)
  end
  write_string_vec(io, S.units)                                       # units
  write(io, S.az)                                                     # az
  write(io, S.baz)                                                    # baz
  write(io, S.dist)                                                   # dist
  for i = 1:N; write(io, S.pha[i]); end                               # pha
  write_string_vec(io, S.src)                                         # src
  for i = 1:N; write_misc(io, getindex(MISC, i)); end                 # misc
  for i = 1:N; write_string_vec(io, getindex(NOTES, i)); end          # notes
  i = 0                                                               # t
  while i < N
    i = i + 1
    t = getindex(T, i)
    setindex!(L, size(t,1), i)
    write(io, t)
  end
  i = 0                                                               # x
  while i < N
    i = i + 1
    x = getindex(X, i)
    nx = lastindex(x)
    if cmp
      l = zero(Int64)
      while l == zero(Int64)
        l = Blosc.compress!(Z, x, level=5)
        (l > zero(Int64)) && break
        nx_max = nextpow(2, nx_max)
        checkbuf_8!(Z, nx_max)
        @warn(string("Compression ratio > 1.0 for channel ", i, "; are data OK?"))
      end
      xc = view(Z, 1:l)
      write(io, xc)
      setindex!(L, l, N+i)
    else
      write(io, x)
      setindex!(L, nx, N+i)
    end
    setindex!(codes, typ2code(eltype(x)), 2*N+i)
  end
  q = position(io)

  seek(io, p)
  write(io, codes)
  write(io, cmp)
  write(io, L)
  seek(io, q)
  return nothing
end

# read
function read(io::IO, ::Type{EventTraceData})
  Z = getfield(BUF, :buf)
  L = getfield(BUF, :int64_buf)
  N     = read(io, Int64)
  checkbuf_strict!(L, 2*N)
  readbytes!(io, Z, 3*N)
  c1    = copy(Z[1:N])
  c2    = copy(Z[N+1:2*N])
  y     = code2typ.(getindex(Z, 2*N+1:3*N))
  cmp   = read(io, Bool)
  read!(io, L)
  nx    = getindex(L, N+1:2*N)

  if cmp
    checkbuf_8!(Z, maximum(nx))
  end

  return EventTraceData(
    N,
    read_string_vec(io, Z),
    read_string_vec(io, Z),
    InstrumentPosition[read(io, code2loctyp(getindex(c1, i))) for i = 1:N],
    read!(io, Array{Float64, 1}(undef, N)),
    read!(io, Array{Float64, 1}(undef, N)),
    InstrumentResponse[read(io, code2resptyp(getindex(c2, i))) for i = 1:N],
    read_string_vec(io, Z),
    read!(io, Array{Float64, 1}(undef, N)),
    read!(io, Array{Float64, 1}(undef, N)),
    read!(io, Array{Float64, 1}(undef, N)),
    PhaseCat[read(io, PhaseCat) for i = 1:N],
    read_string_vec(io, Z),
    [read_misc(io, Z) for i = 1:N],
    [read_string_vec(io, Z) for i = 1:N],
    [read!(io, Array{Int64, 2}(undef, getindex(L, i), 2)) for i = 1:N],
    FloatArray[cmp ?
      (readbytes!(io, Z, getindex(nx, i)); Blosc.decompress(getindex(y,i), Z)) :
      read!(io, Array{getindex(y,i), 1}(undef, getindex(nx, i)))
      for i = 1:N]
    )
end

function EventTraceData(U...)
  TD = EventTraceData()
  for i = 1:length(U)
    Y = getindex(U,i)
    if typeof(Y) == SeisChannel
      push!(TD, convert(EventChannel, Y))
    elseif typeof(Y) == EventChannel
      push!(TD, Y)
    elseif typeof(Y) == SeisData
      append!(TD, convert(EventTraceData, Y))
    elseif typeof(Y) == SeisEvent
      append!(TD, getfield(Y, :data))
    elseif typeof(Y) == EventTraceData
      append!(TD, Y)
    else
      @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
    end
  end
  return TD
end
