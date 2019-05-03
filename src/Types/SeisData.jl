import Base:in, getindex, setindex!, append!, deleteat!, delete!, +, -, *, isequal,
length, size, sizeof, ==, isempty, sort!, sort, lastindex, firstindex

export SeisData, findid, pull, prune!, findchan

# This is type-stable for S = SeisData() but not for keyword args

@doc """
    SeisData

A custom structure designed to contain the minimum necessary information for
processing univariate geophysical data.

    SeisChannel

A single channel designed to contain the minimum necessary information for
processing univariate geophysical data.

    SeisHdr

A container for earthquake source information; specific to seismology.

    SeisEvent

A structure for discrete seismic events, comprising a SeisHdr for the event
  descriptor and a SeisData for data.

## Fields: SeisData, SeisChannel, SeisEvent.data

| **Field** | **Description** |
|:-------|:------ |
| :n     | Number of channels [^1] |
| :c     | TCP connections feeding data to this object [^1] |
| :id    | Channel ids. use NET.STA.LOC.CHAN format when possible  |
| :name  | Freeform channel names |
| :loc   | Location (position) vector; freeform  |
| :fs    | Sampling frequency in Hz; set to 0.0 for irregularly-sampled data. |
| :gain  | Scalar gain; divide data by the gain to convert to units  |
| :resp  | Instrument response; two-column matrix, format [zeros poles] |
| :units | String describing data units. UCUM standards are assumed. |
| :src   | Freeform string describing data source. |
| :misc  | Dictionary for non-critical information. |
| :notes | Timestamped notes; includes automatically-logged acquisition and |
|        | processing information. |
| :t     | Matrix of time gaps, formatted [Sample# GapLength] |
|        | gaps are in μs measured from the Unix epoch |
| :x     | Data |

[^1]: Not present in SeisChannel objects.

See documentation (https://seisio.readthedocs.io/) for more details.
""" SeisData
mutable struct SeisData
  n::Int64
  c::Array{TCPSocket,1}                       # connections
  name::Array{String,1}                       # name
  id::Array{String,1}                         # id
  loc::Array{Array{Float64,1},1}              # loc
  fs::Array{Float64,1}                        # fs
  gain::Array{Float64,1}                      # gain
  resp::Array{Array{Complex{Float64},2},1}    # resp
  units::Array{String,1}                      # units
  misc::Array{Dict{String,Any},1}             # misc
  notes::Array{Array{String,1},1}             # notes
  src::Array{String,1}                        # src
  t::Array{Array{Int64,2},1}                  # time
  x::Array{Union{Array{Float64,1},Array{Float32,1}},1}  # data

  function SeisData()
    return new(0,
                Array{TCPSocket,1}(undef,0),
                Array{String,1}(undef,0),
                Array{String,1}(undef,0),
                Array{Array{Float64,1}}(undef,0),
                Array{Float64,1}(undef,0),
                Array{Float64,1}(undef,0),
                Array{Array{Complex{Float64},2},1}(undef,0),
                Array{String,1}(undef,0),
                Array{Dict{String,Any},1}(undef,0),
                Array{Array{String,1},1}(undef,0),
                Array{String,1}(undef,0),
                Array{Array{Int64,2},1}(undef,0),
                Array{Union{Array{Float64,1},Array{Float32,1}},1}(undef,0)
              )
  end

  function SeisData(n::UInt)
    S = new(n,
              Array{TCPSocket,1}(undef,0),
              Array{String,1}(undef,n),
              Array{String,1}(undef,n),
              Array{Array{Float64,1}}(undef,n),
              Array{Float64,1}(undef,n),
              Array{Float64,1}(undef,n),
              Array{Array{Complex{Float64},2},1}(undef,n),
              Array{String,1}(undef,n),
              Array{Dict{String,Any},1}(undef,n),
              Array{Array{String,1},1}(undef,n),
              Array{String,1}(undef,n),
              Array{Array{Int64,2},1}(undef,n),
              Array{Union{Array{Float64,1},Array{Float32,1}},1}(undef,n)
            )

    # Fill these fields with something to prevent undefined reference errors
    fill!(S.id, "")                                         #  id
    fill!(S.name, "")                                       # name
    fill!(S.src, "")                                        # src
    fill!(S.units, "")                                      # units
    fill!(S.fs, 0.0)                                        # fs
    fill!(S.gain, 1.0)                                      # gain
    for i = 1:n
      S.notes[i]  = Array{String,1}(undef,0)                # notes
      S.misc[i]   = Dict{String,Any}()                      # misc
      S.t[i]      = Array{Int64,2}(undef,0,2)               # t
      S.x[i]      = Array{Float32,1}(undef,0)               # x
      S.loc[i]    = Array{Float64,1}(undef,0)               # loc
      S.resp[i]   = Array{Complex{Float64},2}(undef,0,2)    # resp
    end
    return S
  end
  SeisData(n::Int) = n > 0 ? SeisData(UInt(n)) : SeisData()
