# This is type-stable for S = NodalData() but not for keyword args
@doc """
    NodalData

SeisData variant for multichannel nodal array data.

  NodalChannel

SeisChannel variant for a channel from a nodal array.

## Fields

| **Field** | **Description**                                               |
|:-------|:------                                                           |
| :n     | Number of sensors                                                |
| :ox    | Origin longitude                                                 |
| :oy    | Origin latitude                                                  |
| :oz    | Origin elevation                                                 |
| :info  | Critical array info, shared by all sensors. [^1]                 |
| :id    | Channel id. Uses NET.STA.LOC.CHA format when possible            |
| :name  | Freeform channel name                                            |
| :loc   | Location (position) vector; only accepts NodalLoc                |
| :fs    | Sampling frequency in Hz                                         |
| :gain  | Scalar gain                                                      |
| :resp  | Instrument response                                              |
| :units | String describing data units. UCUM standards are assumed.        |
| :src   | Freeform string describing data source.                          |
| :misc  | Dictionary for non-critical information.                         |
| :notes | Timestamped notes; includes automatically-logged information.    |
| :t     | Matrix of time gaps in integer μs, formatted [Sample# Length]    |
| :data  | Matrix underlying time-series data                               |
| :x     | Views into :data corresponding to each channel                   |

[^1] Not present in, or retained by, NodalChannel objects.

See also: `SeisData`, `InstrumentPosition`, `InstrumentResponse`
""" NodalData
mutable struct NodalData <: GphysData
  n::Int64
  ox::Float64                         # origin x
  oy::Float64                         # origin y
  oz::Float64                         # origin z
  info::Dict{String,Any}              # info
  id::Array{String,1}                 # id
  name::Array{String,1}               # name
  loc::Array{InstrumentPosition,1}    # loc
  fs::Array{Float64,1}                # fs
  gain::Array{Float64,1}              # gain
  resp::Array{InstrumentResponse,1}   # resp
  units::Array{String,1}              # units
  src::Array{String,1}                # src
  misc::Array{Dict{String,Any},1}     # misc
  notes::Array{Array{String,1},1}     # notes
  t::Array{Array{Int64,2},1}          # time
  data::AbstractArray{Float32, 2}     # actual data
  x::Array{FloatArray,1}              # views to data

  function NodalData()
    return new(zero(Int64),
                0.0, 0.0, 0.0,
                Dict{String,Any}(),
                Array{String,1}(undef,0),
                Array{String,1}(undef,0),
                Array{InstrumentPosition,1}(undef,0),
                Array{Float64,1}(undef,0),
                Array{Float64,1}(undef,0),
                Array{InstrumentResponse,1}(undef,0),
                Array{String,1}(undef,0),
                Array{String,1}(undef,0),
                Array{Dict{String,Any},1}(undef,0),
                Array{Array{String,1},1}(undef,0),
                Array{Array{Int64,2},1}(undef,0),
                Array{Float32,2}(undef, 0, 0),
                Array{FloatArray,1}(undef,0)
              )
  end

  function NodalData( n::Int64,
            ox::Float64,
            oy::Float64,
            oz::Float64,
            info::Dict{String,Any}              , # info
            id::Array{String,1}                 , # id
            name::Array{String,1}               , # name
            loc::Array{InstrumentPosition,1}    , # loc
            fs::Array{Float64,1}                , # fs
            gain::Array{Float64,1}              , # gain
            resp::Array{InstrumentResponse,1}   , # resp
            units::Array{String,1}              , # units
            src::Array{String,1}                , # src
            misc::Array{Dict{String,Any},1}     , # misc
            notes::Array{Array{String,1},1}     , # notes
            t::Array{Array{Int64,2},1}          , # time
            data::AbstractArray{Float32, 2}     , # data
            )


    S = new(n, ox, oy, oz, info, id, name, loc, fs, gain, resp, units, src, misc, notes, t, data, Array{FloatArray, 1}(undef, n))
    for i in 1:n
      S.x[i] = view(S.data, :, i)
    end
    return S
  end

  function NodalData(data::AbstractArray{Float32, 2}, info::Dict{String, Any}, chans::ChanSpec, ts::Int64)
    dims = size(data)
    m = dims[1]
    n₀ = dims[2]
    if isempty(chans)
      chans = 1:n₀
    elseif isa(chans, Integer)
      chans = [chans]
    end
    n = length(chans)

    S = new(n,
            zero(Float64),
            zero(Float64),
            zero(Float64),
            deepcopy(info),
            Array{String, 1}(undef, n),
            Array{String, 1}(undef, n),
            Array{InstrumentPosition, 1}(undef, n),
            Array{Float64, 1}(undef, n),
            Array{Float64, 1}(undef, n),
            Array{InstrumentResponse, 1}(undef, n),
            Array{String, 1}(undef, n),
            Array{String, 1}(undef, n),
            Array{Dict{String, Any}, 1}(undef, n),
            Array{Array{String, 1}, 1}(undef, n),
            Array{Array{Int64, 2}, 1}(undef, n),
            data[:, chans],
            Array{FloatArray, 1}(undef, n)
            )

    # Fill these fields with something to prevent undefined reference errors
    fill!(S.id, "")                                         # id
    fill!(S.name, "")                                       # name
    fill!(S.src, "")                                        # src
    fill!(S.units, "")                                      # units
    fill!(S.fs, 0.0)                                        # fs
    fill!(S.gain, 1.0)                                      # gain
    t = mk_t(m, ts)
    for i = 1:n
      S.notes[i]  = Array{String,1}(undef, 0)               # notes
      S.misc[i]   = Dict{String,Any}()                      # misc
      S.t[i]      = copy(t)                                 # t
      S.x[i]      = view(S.data, :, i)                      # x
      S.loc[i]    = NodalLoc()                              # loc
      S.resp[i]   = deepcopy(flat_resp)                     # resp
    end
    return S
  end
