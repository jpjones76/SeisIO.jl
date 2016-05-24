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

Create a single channel instance of univariate geophysical data. A SeisObj has
the following fields, which can be set by name at creation; for example,
T = SeisObj(gain=1.0e6) creates a SeisObj with T.gain = 1.0e6.

* name: ASCIIString. Freeform; strings > 26 characters long cannot be saved to
SeisData files.
* id: ASCIIString. ID must follow the convention `net`.`sta`.`loc`.`chan`;
If unsure of a value, leave it blank.
+ `network` is a 2-character network code.
+ `station` is a 5-character (maximum) station code. For strict compliance with
SEED standards, station codes shouldn't contain punctuation or non-standard
characters.
+ `loc` is a 2-character SEED-style location code. Not widely used.
+ `chan` is a 3-character channel code. If you only know the orientation, try
`getbandcode(fs)` for the first character; if you also know the critical
frequency FC, `getbandcode(fs, fc=FC)`.
* fs: Float64. Sampling frequency in Hz.
+ For irregularly sampled data, such as "campaign" style gas flux, set fs = 0.
* gain: Float64. Stage 0 scalar gain.
* loc: 5-element vector. The first three elements should be [latitude [°N],
longitude [°E], elevation [m]]. For data channels from a three-component
seismometer with orthogonal channels, loc[4] should be the azimuth of the
horizontal components [N°E]; loc [5] should be the incidence angle of the
vertical component [° from vertical].
* misc: Dictionary with ASCII keys. Can hold any type of value, but only
characters, strings, numbers, and arrays will be saved to/read from file.
* notes: An array of strings. A log of channel information as data is processed.
The command `note` appends a timestamped note.
* resp: Instrument frequency response, given as a matrix with complex zeros in
the first column and complex poles in the second.
* src: ASCII string. The source of the data. Normally this is filled in
automatically when data are loaded in.
* t: Sparse two-column array of delta-encoded times.
+ For regularly sampled data (S.fs > 0), the first column gives the index
in the data (S.x) of the first value after each time gap. The second column
gives the gap length in seconds.
+ For irregularly sampled data (S.fs == 0), the first column is meaningless;
the second column gives delta-encoded sample times.
+ For all data, S.t[1,2] is the start of the time series, measured from Unix
Epoch time (1 January 1970).
* x: Array of data points.
* units: Freeform string with the unit type.
"""
type SeisObj
  name::ASCIIString
  id::ASCIIString
  fs::Float64
  gain::Float64
  loc::Array{Float64,1}
  misc::Dict{ASCIIString,Any}
  notes::Array{ASCIIString,1}
  resp::Array{Complex{Float64},2}
  src::ASCIIString
  t::Array{Float64,2}
  x::Array{Float64,1}
  units::ASCIIString

  SeisObj(;name=""::ASCIIString,
          id=""::ASCIIString,
          fs=0.0::Float64,
          gain=1.0::Float64,
          loc=Array{Float64,1}()::Array{Float64,1},
          misc=Dict{ASCIIString,Any}()::Dict{ASCIIString,Any},
          notes=Array{ASCIIString,1}()::Array{ASCIIString,1},
          resp=Array{Complex{Float64},2}(0,2)::Array{Complex{Float64},2},
          src=""::ASCIIString,
          t=Array{Float64,2}(0,2)::Array{Float64,2},
          x=Array{Float64,1}()::Array{Float64,1},
          units=""::ASCIIString) = begin
     return new(name, id, fs, gain, loc, misc, notes, resp, src, t, x, units)
  end
end


"""
    S = SeisData()

Create a multichannel structure for univariate geophysical data. A SeisData
structure has the same fields as a SeisObj, but they cannot be set at creation.
See the help for `SeisObj` for details of field names and meanings.