end

function SeisData(U...)
  S = SeisData()
  for i = 1:length(U)
    if typeof(U[i]) == SeisChannel
      push!(S, U[i])
    elseif typeof(U[i]) == SeisData
      append!(S, U[i])
    elseif typeof(U[i]) == SeisEvent
      append!(S, U[i].data)
    else
      @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
    end
  end
  return S
end

# ============================================================================
# Indexing, searching, iteration, size
# s = S[j] returns a SeisChannel struct
# s = S[i:j] returns a SeisData struct
# S[i:j].foo = bar won't work
lastindex(S::SeisData) = S.n
firstindex(S::SeisData) = 1
size(S::SeisData) = (S.n,)

function getindex(S::SeisData, J::Array{Int,1})
  U = SeisData()
  for f in datafields
    setfield!(U, f, getfield(S,f)[J])
  end
  setfield!(U, :n, length(J))
  return U
end
getindex(S::SeisData, J::UnitRange) = getindex(S, collect(J))

in(s::String, S::SeisData) = in(s, S.id)

function setindex!(S::SeisData, U::SeisData, J::Array{Int,1})
  length(J) == U.n || throw(BoundsError)
  ([(getfield(S, f))[J] = getfield(U, f) for f in datafields])
  return nothing
end
setindex!(S::SeisData, U::SeisData, J::UnitRange) = setindex!(S, U, collect(J))

isempty(S::SeisData) = (S.n == 0) ? true : minimum([isempty(getfield(S,f)) for f in datafields])

function isequal(S::SeisData, U::SeisData)
  q::Bool = true
  for i in datafields
    if i != :notes
      q = min(q, hash(getfield(S,i))==hash(getfield(U,i)))
    end
  end
  return q
end
==(S::SeisData, U::SeisData) = isequal(S,U)

function sizeof(S::SeisData)
  s = sizeof(S.c) + 8
  for f in datafields
    v = getfield(S,f)
    s += sizeof(v)
    for i = 1:S.n
      s += sizeof(v[i])
      if f == :notes
        if !isempty(S.notes[i])
          s += sum([sizeof(j) for j in S.notes[i]])
        end
      elseif f == :misc
        if !isempty(S.misc[i])
          s += sum([sizeof(j) for j in values(S.misc[i])])
        end
      end
    end
  end
  return s
end

"""
    findid(id::String, S::SeisData)
    findid(S::SeisData, id::String)

Get the index of the first channel in S where `id.==S.id` is true. Returns 0
for failure.

    findid(S::SeisData, T::SeisData)

Get index corresponding to the first channel in T that matches each ID in S;
equivalent to [findid(id,T) for id in S.id].
"""
function findid(id::Union{Regex,String}, S::SeisData)
  j=0
  for i=1:length(S.id)
    if S.id[i] == id
      j=i
      break
    end
  end
  return j
end
findid(S::SeisData, id::Union{String,Regex}) = findid(id, S)
findid(S::SeisData, T::SeisData) = [findid(id, T) for id in S.id]
# DND ...why the fuck is findfirst so fucking slow?!

"""
    findchan(id::String, S::SeisData)

Get all channel indices `i` in S with id ∈ S.id[i]
"""
findchan(r::Union{Regex,String}, S::SeisData) = findall([occursin(r, i) for i in S.id])

