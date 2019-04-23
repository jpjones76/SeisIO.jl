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

"""
  m,d = j2md(y,j)

Convert Julian day j of year y to month m, day d
"""
function j2md(y::T, j::T) where T<:Integer
  if T != Int32
    y = Int32(y)
    j = Int32(j)
  end
  z = zero(Int32)
  o = one(Int32)
  m = z
  d = o
  if j > Int32(31)
    if j > 59 && ((y % Int32(400) == z) ||
                  (y % Int32(4)   == z &&
                   y % Int32(100) != z))
      D = days_per_month_leap
    else
      D = days_per_month
    end
    while j > z
      d = j
      m += o
      j -= D[m]
    end
  else
    m = o
    d = j
  end
  return m,d
end

"""
  j = md2j(y,m,d)

Convert month `m`, day `d` of year `y` to Julian day (day of year)
"""
function md2j(y::T, m::T, d::T) where T<:Integer
  if T != Int32
    y = Int32(y)
    m = Int32(m)
    d = Int32(d)
  end
  z = zero(Int32)
  j = sum(days_per_month[1:m-1]) + d
  if m > 2 && ((y % Int32(400) == z) ||
               (y % Int32(4)   == z &&
                y % Int32(100) != z))
    j+=1
  end
  return T(j)
end
md2j(y::AbstractString, m::AbstractString, d::AbstractString) = md2j(parse(Int, y), parse(Int, m), parse(Int, d))

function y2μs(y::T) where T<:Integer
  y = Int64(y)-1
  return 86400000000 * (y*365 + div(y,4) - div(y,100) + div(y,400)) - 62135596800000000
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

### Relative Timekeeping
Numeric time values are *relative to the start of the current minute*. Thus, if one of `-s` or `-t` is 0, the data request begins (or ends) at the start of the minute in which the request is submitted.
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

function endtime(t::Array{Int64,2}, Δ::Int64)
  if isempty(t)
    t_end = 0
  else
    L = size(t,1)
    t_end = (t[L,1]-1)*Δ
    if L > 2
      t_end += getindex(sum(t, dims=1),2)
    else
      t_end += t[1,2]
    end
    # t_end = getindex(sum(t, dims=1),2) + (t[L,1]-1)*Δ
  end
  return t_end
end
endtime(t::Array{Int64,2}, fs::Float64) = endtime(t, round(Int64, 1.0/(fs*μs)))

function t_win(T::Array{Int64,2}, Δ::Int64)
  n = size(T,1)-1
  if T[n+1,2] != 0
    T = vcat(T, [T[n+1,1] 0])
    n += 1
  end
  w0 = -(Δ)
  W = Array{Int64,2}(undef,n,2)
  for i = 1:n
    W[i,1] = T[i,2] + w0 + Δ
    W[i,2] = W[i,1] + Δ*(T[i+1,1]-T[i,1]-1)
    w0 = W[i,2]
  end
  W[n,2] += Δ
  return W
end
t_win(T::Array{Int64,2}, fs::Float64) = t_win(T, round(Int64, 1000000.0/fs))

function w_time(W::Array{Int64,2}, Δ::Int64)
  n = size(W,1)+1
  T = Array{Int64,2}(undef,n,2)
  T[1,1] = Int64(1)
  T[1,2] = W[1,1]
  for i = 2:n-1
    T[i,1] = T[i-1,1] + div(W[i-1,2]-W[i-1,1], Δ) + 1
    T[i,2] = W[i,1] - W[i-1,2] - Δ
  end
  T[n,1] = T[n-1,1] + div(W[n-1,2]-W[n-1,1], Δ)
  T[n,2] = 0
  if T[n,1] == T[n-1,1]
    T = T[1:n-1,:]
  end
  return T
end
w_time(W::Array{Int64,2}, fs::Float64) = w_time(W, round(Int64, 1000000.0/fs))
