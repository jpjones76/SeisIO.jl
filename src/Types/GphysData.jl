export GphysData, findid, findchan, prune, prune!, pull

abstract type GphysData end

"""
    findid(id::String, S::GphysData)
    findid(S::GphysData, id::String)

Get the index of the first channel in S where `id.==S.id` is true. Returns 0
for failure.

    findid(S::GphysData, T::GphysData)

Get index corresponding to the first channel in T that matches each ID in S;
equivalent to [findid(id,T) for id in S.id].
"""
function findid(id::Union{Regex,String}, S::T) where {T<:GphysData}
  j=0
  for i=1:length(S.id)
    if S.id[i] == id
      j=i
      break
    end
  end
  return j
end
findid(S::T, id::Union{String,Regex})  where {T<:GphysData} = findid(id, S)
findid(S::T, U::T) where {T<:GphysData} = [findid(id, U) for id in getfield(S,:id)]
# DND ...why the fuck is findfirst so fucking slow?!

"""
    findchan(id::String, S::GphysData)

Get all channel indices `i` in S with id ∈ S.id[i]
"""
findchan(r::Union{Regex,String}, S::GphysData) = findall([occursin(r, i) for i in getfield(S, :id)])

# Extract
"""
    T = pull(S::SeisData, id::String)

Extract the first channel with id=`id` from `S` and return it as a new SeisChannel structure. The corresponding channel in `S` is deleted.

    T = pull(S::SeisData, i::Union{Integer, UnitRange, Array{In64,1}}

Extract channel `i` from `S` as a new SeisChannel struct, deleting it from `S`.
"""
function pull(S::T, s::String) where {T<:GphysData}
  i = findid(S, s)
  U = deepcopy(getindex(S, i))
  deleteat!(S, i)
  return U
end
function pull(S::T, J::UnitRange) where {T<:GphysData}
  U = deepcopy(getindex(S, J))
  deleteat!(S, J)
  return U
end
function pull(S::T, J::Array{Int64,1}) where {T<:GphysData}
  U = deepcopy(getindex(S, J))
  deleteat!(S, J)
  return U
end
function pull(S::T, i::Integer) where {T<:GphysData}
  C = deepcopy(getindex(S, i))
  deleteat!(S, i)
  return C
end

# ============================================================================
# Indexing, searching, iteration, size
# s = S[j] returns a SeisChannel struct
# s = S[i:j] returns a SeisData struct
# S[i:j].foo = bar won't work

lastindex(S::T) where {T<:GphysData} = getfield(S, :n)
firstindex(S::T) where {T<:GphysData} = 1
size(S::T) where {T<:GphysData} = (getfield(S, :n),)
in(s::String, S::GphysData) = in(s, getfield(S, :id))

function getindex(S::T, J::Array{Int,1}) where {T<:GphysData}
  n = getfield(S, :n)
  U = T()
  F = fieldnames(T)
  # ([(getfield(S, f))[J] = getfield(U, f) for f in datafields])
  for f in F
    if (f in unindexed_fields) == false
      setfield!(U, f, getindex(getfield(S, f), J))
    end
  end
  setfield!(U, :n, lastindex(J))
  return U
end
getindex(S::GphysData, J::UnitRange) = getindex(S, collect(J))

function setindex!(S::T, U::T, J::Array{Int,1}) where {T<:GphysData}
  typeof(S) == typeof(U) || throw(MethodError)
  length(J) == U.n || throw(BoundsError)
  F = fieldnames(T)
  for f in F
    if (f in unindexed_fields) == false
      setindex!(getfield(S, f), getfield(U, f), J)
    end
  end
  # ([(getfield(S, f))[J] = getfield(U, f) for f in datafields])
  return nothing
end
setindex!(S::GphysData, U::GphysData, J::UnitRange) = setindex!(S, U, collect(J))

@doc """
    sort!(S::SeisData, [rev=false])

In-place sort of channels in object S by `S.id`. Specify `rev=true` to reverse the sort order.

    sort(S::SeisData, [rev=false])

Sort channels in object S by `S.id`. Specify `rev=true` to reverse the sort order.
""" sort!
function sort!(S::T; rev=false::Bool) where {T<:GphysData}
  j = sortperm(getfield(S, :id), rev=rev)
  F = fieldnames(T)
  for f in F
    if (f in unindexed_fields) == false
      setfield!(S, f, getfield(S,f)[j])
    end
  end
  return nothing
end