# Append, add, delete, sort
append!(S::SeisData, U::SeisData)  = (
  [setfield!(S, i, append!(getfield(S,i), getfield(U,i))) for i in datafields];
  S.n += U.n;
  return S)
+(S::SeisData, U::SeisData) = (T = deepcopy(S); return append!(T, U))

# ============================================================================
# deleteat!
deleteat!(S::SeisData, j::Int)          = ([deleteat!(getfield(S, i),j) for i in datafields]; S.n -= 1; return nothing)
deleteat!(S::SeisData, J::Array{Int,1}) = (sort!(J); [deleteat!(getfield(S, f), J) for f in datafields]; S.n -= length(J); return nothing)
deleteat!(S::SeisData, K::UnitRange)    = deleteat!(S, collect(K))

# Subtraction
-(S::SeisData, i::Int)          = (U = deepcopy(S); deleteat!(U,i); return U)  # By channel #
-(S::SeisData, J::Array{Int,1}) = (U = deepcopy(S); deleteat!(U,J); return U)  # By array of channel #s
# ============================================================================
# delete!
function delete!(S::SeisData, s::Union{Regex,String}; exact=true::Bool)
  if exact
    i = findid(S, s)
    deleteat!(S, i)
  else
    deleteat!(S, findchan(s,S))
  end
  return nothing
end

# With this convention, S+U-U = S
function delete!(S::SeisData, U::SeisData)
  id = reverse(U.id)
  J = Array{Int64,1}(undef,0)
  for i in id
    j = findlast(S.id.==i)
    (j == nothing) || push!(J,j)
  end
  deleteat!(S, J)
  return nothing
end

-(S::SeisData, r::Union{Regex,String}) = (U = deepcopy(S); delete!(U,r); return U)  # By channel id regex or string
-(S::SeisData, T::SeisData) = (U = deepcopy(S); delete!(U,T); return U)             # Remove all channels with IDs in one SeisData from another

# Extract
"""
    T = pull(S::SeisData, id::String)

Extract the first channel with id=`id` from `S` and return it as a new SeisChannel structure. The corresponding channel in `S` is deleted.

    T = pull(S::SeisData, i::integer)

Extract channel `i` from `S` as a new SeisChannel struct, deleting it from `S`.
"""
function pull(S::SeisData, s::String)
  i = findid(S, s)
  T = deepcopy(getindex(S, i))
  deleteat!(S,i)
  return T
end
function pull(S::SeisData, J::UnitRange)
  T = deepcopy(getindex(S, J))
  deleteat!(S,J)
  return T
end
function pull(S::SeisData, J::Array{Int64,1})
  T = deepcopy(getindex(S, J))
  deleteat!(S,J)
  return T
end

# Sorting
"""
sort!(S::SeisData, [rev=false])

In-place sort of channels in object S by `S.id`. Specify `rev=true` to reverse the sort order.
"""
function sort!(S::SeisData; rev=false::Bool)
  j = sortperm(S.id, rev=rev)
  [setfield!(S,i,getfield(S,i)[j]) for i in datafields]
  return S
end
sort(S::SeisData; rev=false::Bool) = (T = deepcopy(S); sort!(T, rev=rev))

"""
    prune!(S::SeisData)

Delete all channels from S that have no data (i.e. S.x is empty or non-existent).
"""
prune!(S::SeisData) = (deleteat!(S, findall([length(x) == 0 for x in S.x])); return nothing)

# Purpose: deal with intentional overly-generous "resize!" when parsing SEED
function trunc_x!(S::SeisData)
  for i = 1:S.n
    L = size(S.t[i], 1)
    if L == 0
      S.x[i] = Array{Float64,1}(undef, 0)
    else
      nx = S.t[i][L,1]
      if length(S.x[i]) > nx
        resize!(S.x[i], nx)
      end
    end
  end
  return nothing
end

namestrip!(S::SeisData) = (for (i,name) in enumerate(S.name); s = namestrip(name); S.name[i]=s; end)
