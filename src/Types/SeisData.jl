import Base:in, getindex, setindex!, append!, deleteat!, delete!, +, -, *, isequal,
length, start, done, next, size, sizeof, ==, isempty, sort!, sort, endof

# This is type-stable for S = SeisData() but not for keyword args
type SeisData
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
  x::Array{Array{Float64,1},1}                # data

  function SeisData(n::Int64)
    n = max(n,0)
    name = Array{String,1}(n)
    id = Array{String,1}(n)
    notes = Array{Array{String,1},1}(n)
    src = Array{String,1}(n)
    misc = Array{Dict{String,Any},1}(n)
    n0 = tnote("Channel initialized")
    s0 = "SeisData"
    for i = 1:n
      name[i] = string("Channel ",i)
      notes[i] = Array{String,1}([identity(n0)])
      src[i] = identity(s0)
      misc[i] = Dict{String,Any}()
    end
    new(n,
      Array{TCPSocket,1}(0),
      name,
      collect(Main.Base.Iterators.repeated("...YYY",n)),
      collect(Main.Base.Iterators.repeated(zeros(Float64,5),n)),
      collect(Main.Base.Iterators.repeated(0.0,n)),
      collect(Main.Base.Iterators.repeated(1.0,n)),
      collect(Main.Base.Iterators.repeated(Array{Complex{Float64}}(0,2),n)),
      collect(Main.Base.Iterators.repeated("",n)),
      misc,
      notes,
      src,
      collect(Main.Base.Iterators.repeated(Array{Int64,2}(0,2),n)),
      collect(Main.Base.Iterators.repeated(Array{Float64,1}(0),n)))
  end

  function SeisData(U...)
    S = SeisData()
    for i = 1:1:length(U)
      if typeof(U[i]) in [SeisChannel,SeisData]
        append!(S, U[i])
      else
        warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
      end
    end
    return S
  end
end
SeisData() = SeisData(0)

# ============================================================================
# Indexing, searching, iteration, size
# s = S[j] returns a SeisChannel struct
# s = S[i:j] returns a SeisData struct
# S[i:j].foo = bar won't work
endof(S::SeisData) = S.n

function getindex(S::SeisData, J::Array{Int,1})
  U = SeisData()
  [setfield!(U, f, getfield(S,f)[J]) for f in datafields]
  setfield!(U, :n, length(J))
  return U
end
getindex(S::SeisData, J::UnitRange) = getindex(S, collect(J))

in(s::String, S::SeisData) = in(s, S.id)

"""
    findid(S::SeisData, n::String)

Get the index to the first channel of S where `(S.id.==n) == true`.
"""
findid(n::String, S::SeisData) = findfirst(S.id .== n)
findid(S::SeisData, n::String) = findfirst(S.id .== n)
findid(S::SeisData, T::SeisData) = [findfirst(S.id .== T.id[i]) for i=1:1:T.n]

setindex!(S::SeisData, U::SeisData, J::Array{Int,1}) = (
  [(getfield(S, f))[J] = getfield(U, f) for f in datafields];
  return S)
setindex!(S::SeisData, U::SeisData, J::UnitRange) = setindex!(S, U, collect(J))
setindex!(S::SeisData, U::SeisData, j::Int) = setindex!(S, U, [j])

function isempty(S::SeisData)
  if S.n == 0
    return true
  else
    return minimum([isempty(S.x[i]) for i=1:1:S.n]::Array{Bool,1})
  end
end

isequal(S::SeisData, U::SeisData) = minimum([hash(getfield(S,i))==hash(getfield(U,i)) for i in datafields]::Array{Bool,1})
==(S::SeisData, U::SeisData) = isequal(S,U)::Bool

function sizeof(S::SeisData)
  N = Array{Int,1}(length(datafields))
  M = Array{Int,1}(length(datafields))
  [M[i] = sizeof(getfield(S,f)) for (i,f) in enumerate(datafields)]
  [N[i] = sum([M[j] = sizeof(V) for (j,V) in enumerate(getfield(S,f))]) for (i,f) in enumerate(datafields)]
  return sum(N) + sum(M)
end
# ============================================================================


# ============================================================================
# Annotation

