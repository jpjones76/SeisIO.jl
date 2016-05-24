u2d(k) = Dates.unix2datetime(k)
d2u(k) = Dates.datetime2unix(k)

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
