import Base:in, getindex, setindex!, append!, deleteat!, delete!, +, -, *, isequal,
length, size, sizeof, ==, isempty, sort!, sort, lastindex

# This is type-stable for S = SeisData() but not for keyword args
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
  x::Array{Array{Float64,1},1}                # data

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
        Array{String,1}(undef,0),
        Array{String,1}(undef,0),
        Array{Array{Int64,2}}(undef,0),
        Array{Array{Float64,1}}(undef,0)
        )
  end

  function SeisData(n::UInt)
    id = Array{String,1}(undef, n)
    name = Array{String,1}(undef, n)
    notes = Array{Array{String,1},1}(undef, n)
    misc = Array{Dict{String,Any},1}(undef, n)

    n0 = tnote("channel initialized")
    for i = 1:n
      name[i] = string("Channel ",i)
      id[i] = string(".", i, "..YYY")
      misc[i] = Dict{String,Any}()
      notes[i] = Array{String,1}([identity(n0)])
    end

    return new(n,
        Array{TCPSocket,1}(undef,0),
        name,
        id,
        collect(Main.Base.Iterators.repeated(zeros(Float64,5),n)),
        collect(Main.Base.Iterators.repeated(0.0,n)),
        collect(Main.Base.Iterators.repeated(1.0,n)),
        collect(Main.Base.Iterators.repeated(Array{Complex{Float64}}(undef,0,2),n)),
        collect(Main.Base.Iterators.repeated("Unknown",n)),
        misc,
        notes,
        collect(Main.Base.Iterators.repeated(string("SeisData(", n, ")"),n)),
        collect(Main.Base.Iterators.repeated(Array{Int64,2}(undef,0,2),n)),
        collect(Main.Base.Iterators.repeated(Array{Float64,1}(undef,0),n))
        )
  end

  function SeisData(U...)
    S = SeisData()
    for i = 1:length(U)
      if typeof(U[i]) in [SeisChannel,SeisData]
        append!(S, U[i])
      else
        @warn(string("Tried to join incompatible type into SeisData at arg ", i, "; skipped."))
      end
    end
    return S
  end
end
SeisData(n::Int) = n > 0 ? SeisData(UInt(n)) : SeisData()

# ============================================================================
# Indexing, searching, iteration, size
# s = S[j] returns a SeisChannel struct
# s = S[i:j] returns a SeisData struct
# S[i:j].foo = bar won't work
lastindex(S::SeisData) = S.n

function getindex(S::SeisData, J::Array{Int,1})
  U = SeisData()
  # [setfield!(U, f, getfield(S,f)[J]) for f in datafields]
  # I guess this bug was fixed in 0.6
  for f in datafields
    setfield!(U, f, getfield(S,f)[J])
  end
  setfield!(U, :n, length(J))
  return U
end
getindex(S::SeisData, J::UnitRange) = getindex(S, collect(J))

in(s::String, S::SeisData) = in(s, S.id)

"""
    findid(id::String, S::SeisData)
    findid(S::SeisData, id::String)

Get the index to the first channel `c` in  S where `S.id[c]==id`.
"""
function findid(id::String, S::SeisData)
  c = 0
  for i = 1:S.n
    if S.id[i] == id
      c = i
      break
    end
  end
  return c
end
findid(S::SeisData, id::String) = findid(id, S)
function findid(S::SeisData, T::SeisData)
  tc = Array{Int,1}(T.n)
  for i = 1:T.n
    tc[i] = findid(T.id[n], S)
  end
  return tc
end

setindex!(S::SeisData, U::SeisData, J::Array{Int,1}) = (
  [(getfield(S, f))[J] = getfield(U, f) for f in datafields];
  return S)
setindex!(S::SeisData, U::SeisData, J::UnitRange) = setindex!(S, U, collect(J))
setindex!(S::SeisData, U::SeisData, j::Int) = setindex!(S, U, [j])

function isempty(S::SeisData)
  if S.n == 0
    return true
  else
    return minimum([isempty(S.x[i]) for i=1:S.n]::Array{Bool,1})
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
  J = Array{Int64,1}(undef,0)
  for i in id
    j = findlast(S.id.==i)
    (j > 0) && push!(J,j)
  end
  deleteat!(S, J)
  return nothing
end

# Delete by Regex match or exact ID match
delete!(S::SeisData, r::Regex)          = deleteat!(S, findall([occursin(r, i) for i in S.id]))
delete!(S::SeisData, s::String)         = (i = findlast(S.id.==s); (i > 0) && deleteat!(S, i))

# Nothing more than aliasing, really
delete!(S::SeisData, j::Int)            = deleteat!(S, j)
delete!(S::SeisData, J::UnitRange)      = deleteat!(S, J)
delete!(S::SeisData, J::Array{Int,1})   = deleteat!(S, J)

# Subtraction
-(S::SeisData, i::Int)          = (U = deepcopy(S); deleteat!(U,i); return U)  # By channel #
-(S::SeisData, J::Array{Int,1}) = (U = deepcopy(S); deleteat!(U,J); return U)  # By array of channel #s
-(S::SeisData, J::AbstractRange)= (U = deepcopy(S); deleteat!(U,J); return U)  # By range of channel #s
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
function pull(S::SeisData, J::Array{Integer,1})
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
sort(S::SeisData; rev=false::Bool) = (T = deepcopy(S); j = sortperm(T.id, rev=rev); [setfield!(T,i,getfield(T,i)[j]) for i in datafields]; return(T))
