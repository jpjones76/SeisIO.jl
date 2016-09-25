# To do: Abstract type
using DSP: resample, tukey
import Base.in
import Base:getindex, setindex!, append!, deleteat!, delete!, +, -, isequal,
search, push!, merge!,  length, start, done, next, size, sizeof, ==,
filter, filt!, sort!, sort #, isempty

# No way to define a SeisData as an array of SeisObj's; indexing relations
# become impossible. BUT we CAN define a SeisObj as a degenerate single-channel
# SeisData instance
"""
    S = SeisObj()

Create a single channel instance of univariate geophysical data. See
documentation for information on fields.
"""
type SeisObj
  name::String
  id::String
  fs::Float64
  gain::Float64
  loc::Array{Float64,1}
  misc::Dict{String,Any}
  notes::Array{String,1}
  resp::Array{Complex{Float64},2}
  src::String
  t::Array{Int64,2}
  x::Array{Float64,1}
  units::String

  SeisObj(;name=""::String,
          id=""::String,
          fs=0.0::Float64,
          gain=1.0::Float64,
          loc=Array{Float64,1}()::Array{Float64,1},
          misc=Dict{String,Any}()::Dict{String,Any},
          notes=Array{String,1}()::Array{String,1},
          resp=Array{Complex{Float64},2}(0,2)::Array{Complex{Float64},2},
          src=""::String,
          t=Array{Int64,2}(0,2)::Array{Int64,2},
          x=Array{Float64,1}()::Array{Float64,1},
          units=""::String) = begin
     return new(name, id, fs, gain, loc, misc, notes, resp, src, t, x, units)
  end
end


"""
    S = SeisData()

Create a multichannel structure for univariate geophysical data. A SeisData
structure has the same fields as a SeisObj, but they cannot be set at creation.

"""
type SeisData
  n::Int64
  name::Array{String,1}                       # name
  id::Array{String,1}                         # id
  fs::Array{Float64,1}                        # fs
  gain::Array{Float64,1}                      # gain
  loc::Array{Array{Float64,1},1}              # loc
  misc::Array{Dict{String,Any},1}             # misc
  notes::Array{Array{String,1},1}             # notes
  resp::Array{Array{Complex{Float64},2},1}    # resp
  src::Array{String,1}                        # src
  t::Array{Array{Int64,2},1}                  # time
  x::Array{Array{Float64,1},1}                # data
  units::Array{String,1}                      # units

  SeisData(;
    n=0::Int64,
    name=Array{String,1}(),                   # name
    id=Array{String,1}(),                     # id
    fs=Array{Float64,1}(),                    # fs
    gain=Array{Float64,1}(),                  # gain
    loc=Array{Array{Float64,1},1}(),          # loc
    misc=Array{Dict{String,Any},1}(),         # misc
    notes=Array{Array{String,1},1}(),         # notes
    resp=Array{Array{Complex{Float64},2},1}(),# resp
    src=Array{String,1}(),                    # src
    t=Array{Array{Int64,2},1}(),              # time
    x=Array{Array{Float64,1},1}(),            # data
    units=Array{String,1}()                   # units
    ) = begin
      return new(n, name, id, fs, gain, loc, misc, notes, resp, src, t, x, units)
  end

  function SeisData(T...)
    S = SeisData()
    for i = 1:1:length(T)
      if isa(T[i],SeisObj) || isa(T[i],SeisData)
        merge!(S, T[i])
      else
        warn(string("Tried to join non-SeisObj into SeisData (arg",
          @sprintf("%i", i), "); skipped."))
      end
    end
    return S
  end
end

# don't include S.n when looping over the arrays of S
datafields(S::Union{SeisObj,SeisData}) = (filter(i -> i ∉ [:n], fieldnames(S)))
headerfields(S::Union{SeisObj,SeisData}) = (filter(i ->
  i ∉ [:n, :name, :t, :x, :misc, :notes, :src], fieldnames(S)))

# ============================================================================
# Indexing, search, iteration, size
# s = S[j] returns a SeisObj struct
# s = S[i:j] returns a SeisData struct
# S[i:j].foo = bar won't work

