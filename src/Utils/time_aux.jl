const μs = 1.0e-6

u2d(k) = Dates.unix2datetime(k)
d2u(k) = Dates.datetime2unix(k)

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
function j2md(y::Integer, j::Integer)
   if j > 31
      D = [31,28,31,30,31,30,31,31,30,31,30,31]
      ((y%400 == 0) || (y%4 == 0 && y%100 != 0)) && (D[2]+=1)
      m = 0
      while j > 0
         d = j
         m += 1
         j -= D[m]
      end
   else
      m = 1
      d = j
   end
   return m, d
end

"""
  j = md2j(y,m,d)

Convert month `m`, day `d` of year `y` to Julian day (day of year)
"""
function md2j(y::Integer,m::Integer,d::Integer)
  D = [31,28,31,30,31,30,31,31,30,31,30,31]
  ((y%400 == 0) || (y%4 == 0 && y%100 != 0)) && (D[2]+=1)
  return (sum(D[1:m-1]) + d)
end

"""
    t = sac2epoch(S)

Generate epoch time `t` from SAC dictionary `S`. `S` must contain all relevant
time headers (NZYEAR, NZJDAY, NZHOUR, NZMIN, NZSEC, NSMSEC).
"""
function sac2epoch(S::Dict{ASCIIString,Any})
  y = convert(Int64,S["nzyear"])
  j = convert(Int64,S["nzjday"])
  m,d = j2md(y,j)
  b = [convert(Int64,i) for i in [S["nzhour"] S["nzmin"] S["nzsec"] S["nzmsec"]]]
  return d2u(DateTime(y,m,d,b[1],b[2],b[3],b[4]))
end

"""
    d0, d1 = parsetimewin(s, t)

Either convert length `t` time window ending at time `s` to a pair of
DateTime objects, or create a pair of DateTime objects with `d0` as the start
datetime and `d1` as the end.
"""
function parsetimewin(s, t)
  if isa(s,Union{DateTime,ASCIIString}) && isa(t,Union{DateTime,ASCIIString})
    if typeof(s) == ASCIIString
      d0 = DateTime(s)
    else
      d0 = s
    end
    if typeof(t) == ASCIIString
      d1 = DateTime(t)
    else
      d1 = t
    end
    return d0, d1

  # t::Union{ASCIIString,DateTime} --> start at s, end at t
  elseif isa(t,Union{ASCIIString,DateTime}) && isa(s,Union{Float64,Int})
    if typeof(t) == ASCIIString
      d1 = DateTime(t)
    else
      d1 = t
    end
    return u2d(s), d1
  elseif !isa(t,Union{Float64,Int})
    throw(TypeError(:t))

  # t::Union{Float64,Int} --> backfill approximately t seconds from s
  elseif isa(s,Union{Float64,Int})
    # Special (default) case: s=0 --> start at beginning of current minute
    if abs(s-0) < eps()
      t1 = 60*floor(time()/60)
    end
    d0 = u2d(t1-t)
    d1 = u2d(t1)
  else
    if typeof(s) == ASCIIString
      d1 = DateTime(s)
    elseif typeof(s) == DateTime
      d1 = s
    else
      throw(TypeError(:s))
    end
    d0 = u2d(d2u(d1)-t)
  end
  return d0, d1
end

"""
    T = t_expand(t, fs)

Expand sparse delta-encoded time stamp representation t to full time stamps.
Returns integer time stamps in microseconds. fs should be in Hz.
"""
function t_expand(t::Array{Int64,2}, fs::Real)
  fs == 0 && return cumsum(t[:,1])
  dt = round(Int, 1/(fs*μs))
  tt = dt.*ones(Int64, t[end,1])
  tt[t[:,1]] += t[:,2]
  return cumsum(tt)
end

"""
    t = t_collapse(T, fs)

Collapse full time stamp representation T to sparse-difference representation t.
Time stamps in T should be in integer microseconds. fs should be in Hz.
"""
function t_collapse(tt::Array{Int64,1}, fs::Real)
  fs == 0 && return reshape([tt[1]; diff[tt]], length(tt), 1)
  dt = round(Int, 1/(fs*μs))
  ts = [dt; diff(tt)]
  L = length(tt)
  i = find(ts .!= dt)
  t = [[1 tt[1]]; [i ts[i]-dt]]
  (isempty(i) || i[end] != L) && (t = cat(1, t, [L 0]))
  return t
end

function xtmerge(t1::Array{Int64,2}, x1::Array{Float64,1},
                 t2::Array{Int64,2}, x2::Array{Float64,1}, fs::Float64)
  t = [t_expand(t1, fs); t_expand(t2, fs)]
  x = [x1; x2]

  # Sort
  i = sortperm(t)
  t1 = t[i]
  x1 = x[i]

  # Resolve conflicts
  half_samp = fs == 0 ? 0 : round(Int, 0.5/(fs*μs))
  if minimum(diff(t1)) < half_samp
    J = flipdim(find(diff(t1) .< half_samp), 1)
    for j in J
      t1[j] = round(Int, 0.5*(t1[j]+t1[j+1]))
      if isnan(x1[j])
        x1[j] = x1[j+1]
      elseif !isnan(x1[j+1])
        x1[j] = 0.5*(x1[j]+x1[j+1])
      end
      deleteat!(t1, j+1)
      deleteat!(x1, j+1)
    end
  end
  if half_samp > 0
    t1 = t_collapse(t1, fs)
  end
  return (t1, x1)
end
