const sμ = 1000000.0
const μs = 1.0e-6

u2d(k::Real) = Dates.unix2datetime(k)
d2u(k::DateTime) = Dates.datetime2unix(k)
timestamp() = String(Dates.format(u2d(time()), "yyyy-mm-ddTHH:MM:SS"))
timestamp(t::Int64) = String(Dates.format(u2d(t/sμ), "yyyy-mm-ddTHH:MM:SS"))

# =========================================================
# Not for export

function t_expand(t::Array{Int64,2}, fs::Float64)
  fs == 0.0 && return cumsum(t[:,2])
  t[end,1] == 1 && return [t[1,2]]
  dt = round(Int64, 1.0/(fs*SeisIO.μs))
  tt = dt.*ones(Int64, t[end,1])
  tt[1] -= dt
  for i = 1:size(t,1)
    tt[t[i,1]] += t[i,2]
  end
  return cumsum(tt)
end

function t_collapse(tt::Array{Int64,1}, fs::Float64)
  if fs == 0.0
    t = Array{Int64,2}([Int64(0) tt[1]; zeros(Int64, length(tt)) diff(tt)::Array{Int64,1}])
  else
    dt = round(Int64, 1.0/(fs*μs))
    ts = Array{Int64,1}([dt; diff(tt)::Array{Int64,1}])
    L = length(tt)
    i = findall(ts .!= dt)
    t = Array{Int64,2}([[1 tt[1]];[i ts[i].-dt]])
  end
  if isempty(i) || i[end] != L
    t = vcat(t, hcat(L,0))
  end
  return t
end

# =========================================================

"""
    w = t_win(T::Array{Int64,2}, fs::Float64)

Convert matrix T from sparse delta-encoded time gaps to time windows (w[:,1]:w[:,2]) in integer μs from the Unix epoch (1970-01-01T00:00:00). Specify fs in Hz.

    W = t_win(S::SeisData)

Convert S.t to time windows s.t. W[i] = t_win(S.t[i], S.fs[i]).
"""
function t_win(T::Array{Int64,2}, fs::Float64)
  n = size(T,1)-1
  w0 = Int64(0)
  W = Array{Int64,2}(undef,n,2)
  @inbounds for i = 1:n
    W[i,1] = T[i,2] + w0
    W[i,2] = W[i,1] + round(Int64, SeisIO.sμ*Float64(T[i+1,1]-T[i,1])/fs)
    w0 = W[i,2]
  end
  return W
end

"""
    w = w_time(W::Array{Int64,2}, fs::Float64)

Convert matrix W from time windows (w[:,1]:w[:,2]) in integer μs from the Unix epoch (1970-01-01T00:00:00) to sparse delta-encoded time representation. Specify fs in Hz.
"""
function w_time(W::Array{Int64,2}, fs::Float64)
  w2 = Int64(0)
  n = size(W,1)
  T = Array{Int64,2}(undef,n+1,2)
  T[1,1] = Int64(1)
  @inbounds for i = 1:n
    T[i,2] = W[i,1] - w2
    T[i+1,1] = T[i,1] - round(Int64, (W[i,1]-W[i,2])*SeisIO.μs*fs)
    w2 = W[i,2]
  end
  T[n+1,2] = Int64(0)
  return T
end

"""
  m,d = j2md(y,j)

Convert Julian day j of year y to month m, day d
"""
function j2md(y::T, j::T) where T
   if j > T(31)
      D = Array{T,1}([31,28,31,30,31,30,31,31,30,31,30,31])
      ((y%T(400) == T(0)) || (y%T(4) == T(0) && y%T(100) != T(0))) && (D[2]+=T(1))
      m = T(0)
      while j > T(0)
         d = j
         m += T(1)
         j -= D[m]
      end
   else
      m = T(1)
      d = T(j)
   end
   return m, d
end
# j2md(y::Int64, j::Int64) = j2md(Int32(y), Int32(j))

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
