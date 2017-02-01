const sμ = 1000000.0
const μs = 1.0e-6

u2d(k::Real) = Dates.unix2datetime(k)
d2u(k::DateTime) = Dates.datetime2unix(k)
timestamp() = String(Dates.format(u2d(time()), "yyyy-mm-ddTHH:MM:SS"))
timestamp(t::Int64) = String(Dates.format(u2d(t/sμ), "yyyy-mm-ddTHH:MM:SS"))

# =========================================================
# Not for export
function xtmerge(t1::Array{Int64,2}, t2::Array{Int64,2}, x1::Array{Float64,1}, x2::Array{Float64,1}, fs::Float64)
  t = [t_expand(t1, fs); t_expand(t2, fs)]

  # Sort
  i = sortperm(t)
  t = t[i]
  x = [x1; x2][i]

  if fs == 0.0
    half_samp = Int64(0)
  else
    half_samp = round(Int, 0.5/(fs*μs))
  end
  if minimum(diff(t)) < half_samp
    xtjoin!(x, t, half_samp)
  end
  if half_samp > 0.0
    return (t_collapse(t, fs), x)
  else
    return (reshape(t, length(t), 1), x)
  end
end

function xtjoin!(x::Array{Float64,1}, t::Array{Int64,1}, half_samp::Int64)
  J0 = find(diff(t) .< half_samp)
  while !isempty(J0)
    J1 = J0.+1
    K = [isnan(x[J0]) isnan(x[J1])]

    # Average points that are either both NaN or neither Nan
    ii = find(K[:,1].==K[:,2])
    i0 = J0[ii]
    i1 = J1[ii]
    t[i0] = round(Int, 0.5*(t[i0]+t[i1]))
    x[i0] = 0.5*(x[i0]+x[i1])

    # Delete pairs with only one NaN (and delete i1, while we're here)
    i3 = find(K[:,1].*!K[:,2])
    i4 = find(!K[:,1].*K[:,2])
    II = sort([J0[i3]; J1[i4]; i1])
    deleteat!(t, II)
    deleteat!(x, II)

    J0 = find(diff(t) .< half_samp)
  end
  return (x, t)::Tuple{Array{Float64,1},Array{Int64,1}}
end

function t_expand(t::Array{Int64,2}, fs::Float64)
  fs == 0 && return cumsum(t[:,1])
  dt = round(Int, 1/(fs*μs))
  tt = dt.*ones(Int64, t[end,1])
  tt[t[:,1]] += t[:,2]
  return cumsum(tt)
end

function t_collapse(tt::Array{Int64,1}, fs::Float64)
  if fs == 0.0
    t = Array{Int64,2}([tt[1]; diff(tt)::Array{Int64,1}])
  else
    dt = round(Int, 1.0/(fs*μs))
    ts = Array{Int64,1}([dt; diff(tt)::Array{Int64,1}])
    L = length(tt)
    i = find(ts .!= dt)
    t = Array{Int64,2}([[1 tt[1]];[i ts[i].-dt]])
  end
  if isempty(i) || i[end] != L
    t = vcat(t, hcat(L,0))
  end
  return t
end
# =========================================================

"""
    t = tzcorr()

Fast fix for timezone in Libc.strftime assuming local, not UTC. Returns a time
zone correction in seconds; when calling Libc.strftime, add tzcorr() to an epoch
time to obtain output in UTC.
"""
tzcorr() = (t = Libc.strftime("%z",time()); return -3600*parse(t[1:3])-60*parse(t[4:5]))

"""
  m,d = j2md(y,j)

Convert Julian day j of year y to month m, day d
"""
function j2md{T}(y::T, j::T)
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
function md2j{T}(y::T, m::T, d::T)
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
