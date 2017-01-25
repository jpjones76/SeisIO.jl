import Base:in, getindex, setindex!, append!, deleteat!, delete!, +, -, isequal,
merge!, merge, length, start, done, next, size, sizeof, ==, isempty

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
    t = timestamp()
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
      collect(repeated("....",n)),
      collect(repeated(zeros(Float64,5),n)),
      collect(repeated(0.0,n)),
      collect(repeated(1.0,n)),
      collect(repeated(Array{Complex{Float64}}(0,2),n)),
      collect(repeated("",n)),
      misc,
      notes,
      src,
      collect(repeated(Array{Int64,2}(0,2),n)),
      collect(repeated(Array{Float64,1}(0),n)))
  end

  function SeisData(U...)
    S = SeisData()
    for i = 1:1:length(U)
      if isa(U[i],SeisData)
        merge!(S, U[i])
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

function getindex(S::SeisData, J::Array{Int,1})
  U = SeisData()
  [setfield!(U, f, getfield(S,f)[J]) for f in datafields]
  setfield!(U, :n, length(J))
  return U
end
getindex(S::SeisData, J::UnitRange) = getindex(S, collect(J))

in(s::String, S::SeisData) = in(s, S.id)
findid(n::String, S::SeisData) = findfirst(S.id .== n)
findid(S::SeisData, n::String) = findfirst(S.id .== n)
findid(S::SeisData, T::SeisData) = [findfirst(S.id .== T.id[i]) for i=1:1:T.n]
hasid(s::String, S::SeisData) = in(s, S.id)
hasname(s::String, S::SeisData) = in(s, S.name)

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
# Append, delete, sort
append!(S::SeisData, U::SeisData)  = (
  [setfield!(S, i, append!(getfield(S,i), getfield(U,i))) for i in datafields];
  S.n += U.n;
  return S)

# Delete methods are aliased to -
deleteat!(S::SeisData, j::Int)          = ([deleteat!(getfield(S, i),j) for i in datafields]; S.n -= 1; return S)
deleteat!(S::SeisData, J::UnitRange)    = (collect(J); [deleteat!(S, j) for j in sort(J, rev=true)]; return S)
deleteat!(S::SeisData, J::Array{Int,1}) = ([deleteat!(S, j) for j in sort(J, rev=true)]; return S)
delete!(S::SeisData, j::Int)            = deleteat!(S, j)
delete!(S::SeisData, J::UnitRange)      = deleteat!(S, J)
delete!(S::SeisData, J::Array{Int,1})   = deleteat!(S, J)
delete!(S::SeisData, r::Regex)          = deleteat!(S, find([ismatch(r, i) for i in S.id]))
delete!(S::SeisData, s::String)         = delete!(S, Regex(s))
-(S::SeisData, i::Int)                  = deleteat!(S,i)  # By channel #
-(S::SeisData, J::Array{Int,1})         = deleteat!(S,J)  # By array of channel #s
-(S::SeisData, J::Range)                = deleteat!(S,J)  # By range of channel #s
-(S::SeisData, s::String)               = delete!(S,s)    # By channel id string
-(S::SeisData, r::Regex)                = delete!(S,r)    # By channel id regex

# Extract
"""
    T = pull(S::SeisData, n::String)

Extract the first channel named `n` from `S` and return it as a new SeisData structure. The corresponding channel in `S` is deleted.

    T = pull(S::SeisData, i::integer)

Extract channel `i` from `S` as a new SeisData struct, deleting it from `S`.
"""
pull(S::SeisData, n::String) = (i = findid(n, S); T = deepcopy(getindex(S, i));
  deleteat!(S,i); note!(T,"Extracted from another SeisData object"); return T)
pull(S::SeisData, J::UnitRange) = (T = deepcopy(getindex(S, J)); deleteat!(S,J);
    note!(T,"Extracted from a SeisData object"); return T)
pull(S::SeisData, J::Array{Integer,1}) = (T = deepcopy(getindex(S, J)); deleteat!(S,J);
        note!(T,"Extracted from a SeisData object"); return T)


# Sorting
"""
chansort!(S::SeisData, [rev=false])

In-place sort of channels in object S by `S.id`. Specify `rev=true` to reverse the sort order.
"""
function chansort!(S::SeisData; rev=false::Bool)
  j = sortperm(S.id, rev=rev)
  [setfield!(S,i,getfield(S,i)[j]) for i in datafields]
  return S
end
chansort(S::SeisData; rev=false::Bool) = (T = deepcopy(S); j = sortperm(T.id, rev=rev); [setfield!(T,i,getfield(T,i)[j]) for i in datafields]; return(T))

# ============================================================================
# Merge and extract
# Dealing with sparse time difference representations

"""
    merge!(S::SeisData, U::SeisData)

Merge two SeisData structures. For timeseries data, a single-pass merge-and-prune operation is applied to value pairs whose sample times are separated by less than half the sampling interval; pairs of non-NaN x_i, x_j with |t_i-t_j| < (1/2*S.fs) are averaged.

`merge!` always invokes `chansort!` to ensure the "+" operator is commutative.
"""
function merge!(S::SeisData, U::SeisData)
  J = Array{Int64,1}()
  for j = 1:1:U.n
    merged = false
    for i = 1:1:S.n
      if S.id[i] == U.id[j]
        # Merge condition: same fs, neither empty
        if S.fs[i] == U.fs[j] && !isempty(U.x[j]) && !isempty(S.x[i])
          x = deepcopy(U.x[j])::Array{Float64,1}
          if S.gain[i] != U.gain[j]
            x = x.*(S.gain[i]/U.gain[j])
          end
          V = xtmerge(S.t[i], U.t[j], S.x[i], x, S.fs[i])
          S.t[i] = deepcopy(V[1])
          S.x[i] = deepcopy(V[2])
          merge!(S.misc[i], U.misc[j])
          S.notes[i] = Array{String,1}([S.notes[i]; U.notes[j]])
          notestr = string("Merged ", length(x), " samples")
          if S.name[i] != U.name[j]
            notestr = string(notestr, " (pre-merge channel name was ",U.name[j],")")
          end
          note!(S, i, notestr)
          merged = true

        # Replace an empty S.x with the corresponding U.x
        elseif isempty(S.x[i])
          S.x[i]    = deepcopy(U.x[j])
          S.t[i]    = deepcopy(U.t[j])
          S.fs[i]   = copy(U.fs[j])
          S.gain[i] = copy(U.gain[j])
          merged = true

        # Warn if U.x is empty, but do nothing else
        elseif isempty(U.x[j])
          warn(string("Trying to merge empty (dataless) channel ", U.id[j], "; ignored."))
          merged = true

        # Warn of possibly strange behavior with inequal fs
        elseif S.fs[i] != U.fs[j]
          warn(string("Tried to merge two of ", U.id[j], " with different fs values; the second will be appended."))
        end
        if !isempty(U.src[j])
          note!(S, string("+src:", U.src[j]))
        end
      end
    end
    # If still unmerged at i=S.n, push index to J
    if !merged
      push!(J,j)
    end
  end
  if !isempty(J)
    append!(S, U[J])
  end
  return chansort!(S)
end

merge(S::SeisData, U::SeisData) = (return merge!(deepcopy(S),U))
+(S::SeisData, U::SeisData) = (return merge!(S,U))

# ============================================================================
# Annotation
function tnote(s::String)
  str = string(timestamp(), ": ", s)
  L = min(length(str),256)
  return str[1:L]
end

# Adding a string to SeisData writes a note; if the string mentions a channel
# name or ID, the note is restricted to the given channels(s), else it's
# added to all channels
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