# Array of hashes for each header field
function headerhash(S::Union{SeisData,SeisObj})
  F = headerfields(S)
  N = isa(S,SeisObj) ? 1 : S.n
  H = Array{UInt64,2}(length(F), N)
  for (i,v) in enumerate(F)
    F = getfield(S, v)
    for n = 1:N
      H[i,n] = hash(F[n])
    end
  end
  return H
end

# alias "in" to match on ID
in(id::AbstractString, S::SeisData) = in(id, S.id)
findname(n::AbstractString, S::SeisData) = findfirst(S.name .== n)
findname(S::SeisData, n::AbstractString) = findfirst(S.name .== n)
findid(n::AbstractString, S::SeisData) = findfirst(S.id .== n)
findid(S::SeisData, n::AbstractString) = findfirst(S.id .== n)
findid(S::SeisData, T::SeisObj) = findfirst(S.id .== T.id)
hasid(id::AbstractString, S::SeisData) = in(id, S.id)
hasname(name::AbstractString, S::SeisData) = in(name, S.name)

# getindex returns a SeisObj
function getindex(S::SeisData, J::Union{Range,Array{Integer,1}})
  isa(J, Range) && (J = collect(J))
  T = SeisData()
  local U = deepcopy(S)
  [push!(T, U[j]) for j in J]
  return T
end

# I can only make this work with a dict
function getindex(S::SeisData, j::Int)
  A = Dict{String,Any}()
  [A[string(v)] = deepcopy(getfield(S, v)[j]) for v in datafields(S)]
  return SeisObj(name=A["name"],
                 id=A["id"],
                 fs=A["fs"],
                 gain=A["gain"],
                 loc=A["loc"],
                 misc=A["misc"],
                 notes=A["notes"],
                 resp=A["resp"],
                 src=A["src"],
                 t=A["t"],
                 x=A["x"],
                 units=A["units"])
end

# overwrite a SeisData channel with a SeisObj
setindex!(S::SeisData, T::SeisObj, i::Int) =
  ([S.(v)[i] = T.(v) for v in datafields(T)])

# overwrite a range of SeisData channels with another SeisData struct
function setindex!(S::SeisData, T::SeisData, I::Range)
  length(I) != T.n && error("Range of indices exceeds size of T")
  for value in datafields(T)
    for (i,j) in enumerate(I)
      S.(value)[j] = T.(value)[i]
    end
  end
  return S
end

#isempty(t::SeisObj) = minimum([isempty(t.(i)) for i in fieldnames(t)])
#isempty(t::SeisData) = (t.n == 0)
length(t::SeisData) = t.n
size(S::SeisData) = println(summary(S))
function sizeof(S::SeisData)
  #   n   fs=1, gain=1, loc=5, name=26, id=15, units=26, src=26
  n = 1 + S.n*100
  for i = 1:S.n
    n += (sizeof(S.resp[i]) + sizeof(S.t[i]) + sizeof(S.x[i]))
    K = sort(collect(keys(S.misc[i])))
    n += length(join(K,","))
    for k in K
      v = S.misc[i][k]
      if isa(v, Array)
        if isa(v[1], AbstractString)
          n += length(join(v[:]))
        elseif isa(v[1], Number)
          n += sizeof(v)
        end
      elseif isa(v, Number)
        n += sizeof(v)
      elseif isa(v, AbstractString)
        n += length(v)
      end
    end
  end
  return n
end
function sizeof(S::SeisObj)
  #   fs=1, gain=1, loc=5, name=12, id=15, units=16, src=16
  n = 100 + sizeof(S.resp) + sizeof(S.t) + sizeof(S.x)
  K = sort(collect(keys(S.misc)))
  n += length(join(K,","))
  for k in K
    v = S.misc[k]
    if isa(v, Array)
      if isa(v[1], AbstractString)
        n += length(join(v[:]))
      elseif isa(v[1], Number)
        n += sizeof(v)
      end
    elseif isa(v, Number)
      n += sizeof(v)
    elseif isa(v, AbstractString)
      n += length(v)
    end
  end
  return n
end


#start(S::SeisData) = 1
#done(S::SeisData) = i > S.n
#next(S::SeisData, i) = # ...um