end

function sizeof(S::NodalData)
  s = 168 + sizeof(getfield(S, :data))

  # The :info Dictionary uses only simple objects, no string arrays
  k = collect(keys(S.info))
  s += sizeof(k) + 64 + sum([sizeof(j) for j in k])
  for p in values(S.info)
    s += sizeof(p)
  end

  for f in nodalfields
    V = getfield(S, f)
    s += sizeof(V)
    (f in unindexed_fields) && continue
    for i = 1:S.n
      v = getindex(V, i)
      s += sizeof(v)
      if f == :notes
        if !isempty(v)
          s += sum([sizeof(j) for j in v])
        end
      elseif f == :misc
        k = collect(keys(v))
        s += sizeof(k) + 64 + sum([sizeof(j) for j in k])
        for p in values(v)
          s += sizeof(p)
          if typeof(p) == Array{String,1}
            s += sum([sizeof(j) for j in p])
          end
        end
      end
    end
  end
  return s
end

function write(io::IO, S::NodalData)
  N     = getfield(S, :n)
  LOC   = getfield(S, :loc)
  RESP  = getfield(S, :resp)
  T     = getfield(S, :t)
  X     = getfield(S, :data)
  MISC  = getfield(S, :misc)
  NOTES = getfield(S, :notes)

  codes = Array{UInt8,1}(undef, 2N+1)     # sizeof(c) = 2N+1
  L = Array{Int64,1}(undef, N)            # sizeof(L) = 8N

  # write begins ------------------------------------------------------
  write(io, N)
  p = fastpos(io)
  fastskip(io, 10N+1)
  write(io, S.ox, S.oy, S.oz)                                         # ox, oy, oz
  write_misc(io, S.info)                                              # info
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
  sz = size(X)
  write(io, Int64(sz[1]), Int64(sz[2]))                               # data
  write(io, X)
  setindex!(codes, typ2code(eltype(X)), 2N+1)
  q = fastpos(io)

  fastseek(io, p)
  write(io, codes)
  write(io, L)
  fastseek(io, q)
  # write ends ------------------------------------------------------
  return nothing
end

function read(io::IO, ::Type{NodalData})
  Z = getfield(BUF, :buf)
  L = getfield(BUF, :int64_buf)

  # read begins ------------------------------------------------------
  N     = fastread(io, Int64)
  checkbuf_strict!(L, N)
  fast_readbytes!(io, Z, 2N+1)
  read!(io, L)
  c1    = copy(Z[1:N])
  c2    = copy(Z[N+1:2N])
  y     = code2typ(getindex(Z, 2N+1))

  return NodalData(N,
    fastread(io, Float64),
    fastread(io, Float64),
    fastread(io, Float64),
    read_misc(io, Z),
    read_string_vec(io, Z),
    read_string_vec(io, Z),
    InstrumentPosition[read(io, code2loctyp(getindex(c1, i))) for i = 1:N],
    fastread(io, Float64, N),
    fastread(io, Float64, N),
    InstrumentResponse[read(io, code2resptyp(getindex(c2, i))) for i = 1:N],
    read_string_vec(io, Z),
    read_string_vec(io, Z),
    [read_misc(io, Z) for i = 1:N],
    [read_string_vec(io, Z) for i = 1:N],
    [read!(io, Array{Int64, 2}(undef, getindex(L, i), 2)) for i = 1:N],
    read!(io, Array{y, 2}(undef, fastread(io, Int64), fastread(io, Int64)))
    )