@doc (@doc sort!)
function sort(S::T; rev=false::Bool) where {T<:GphysData}
  U = deepcopy(S)
  sort!(U, rev=rev)
  return U
end

isempty(S::T) where {T<:GphysData} = (S.n == 0) ? true : minimum([isempty(getfield(S,f)) for f in fieldnames(T)])

function isequal(S::T, U::T) where {T<:GphysData}
  q = true
  F = fieldnames(T)
  for f in F
    if f != :notes
      q = min(q, getfield(S,f) == getfield(U,f))
    end
  end
  return q
end
==(S::T, U::T) where {T<:GphysData} = isequal(S,U)

# Append, add, delete, sort
function append!(S::T, U::T) where {T<:GphysData}
  F = fieldnames(T)
  for f in F
    if (f in unindexed_fields) == false
      append!(getfield(S, f), getfield(U, f))
    end
  end
  S.n += U.n
  return nothing
end

# ============================================================================
# deleteat!
function deleteat!(S::T, j::Int) where {T<:GphysData}
  F = fieldnames(T)
  for f in F
    if (f in unindexed_fields) == false
      deleteat!(getfield(S, f), j)
    end
  end
  S.n -= 1
  return nothing
end

function deleteat!(S::T, J::Array{Int,1}) where {T<:GphysData}
  sort!(J)
  F = fieldnames(T)
  for f in F
    if (f in unindexed_fields) == false
      deleteat!(getfield(S, f), J)
    end
  end
  S.n -= lastindex(J)
  return nothing
end

deleteat!(S::T, K::UnitRange) where {T<:GphysData} = deleteat!(S, collect(K))

@doc """
    prune!(S::SeisData)

Delete all channels from S that have no data (i.e. S.x is empty or non-existent).
""" prune!
function prune!(S::GphysData)
  n = getfield(S, :n)
  klist = Array{Int64,1}(undef, 0)
  sizehint!(klist, n)
  T = getfield(S, :t)
  X = getfield(S, :x)
  i = 0
  while i < n
    i = i+1

    # non-empty X with empty T should be rare
    if isempty(getindex(X, i))
      push!(klist, i)
    elseif isempty(getindex(T, i))
      push!(klist, i)
    end

  end

  deleteat!(S, klist)
  return nothing
end
@doc (@doc prune!)
prune(S::T) where {T<:GphysData} = prune!(deepcopy(S))
# ============================================================================
# delete!
function delete!(S::T, s::Union{Regex,String}; exact=true::Bool) where {T<:GphysData}
  if exact
    i = findid(S, s)
    deleteat!(S, i)
  else
    deleteat!(S, findchan(s,S))
  end
  return nothing
end

# With this convention, S+U-U = S
function delete!(S::T, U::T) where {T<:GphysData}
  id = reverse(getfield(U, :id))
  J = Array{Int64,1}(undef,0)
  for i in id
    j = findlast(S.id.==i)
    (j == nothing) || push!(J, j)
  end
  deleteat!(S, J)
  return nothing
end

-(S::T, r::Union{Regex,String}) where {T<:GphysData} = (U = deepcopy(S); delete!(U,r); return U) # By channel id regex or string
-(S::T, U::T) where {T<:GphysData} = (S2 = deepcopy(S); delete!(S2, U); return S2)                # Remove all channels with IDs in one SeisData from another

# Purpose: deal with intentional overly-generous "resize!" when parsing SEED
function trunc_x!(S::GphysData)
  n = getfield(S, :n)
  X = getfield(S, :x)
  T = getfield(S, :t)
  for i = 1:n
    t = getindex(T, i)
    L = size(t, 1)
    if L == 0
      setindex!(X, Array{Float64,1}(undef, 0), i)
    else
      x = getindex(X, i)
      nx = t[L,1]
      if length(x) > nx
        resize!(x, nx)
      end
    end
  end
  return nothing
end

function namestrip!(S::GphysData)
  names = getfield(S, :name)
  for (i, name) in enumerate(names)
    setindex!(names, namestrip(name), i)
  end
  return nothing
end

# Create end times from t, fs, x
function mk_end_times(S::GphysData)
  n = length(S.fs)
  ts = Int64[S.t[j][1,2] for j=1:n]
  te = copy(ts)
  @inbounds for j = 1:n
    tt = view(S.t[j], :, 2)
    if S.fs[j] == 0.0
      te[j] = last(tt)
    else
      te[j] = sum(tt) + round(Int64, sμ*length(S.x[j])/S.fs[j])
    end
  end
  return ts, te
end