# ============================================================================
# Logging
note(S::SeisObj, s::AbstractString) = (S.notes = cat(1, S.notes,
  string(now(), "  ", s)))
note(S::SeisData, i::Integer, s::AbstractString) = (
    push!(S.notes[i], string(now(), "  ", s)))
note(S::SeisData, s1::AbstractString, s2::AbstractString) = note(S, findname(s1, S), s2)

# ============================================================================
# Equality
isequal(S::SeisObj, T::SeisObj) = (
  minimum([isequal(hash(getfield(S,v)), hash(getfield(T,v)))
    for v in fieldnames(S)]))
isequal(S::SeisData, T::SeisData) = (
  minimum([isequal(hash(getfield(S, v)), hash(getfield(T, v)))
    for v in fieldnames(S)]))

# In case all we care about is a header match
samehdr(S::SeisObj, T::SeisObj) = (
  minimum([isequal(hash(getfield(S,v)), hash(getfield(T,v)))
    for v in headerfields(S)]))
samehdr(S::SeisData, T::SeisObj, i) = (
  minimum([isequal(hash(getfield(S, v)[i]), hash(getfield(T, v)))
    for v in headerfields(S)])) # this might be useless
# ============================================================================

# ============================================================================
# Append, delete
push!(S::SeisData, T::SeisObj) = ([push!(S.(i),T.(i)) for i in fieldnames(T)]; S.n += 1)
append!(S::SeisData, T::SeisData) = ([push!(S,T[i]) for i = 1:S.n])
deleteat!(S::SeisData, j::Int) = ([deleteat!(S.(i),j) for i in datafields(S)];
  S.n -= 1; return S)
deleteat!(S::SeisData, J::Range) = (collect(J); [deleteat!(S, j)
  for j in sort(J, rev=true)]; return S)
deleteat!(S::SeisData, J::Array{Int,1}) = ([deleteat!(S, j)
  for j in sort(J, rev=true)]; return S)
delete!(S::SeisData, j::Int) = deleteat!(S, j)
delete!(S::SeisData, J::Range) = deleteat!(S, J)
delete!(S::SeisData, J::Array{Int,1}) = deleteat!(S, J)

# ============================================================================
# Merge and extract
# Dealing with sparse time difference representations


"""
    merge!(S::SeisObj, T::SeisObj)

Merge two SeisObj structures. For data points, a single-pass merge-and-prune
operation is applied to data value pairs whose timestamps are separated by less
than half the sampling interval; times ti, tj corresponding to merged samples
xi, xj are averaged.
"""
function merge!(S::SeisObj, U::SeisObj)
  S.id == U.id || error("Channel header mismatch!")

  # Empty channel(s)
  isempty(U.x) && (return S)
  isempty(S.x) && ([S.(i) = deepcopy(U.(i)) for i in fieldnames(S)]; return S)

  # Two full channels
  S.fs != U.fs && error("Sampling frequency mismatch; correct manually.")
  T = deepcopy(U)
  if !isapprox(S.gain,T.gain)
    (T.x .*= (S.gain/T.gain); T.gain = copy(S.gain))      # rescale T.x to match S.x
  end
  (S.t, S.x) = xtmerge(S.t, S.x, T.t, T.x, T.fs)          # merge time and data
  merge!(S.misc, T.misc)                                  # merge misc
  S.notes = cat(1, S.notes, T.notes)                      # merge notes
  note(S, @sprintf("Merged %i samples", length(T.x)))
  return S
end
merge(S::SeisObj, T::SeisObj) = (U = deepcopy(S); merge!(S,T); return(S))

"""
    merge!(S::SeisData, T::SeisObj)

Merge a SeisObj structure into a SeisData structure.
"""
function merge!(S::SeisData, U::SeisObj)
  isempty(U.x) && return S
  i = find(S.id .== U.id)
  (isempty(i) || isempty(S.x)) && return push!(S, U)
  i = i[1]
  S.fs[i] != U.fs && return push!(S,U)
  T = deepcopy(U)
  if !isapprox(S.gain[i],T.gain)
    (T.x .*= (S.gain[i]/T.gain); T.gain = copy(S.gain[i]))        # rescale T.x to match S.x
  end
  (S.t[i], S.x[i]) = xtmerge(S.t[i], S.x[i], T.t, T.x, T.fs)      # time, data
  merge!(S.misc[i], T.misc)                                       # misc
  S.notes[i] = cat(1, S.notes[i], T.notes)                        # notes
  note(S, i, @sprintf("Merged %i samples", length(T.x)))
  return S