end

function show(io::IO, S::NodalData)
  W = max(80, displaysize(io)[2]) - show_os
  nc = getfield(S, :n)
  w = min(W, 35)
  N = min(nc, div(W-1, w))
  M = min(N+1, nc)
  println(io, "NodalData with ", nc, " channels (", N, " shown)")
  F = fieldnames(NodalData)
  for f in F
    if ((f in unindexed_fields) == false) || (f == :x)
      targ = getfield(S, f)
      t = typeof(targ)
      fstr = uppercase(String(f))
      print(io, lpad(fstr, show_os-2), ": ")
      if t == Array{String,1}
        show_str(io, targ, w, N)
      elseif f == :notes || f == :misc
        show_str(io, String[string(length(getindex(targ, i)), " entries") for i = 1:M], w, N)
      elseif f == :t
        show_t(io, targ, w, N, S.fs)
      elseif f == :x
        x_str = mkxstr(N, getfield(S, :x))
        show_x(io, x_str, w, N<nc)
      else
        show_str(io, String[repr("text/plain", targ[i], context=:compact=>true) for i = 1:M], w, N)
      end
    elseif f == :ox
      print(io, "COORDS: X = ", repr("text/plain", getfield(S, f), context=:compact=>true), ", ")
    elseif f == :oy
      print(io, "Y = ", repr("text/plain", getfield(S, f), context=:compact=>true), ", ")
    elseif f == :oz
      print(io, "Z = ", repr("text/plain", getfield(S, f), context=:compact=>true), "\n")
    elseif f == :info
      print(io, "  INFO: ", length(S.info), " entries\n")
    end
  end
  return nothing
end
show(S::NodalData) = show(stdout, S)

function getindex(S::NodalData, J::Array{Int,1})
  n = getfield(S, :n)
  U = NodalData()
  U.n = length(J)

  # indexed fields
  for f in nodalfields
    setfield!(U, f, getindex(getfield(S, f), J))
  end

  # :data
  U.data = S.data[:, J]
  U.x = Array{FloatArray, 1}(undef, U.n)
  for i in 1:U.n
    U.x[i] = view(U.data, :, i)
  end

  # origin
  for f in (:ox, :oy, :oz)
    setfield!(U, f, getindex(getfield(S, f)))
  end
  U.info = copy(S.info)
  return U
end

refresh_x!(S::NodalData) = ([S.x[i] = view(S.data, :, i) for i in 1:S.n]);

function setindex!(S::NodalData, U::NodalData, J::Array{Int,1})
  typeof(S) == typeof(U) || throw(MethodError)
  length(J) == U.n || throw(BoundsError)

  # set indexed fields
  for f in nodalfields
    if (f in unindexed_fields) == false
      setindex!(getfield(S, f), getfield(U, f), J)
    end
  end

  # set :data
  for (i,j) in enumerate(J)
    S.data[:,j] .= U.data[:,i]
    S.x[j] = view(S.data, :, j)
  end

  return nothing
end
setindex!(S::NodalData, U::NodalData, J::UnitRange) = setindex!(S, U, collect(J))


function sort!(S::NodalData; rev=false::Bool)
  j = sortperm(getfield(S, :id), rev=rev)
  for f in nodalfields
    setfield!(S, f, getfield(S,f)[j])
  end

  # computationally expensive
  S.data = S.data[:, j]
  refresh_x!(S)
  return nothing
end

# Append, add, delete, sort
function append!(S::NodalData, U::NodalData)
  F = fieldnames(NodalData)
  S.data = hcat(S.data, U.data)
  for f in F
    if (f in unindexed_fields) == false
      append!(getfield(S, f), getfield(U, f))
    end
  end

  # append views to S.x
  resize!(S.x, S.n+U.n)
  for i = S.n+1:S.n+U.n
    S.x[i] = view(S.data, :, i)
  end

  # merge :info
  merge!(S.info, U.info)

  # increment S.n
  S.n += U.n

  return nothing
end

# ============================================================================
# deleteat!
function deleteat!(S::NodalData, j::Int)
  for f in nodalfields
    deleteat!(getfield(S, f), j)
  end
  S.data = S.data[:, setdiff(collect(1:S.n), j)]
  S.n -= 1
  refresh_x!(S)
  return nothing
end

function deleteat!(S::NodalData, J::Array{Int,1})
  sort!(J)
  for f in nodalfields
    deleteat!(getfield(S, f), J)
  end
  S.data = S.data[:, setdiff(collect(1:S.n), J)]
  S.n -= length(J)
  refresh_x!(S)
  return nothing
end