# Adding a string to SeisData writes a note; if the string mentions a channel
# name or ID, the note is restricted to the given channels(s), else it's
# added to all channels
"""
    note!(S::SeisData, s::String)

Append a timestamped note to `S.notes`. If `txt` mentions a channel name or ID, only the corresponding channel is annotated; otherwise, all channels are annotated.

"""
function note!(S::SeisData, s::String)
  j = find(maximum([[findfirst(contains(s,i)) for i in S.name] [findfirst(contains(s,i)) for i in S.id]],2).>0)
  if !isempty(j)
    [push!(S.notes[i], tnote(s)) for i in j]
  else
    for i = 1:1:S.n
      push!(S.notes[i], tnote(s))
    end
  end
  return S
end

note!(S::SeisData, i::Integer, s::String) = push!(S.notes[i], tnote(s))

# ============================================================================
# Append, add, delete, sort
append!(S::SeisData, U::SeisData)  = (
  [setfield!(S, i, append!(getfield(S,i), getfield(U,i))) for i in datafields];
  S.n += U.n;
  return S)
+(S::SeisData, U::SeisData) = (T = deepcopy(S); return append!(T, U))

# Delete methods are aliased to -
deleteat!(S::SeisData, j::Int)          = ([deleteat!(getfield(S, i),j) for i in datafields]; S.n -= 1; return S)
deleteat!(S::SeisData, J::Array{Int,1}) = (sort!(J); [deleteat!(getfield(S, f), J) for f in datafields]; S.n -= length(J))
deleteat!(S::SeisData, K::UnitRange)    = (J = collect(K); deleteat!(S, J))

# With this convention, S+U-U = S
function deleteat!(S::SeisData, U::SeisData)
  id = flipdim(U.id,1)
  J = Array{Int64,1}(0)
  for i in id
    j = findlast(S.id.==i)
    (j > 0) && push!(J,j)
  end
  deleteat!(S, J)
  return nothing
end

# Delete by Regex match or exact ID match
delete!(S::SeisData, r::Regex)          = deleteat!(S, find([ismatch(r, i) for i in S.id]))
delete!(S::SeisData, s::String)         = (i = findlast(S.id.==s); (i > 0) && deleteat!(S, i))

# Nothing more than aliasing, really
delete!(S::SeisData, j::Int)            = deleteat!(S, j)
delete!(S::SeisData, J::UnitRange)      = deleteat!(S, J)
delete!(S::SeisData, J::Array{Int,1})   = deleteat!(S, J)

# Subtraction
-(S::SeisData, i::Int)          = (U = deepcopy(S); deleteat!(U,i); return U)  # By channel #
-(S::SeisData, J::Array{Int,1}) = (U = deepcopy(S); deleteat!(U,J); return U)  # By array of channel #s
-(S::SeisData, J::Range)        = (U = deepcopy(S); deleteat!(U,J); return U)  # By range of channel #s
-(S::SeisData, s::String)       = (U = deepcopy(S); delete!(U,s); return U)    # By channel id string
-(S::SeisData, r::Regex)        = (U = deepcopy(S); delete!(U,r); return U)    # By channel id regex
-(S::SeisData, T::SeisData)     = (U = deepcopy(S); delete!(U,T); return U)    # Remove all channels in one SeisData from another

# Extract
"""
    T = pull(S::SeisData, id::String)

Extract the first channel with id=`id` from `S` and return it as a new SeisData structure. The corresponding channel in `S` is deleted.

    T = pull(S::SeisData, i::integer)

Extract channel `i` from `S` as a new SeisData struct, deleting it from `S`.
"""
pull(S::SeisData, s::String) = (i = findid(S, s); T = deepcopy(getindex(S, i));
  deleteat!(S,i); note!(T,"Extracted from another SeisData object"); return T)
pull(S::SeisData, J::UnitRange) = (T = deepcopy(getindex(S, J)); deleteat!(S,J);
    note!(T,"Extracted from a SeisData object"); return T)
pull(S::SeisData, J::Array{Integer,1}) = (T = deepcopy(getindex(S, J)); deleteat!(S,J);
        note!(T,"Extracted from a SeisData object"); return T)


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
sort(S::SeisData; rev=false::Bool) = (T = deepcopy(S); j = sortperm(T.id, rev=rev); [setfield!(T,i,getfield(T,i)[j]) for i in datafields]; return(T))