end

"""
    merge!(S::SeisData, T::SeisData)

Merge SeisData structure `T` into SeisData structure `S`. If multiple channels
of `S` have identical headers to channel `T[i]`, `T[i]` is only merged into the
first match.
"""
function merge!(S::SeisData, T::SeisData)
  isempty(T.x) && (return S)
  for i = 1:T.n
    try
      merge!(S, T[i])
    catch err
      warn(err)
      push!(S, T[i])
    end
  end
  return S
end

# Extract to SeisObj
"""
    T = pull(S::SeisData, n::String)

Extract the first channel named `n` from `S` and return it as a SeisObj structure.

    T = pull(S::SeisData, i::integer)

Extract channel `i` from `S` as a SeisObj.
"""
pull(S::SeisData, n::String) = (i = findname(n, S); T = getindex(S, i);
  delete!(S,i); note(T, "Extracted from a SeisData object"); return T)
pull(S::SeisData, i::Integer) = (T = getindex(S, i); delete!(S,i);
  note(T, "Extracted from a SeisData object"); return T)

# ============================================================================
# Arithmetic operations

# Adding a SeisObj to SeisData merges it
+(S::SeisData, T::SeisObj) = (U = deepcopy(S); merge!(U,T); return U)
+(S::SeisData, T::SeisData) = (U = deepcopy(S); merge!(U,T); return U)
function +(S::SeisObj, T::SeisObj)
  if S.id == T.id
    U = deepcopy(S)
    return merge!(U,T)
  else
    return SeisData(S, T)
  end
end

# Adding a string to SeisData writes a note; if the string begins with a
# channel name, the note is restricted to the given channel, else it's
# added to all channels
function +(S::SeisData, s::String)
  local T = deepcopy(S)
  name,note = split(s, r"[:]", limit=2)
  t = split(string(now()), 'T')[2]
  try
    i = findname(name, S)
    cat(1, T.notes[i], string(t, "  ", note))
  catch
    try
      i = findid(name, S)
      cat(1, T.notes[i], string(t, "  ", note))
    catch
      [cat(1, T.notes[i], string(t, "  ", note)) for i in 1:S.n]
    end
  end
  return T
end

# Adding a string to a SeisObj simply appends it to the "notes" setion
+(S::SeisObj, s::String) = cat(1, S.notes, string(string(now()), 'T')[2], "  ", s)

# Rules for deleting
-(S::SeisData, i::Int) = deleteat!(S,i)                       # By channel #
-(S::SeisData, J::Array{Int64,1}) = deleteat!(S,J)            # By array of channel #s
-(S::SeisData, J::Range) = deleteat!(S,J)                     # By range of channel #s
-(S::SeisData, str::String) = ([deleteat!(S,k) for k in unique([find(S.id .== str); find(S.name .== str)])]; return S) #Name or ID match
-(S::SeisData, T::SeisObj) = ([deleteat!(S,i) for i in find(S.id .== T.i)]; return S) # By SeisObj

# Tests for equality
==(S::SeisObj, T::SeisObj) = isequal(S,T)
==(S::SeisData, T::SeisData) = isequal(S,T)

# Sorting
"""
    sort!(S, [rev=false])

In-place sort of channels in SeisData object S by S.id. Specify rev=true
to reverse the sort order.
"""
sort!(S::SeisData; rev=false) = (j = sortperm(S.id, rev=rev);
  [S.(i) = S.(i)[j] for i in datafields(S)])

"""
    T = sort(S, [rev=false])

Sort channels in SeisData object S by S.id. Specify rev=true for reverse order.
"""
sort(S::SeisData; rev=false) = (T = deepcopy(S); j = sortperm(T.id, rev=rev);
  [T.(i) = T.(i)[j] for i in datafields(T)]; return(T))
