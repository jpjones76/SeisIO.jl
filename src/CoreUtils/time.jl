export d2u, j2md, md2j, parsetimewin, timestamp, u2d, t_win, w_time

function tstr(t::DateTime)
  Y, M, D, h, m, s, μ = year(t), month(t), day(t), hour(t), minute(t), second(t), millisecond(t)
  Y = lpad(Y, 4, "0")
  M = lpad(M, 2, "0")
  D = lpad(D, 2, "0")
  h = lpad(h, 2, "0")
  m = lpad(m, 2, "0")
  s = lpad(s, 2, "0")
  μ = lpad(μ, 3, "0")
  return string(Y, "-", M, "-", D, "T", h, ":", m, ":", s, ".", μ)
end

u2d(k::Real) = Dates.unix2datetime(k)
d2u(k::DateTime) = Dates.datetime2unix(k)
timestamp() = tstr(Dates.unix2datetime(time()))
timestamp(t::DateTime) = tstr(t)
timestamp(t::Real) = tstr(u2d(t))
timestamp(t::String) = tstr(Dates.DateTime(t))
tnote(s::String) = string(timestamp(), ": ", s)

# =========================================================
# Not for export

function t_expand(t::Array{Int64,2}, fs::Float64)
  fs == 0.0 && return t[:,2]
  t[end,1] == 1 && return [t[1,2]]
  dt = round(Int64, 1.0/(fs*μs))
  tt = dt.*ones(Int64, t[end,1])
  tt[1] -= dt
  for i = 1:size(t,1)
    tt[t[i,1]] += t[i,2]
  end
  return cumsum(tt)
end

function t_collapse(tt::Array{Int64,1}, fs::Float64)
  if fs == 0.0
    t = hcat(collect(1:1:length(tt)), tt)
  else
    dt = round(Int64, 1.0/(fs*μs))
    ts = Array{Int64,1}([dt; diff(tt)::Array{Int64,1}])
    L = length(tt)
    i = findall(ts .!= dt)
    t = Array{Int64,2}([[1 tt[1]];[i ts[i].-dt]])
    if isempty(i) || i[end] != L
      t = vcat(t, hcat(L,0))
    end
  end
  return t
end

function endtime(t::Array{Int64,2}, fs::Float64)
  L = size(t,1)
  return L == 0 ? 0 : getindex(sum(t, dims=1),2) + (t[L,1]-1)*round(Int64, 1.0/(fs*μs))
end

# =========================================================

"""
  m,d = j2md(y,j)

Convert Julian day j of year y to month m, day d
"""
function j2md(y::T, j::T) where T
  m = zero(T)
  d = one(T)
  if j > T(31)
    D = Array{T,1}([31,28,31,30,31,30,31,31,30,31,30,31])
    ((y%T(400) == T(0)) || (y%T(4) == T(0) && y%T(100) != T(0))) && (D[2]+=T(1))
    z = zero(T)
    while j > z
      d = j
      m += one(T)
      j -= D[m]
    end
  else
    m = one(T)
    d = T(j)
  end
  return m, d
end

"""
  j = md2j(y,m,d)

Convert month `m`, day `d` of year `y` to Julian day (day of year)
"""
function md2j(y::T, m::T, d::T) where T
  D = Array{T,1}([31,28,31,30,31,30,31,31,30,31,30,31])
  ((y%400 == 0) || (y%4 == 0 && y%100 != 0)) && (D[2]+=1)
  return (sum(D[1:m-1]) + d)
end

"""
    d0, d1 = parsetimewin(s, t)

Convert times `s` and `t` to strings and sorts s.t. d0 < d1.

### Time Specification
`s` and `t` can be real numbers, DateTime objects, or ASCII strings. Strings must follow the format "yyyy-mm-ddTHH:MM:SS.nnn", e.g. `s="2016-03-23T11:17:00.333"`. Exact behavior depends on the data types of s and t:

| **s** | **t** | **Behavior**                         |
|:------|:------|:-------------------------------------|
| DT    | DT    | Sort                                 |
| R     | DT    | Add `s` seconds to `t`, then sort    |
| DT    | R     | Add `t` seconds to `s`, then sort    |
| S     | R, DT | Convert `s` → DateTime, then sort    |
| R, DT | S     | Convert `t` → DateTime, then sort    |
| R     | R     | `s` and `t' are seconds from `now()` |

(above, R = Real, DT = DateTime, S = String, I = Integer)
"""
function parsetimewin(s::DateTime, t::DateTime)
  if s < t
    return (string(s), string(t))
  else
    return (string(t), string(s))
  end
end
parsetimewin(s::DateTime, t::String) = parsetimewin(s, DateTime(t))
parsetimewin(s::DateTime, t::Real) = parsetimewin(s, u2d(d2u(s)+t))
parsetimewin(s::Real, t::DateTime) = parsetimewin(t, u2d(d2u(t)+s))
parsetimewin(s::String, t::Union{Real,DateTime}) = parsetimewin(DateTime(s), t)
parsetimewin(s::Union{Real,DateTime}, t::String) = parsetimewin(s, DateTime(t))
parsetimewin(s::String, t::String) = parsetimewin(DateTime(s), DateTime(t))
parsetimewin(s::Real, t::Real) = parsetimewin(u2d(60*floor(Int, time()/60) + s), u2d(60*floor(Int, time()/60) + t))