### Creating and modifying SeisData structures
You can create a SeisData structure piecewise from individual channels by
concatenating SeisObj structures:
* `S = SeisData(SeisObj(name="BRASIL"), SeisObj(name="UKRAINE"), SeisObj())``
**creates** a new SeisData structure with three channels; the first is named
"BRASIL", the second "UKRAINE", the third is blank.
* You can **merge** SeisObj and SeisData structures into existing SeisData
structures with the addition operator. `S = SeisData(); T = SeisObj(); S += T`
merges T into S.
+ If a merged SeisObj structure has the same ID field as a channel in an existing
SeisData structure, the data are meged using the `.t` fields. Data pairs separated
by less than half the sampling interval are *averaged*.
+ To append a SeisObj `T` as a new channel in `S` without merging, use `append!(S,T)`.
+ You can create a new SeisData structure by adding two or more SeisObj instances
together, e.g. `S = SeisObj(); T = SeisObj(); U = SeisObj(); R = S + T + U`
* You can **remove** a channel from a SeisData structure in three ways:
+ `T = S[i]` creates a SeisObj out of all data in channel `i` of `S`;
`T = S[i1:i2]` creates a SeisData object from multiple channels. Both methods
leave S intact.
+ `S -= i`, where `i` is an integer, deletes channel `i` from S.
+ `T = pull(S, name)`, where `name` is a string, creates a SeisObj `T` from
the first channel with name=`name`. The channel is removed from `S`.
+ `T = pull(S, i)`, where `i` is an integer, creates a SeisObj `T` from
channel `i` and removes channel `i` from `S`.

### Differences between SeisData and SeisObj interactions
* The command `note(S, i, [note])` adds a timestamped note to channel `i` of `S`.
* The command `S += "[name]: [note]"`, adds a note with a short form date.
* The command `S += "[note]"` adds a note with short-form date to all channels.
"""
type SeisData
  n::Int64
  name::Array{ASCIIString,1}                   # name
  id::Array{ASCIIString,1}                     # id
  fs::Array{Float64,1}                         # fs
  gain::Array{Float64,1}                       # gain
  loc::Array{Array{Float64,1},1}               # loc
  misc::Array{Dict{ASCIIString,Any},1}         # misc
  notes::Array{Array{ASCIIString,1},1}         # notes
  resp::Array{Array{Complex{Float64},2},1}     # resp
  src::Array{ASCIIString,1}                    # src
  t::Array{Array{Float64,2},1}                 # time
  x::Array{Array{Float64,1},1}                 # data
  units::Array{ASCIIString,1}                  # units

  SeisData(;
    n=0::Int64,
    name=Array{ASCIIString,1}(),                  # name
    id=Array{ASCIIString,1}(),                    # id
    fs=Array{Float64,1}(),                        # fs
    gain=Array{Float64,1}(),                      # gain
    loc=Array{Array{Float64,1},1}(),              # loc
    misc=Array{Dict{ASCIIString,Any},1}(),        # misc
    notes=Array{Array{ASCIIString,1},1}(),        # notes
    resp=Array{Array{Complex{Float64},2},1}(),    # resp
    src=Array{ASCIIString,1}(),                   # src
    t=Array{Array{Float64,2},1}(),                # time
    x=Array{Array{Float64,1},1}(),                # data
    units=Array{ASCIIString,1}()                  # units
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
  A = Dict{ASCIIString,Any}()
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
push!(S::SeisData, T::SeisObj; n=true::Bool) = ([push!(S.(i),T.(i)) for i in fieldnames(T)];
  S.n += 1; n && (note(S, S.n, @sprintf("Channel added."));))
append!(S::SeisData, T::SeisObj; n=true::Bool) = push!(S, T, n=n)
deleteat!(S::SeisData, j::Int) = ([deleteat!(S.(i),j) for i in datafields(S)];
  S.n -= 1;)
deleteat!(S::SeisData, J::Range) = (collect(J); [deleteat!(S, j)
  for j in sort(J, rev=true)];)
deleteat!(S::SeisData, J::Array{Int,1}) = ([deleteat!(S, j)
  for j in sort(J, rev=true)];)
delete!(S::SeisData, j::Int) = deleteat!(S, j)
delete!(S::SeisData, J::Range) = deleteat!(S, J)
delete!(S::SeisData, J::Array{Int,1}) = deleteat!(S, J)

# ============================================================================
# Merge and extract
# Dealing with sparse time difference representations
"""
    t = t_expand(T::Array{Float64,2}, dt::Real)

Expand sparse-difference (SeisData-style) time stamp representation t to full
time stamps.
"""
function t_expand(t::Array{Float64,2}, dt::Real)
  dt == Inf && return cumsum(t[:,2])
  i = round(Int, t[:,1])
  tt = dt.*ones(i[end])
  tt[i] += t[:,2]
  return cumsum(tt)
end

"""
    t = t_collapse(T::Array{Float64,1}, dt::Real)

Collapse full time stamp representation t to SeisData sparse-difference
representation t.
"""
function t_collapse(t::Array{Float64,1}, dt::Real)
  ts = map(Float32, [dt; diff(t)])
  L = length(t)
  i = find([!isapprox(ts[i],Float32(dt)) for i = 1:1:length(t)])
  tt = cat(1, [1.0 t[1]], [map(Float64, i) ts[i]-dt])
  (isempty(i) || i[length(i)] != Float64(L)) && (tt = cat(1, tt,
    [Float64(L) 0.0]))
  return tt
end

function xtmerge(t1::Array{Float64,2}, x1::Array{Float64,1},
                 t2::Array{Float64,2}, x2::Array{Float64,1}, dt::Float64)
  t = [t_expand(t1, dt); t_expand(t2, dt)]
  if dt == Inf
    dt = 0
  end
  x = [x1; x2]

  # Sort
  i = sortperm(t)
  t1 = t[i]
  x1 = x[i]

  # Resolve conflicts
  if minimum(diff(t1)) < 0.5*dt
    J = flipdim(find(diff(t1) .< 0.5*dt), 1)
    for j in J
      t1[j] = 0.5*(t1[j]+t1[j+1])
      if isnan(x1[j])
        x1[j] = x1[j+1]
      elseif !isnan(x1[j+1])
        x1[j] = 0.5*(x1[j]+x1[j+1])
      end
      deleteat!(t1, j+1)
      deleteat!(x1, j+1)
    end
  end
  if 0 < dt < Inf
    t1 = t_collapse(t1, dt)
  else
    t1 = [zeros(length(t1)) t1]
  end
  return (t1, x1)
end

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
  # ungap!(S, m=false, w=false)
  # T = ungap(U, m=false, w=false)
  T = deepcopy(U)
  if !isapprox(S.gain,T.gain)
    (T.x .*= (S.gain/T.gain); T.gain = copy(S.gain))      # rescale T.x to match S.x
  end
  (S.t, S.x) = xtmerge(S.t, S.x, T.t, T.x, 1/T.fs)        # merge time and data
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
  #ungap!(S[i], m=false, w=false)
  #ungap!(T, m=false, w=false)
  if !isapprox(S.gain[i],T.gain)
    (T.x .*= (S.gain[i]/T.gain); T.gain = copy(S.gain[i]))        # rescale T.x to match S.x
  end
  (S.t[i], S.x[i]) = xtmerge(S.t[i], S.x[i], T.t, T.x, 1/T.fs)    # time, data
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
    T = pull(S::SeisData, n::ASCIIString)

Extract the first channel named `n` from `S` and return it as a SeisObj structure.

    T = pull(S::SeisData, i::integer)

Extract channel `i` from `S` as a SeisObj.
"""
pull(S::SeisData, n::ASCIIString) = (i = findname(n, S); T = getindex(S, i);
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
function +(S::SeisData, s::ASCIIString)
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
+(S::SeisObj, s::ASCIIString) = cat(1, S.notes, string(string(now()), 'T')[2], "  ", s)

# Rules for deleting
-(S::SeisData, i::Int) = (U = deepcopy(S); deleteat!(U,i); return U)  # By channel #
-(S::SeisData, str::ASCIIString) = ([deleteat!(S,k) for k in unique([find(S.id .== str); find(S.name .== str)])]) #Name or ID match
-(S::SeisData, T::SeisObj) = [deleteat!(S,i) for i in find(S.id .== T.i)] # By SeisObj

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
