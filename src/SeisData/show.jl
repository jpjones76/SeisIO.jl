import Base:summary, show
const screenwid = Base.displaysize()[2]-2

function strtrunc(str::AbstractString; wid=screenwid::Integer)
  L = length(str)
  str = str[1:min(wid,L)]
  L >= wid && (str *= "…")
  return str
end

# =============================================================================
# Special functions to control display formatting of different fields
# Time size
ngaps(t::Array{Int64,2}, L::Integer) = max(0,size(t,1)-(t[end]==0?2:1))
is_ts(f::Float64) = (f > 0)
isgapped(t::Array{Int64,2}) = (size(t,1) > 2)
maxgap(t::Array{Int64,2}) = @sprintf("%.2f", isgapped(t) ? μs*maximum(t[2:end,2]) : 0)
gapsum(t::Array{Int64,2}, f::Float64, L::Integer) = isempty(t) ? "" :
  !is_ts(f) ? string(ngaps(t,L)+1, " vals") : !isgapped(t) ? "0 gaps" :
    string(ngaps(t,L), " gap", ngaps(t,L)>1 ? "s <= ":" = ", maxgap(t))

# Location
function short_loc(loc::Array{Float64,1})
  if isempty(loc)
    return "0.0 0.0 0.0 0.0 0.0"
  else
    return @sprintf("%.2f, %.2f, %.1f, %.1f, %.1f",
      loc[1], loc[2], loc[3], loc[4], loc[5])
  end
end
function long_loc(loc::Array{Float64,1})
  if isempty(loc)
    return "0.0 0.0 0.0 0.0 0.0"
  else
    return @sprintf("%.4f %c, %.4f %c, z = %+.3f, Θ = %+.3f%c, ϕ = %+.3f%c",
      abs(loc[1]), loc[1] < 0 ? 'S' : 'N', abs(loc[1]), loc[2] < 0 ? 'W' : 'E',
        loc[3], loc[4], '°', loc[5], '°')
  end
end
# Picks
picksum(D::Dict{String,Float64}) =
  strtrunc(join([@sprintf("%s %.2f",i,D[i]) for i in collect(keys(D))], ", "))

# Response
function respsum(R::Array{Complex{Float64},2})
  isempty(R) && return ""
  L = size(R,1)
  z = "z = "
  p = "p = "
  for i = 1:min(3,L)
    z *= @sprintf("%+.2f%+.2f%c, ", real(R[i,1]), imag(R[i,1]), 'i')
    p *= @sprintf("%+.2f%+.2f%c, ", real(R[i,2]), imag(R[i,2]), 'i')
  end
  if L > 3
    z *= "…"; p *= "…"
  else
    z = z[1:end-2]; p = p[1:end-2]
  end
  w = round(Int, 0.5*(screenwid-6))
  z = strtrunc(z, wid=w)
  p = strtrunc(p, wid=w)
  return string(z, " / ", p)
end
# =============================================================================

# =============================================================================
# String populators
arraypop(s, A, v) = strtrunc(s*join(["["*string(size(A[i],1))
  for i = 1:length(A)], v*"], ")*(isempty(A)?:"":v*"]"))

# SeisObj
strpop(s::AbstractString, A::String) = s*A              # name, id, units, src
strpop(s::AbstractString, A::Array{Complex{Float64},2}) =
  s*respsum(A)                                                           # resp
strpop(s::AbstractString, A::Array{String,1}) =
  strtrunc(s*join(A, ", "))   # SeisObj: notes / SeisData: name, id, units, src
strpop(s::AbstractString, A::Dict{String,Any}) =
    s*string(length(A), " entries")                                      # misc
strpop(s::AbstractString, A::Real) = (
      s*(searchindex(s, "FS") > 0 ? @sprintf("%.1f", A) :
        @sprintf("%.3e", A)))                                        # fs, gain

# SeisData
strpop(s::AbstractString, A::Array{Array{String,1},1}) =
  arraypop(s, A, " entries")                                            # notes
strpop(s::AbstractString, A::Array{Array{Complex{Float64},2},1}) =
  arraypop(s, A, " p/z")                                                 # resp
strpop(s::AbstractString, A::Array{Dict{String,Any},1}) =
      strtrunc(s*join([string("[",length(A[i])," entries]")
        for i=1:length(A)], ", "))                                       # misc
function strpop(s::AbstractString, A::Array{Array{Float64,1},1})
  if searchindex(s, "LOC") > 0
     [s *= string("[", short_loc(A[i]), "], ") for i = 1:length(A)]
     return strtrunc(s)                                                   # loc
   else
     return arraypop(s, A, " vals")                                         # x
   end
end

# SeisData: fs, gain / SeisObj: loc, x
function strpop(s::AbstractString, A::Array{Float64,1})
  if searchindex(s, "FS") > 0
    return strtrunc(s * join([@sprintf("%.1f", A[i])
      for i = 1:min(40, length(A))], ", "))                              # fs
  elseif searchindex(s, "LOC") > 0
    return s*long_loc(A)                                                 # loc
  else
    searchindex(s, "X") > 0 && (s *= string("(", length(A), ") "))       # x
    return strtrunc(s * join([@sprintf("%.3e", A[i])
      for i = 1:min(40, length(A))], ", "))                              # gain
  end
end
# =============================================================================

# =============================================================================
# Display-replated
function show(io::IO, S::Union{SeisData,SeisObj})
  str = Dict{String,AbstractString}()
  for i in datafields(S)
    if i != :t
      str[string(i)] = strpop(@sprintf("%5s: ", uppercase(string(i))), getfield(S,i))
    else
      s = "    T: "
      if isa(S, SeisObj)
        str["t"] = string(s, gapsum(S.t,S.fs,length(S.x)))
      else
        str["t"] = (s*join(["["*gapsum(S.t[i],S.fs[i],length(S.x[i]))
          for i = 1:length(S.t)], "], ")*(isempty(S.t)?"":"]"))
        length(str["t"]) > screenwid && (str["t"] = strtrunc(str["t"]))
      end
    end
  end

  println(io, summary(S))
  for k in ("name", "id", "src", "fs", "gain", "units", "loc", "resp",
            "misc", "notes", "t", "x")
    println(io, str[k])
  end
end
show(S::Union{SeisData,SeisObj}) = show(STDOUT, S)
summary(s::SeisData) = string("type ", typeof(s), " with ", s.n, " channel",
  s.n == 1 ? "" : "s")
summary(S::SeisObj) = string(typeof(S), " with ", length(S.x), " sample",
  (length(S.x) == 1 ? "" : "s"), ", ", gapsum(S.t, S.fs,length(S.x)))
length(t::SeisObj) = println(summary(t))
size(t::SeisObj) = println(summary(t))
# =============================================================================
