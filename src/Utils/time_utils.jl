function mk_t!(C::GphysChannel, nx::Integer, ts::Int64)
  t = Array{Int64, 2}(undef, 2, 2)
  setindex!(t, one(Int64), 1)
  setindex!(t, nx, 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)
  setfield!(C, :t, t)
  return nothing
end

function mk_t(nx::Integer, ts::Int64)
  t = Array{Int64, 2}(undef, 2, 2)
  setindex!(t, one(Int64), 1)
  setindex!(t, nx, 2)
  setindex!(t, ts, 3)
  setindex!(t, zero(Int64), 4)
  return t
end

function t_arr!(tbuf::Array{Int32,1}, dt::DateTime; digits::Integer=3, md::Bool=false)
  if length(tbuf) < 7
    resize!(tbuf, 7)
  end
  tbuf[1] = year(dt)
  if md==false
    os = 0
    tbuf[2] = md2j(tbuf[1], Int32(month(dt)), Int32(day(dt)))
  else
    os = 1
    tbuf[2] = month(dt)
    tbuf[3] = day(dt)
  end
  tbuf[3+os] = hour(dt)
  tbuf[4+os] = minute(dt)
  tbuf[5+os] = second(dt)
  ms = millisecond(dt)
  tbuf[6+os] = digits == 3 ? ms : div(ms, 10^(3-max(min(digits, 3), 1)))
  return nothing
end
t_arr!(tbuf::Array{Int32,1}, ts::String; digits::Integer=3, md::Bool=false) = t_arr!(tbuf, DateTime(ts), digits=digits, md=md)

@doc """
    t_arr!(tbuf::Array{Int32,1}, t::Union{Int64,DateTime,String} [, md::Bool=false, digits::Int=3])

Convert a time to an array of Int32s that overwrites `dbuf`.
* Input options: `t` can be
  - an Epoch time in integer μs
  - a DateTime
  - a String (formatted "YYYY-MM-DDThh:mm:ss.sss")
* Output: [year, Julian day, hour, minute, second, frac_second, ... ]
* `md=true` outputs [year, month, day, hour, minute, second, frac_second, ... ]
* `digits=N` changes the precision of `frac_second` to `N` digits
  - `digits=6` outputs frac_second in integer μs.
  - `digits=3` output frac_second in integer ms (default)
    - `N` outside the range 1:6 is treated as the nearest in-range integer
  - Maximum precision is 6 digits if `t` is an Int64
  - Maximum precision is 3 digits if `t` is a DateTime or String
""" t_arr!
function t_arr!(tbuf::Array{Int32,1}, t::Int64; digits::Integer=3, md::Bool=false)
  if length(tbuf) < 7
    resize!(tbuf, 7)
  end
  dt = u2d(t*μs)
  tbuf[1] = year(dt)
  if md==false
    os = 0
    tbuf[2] = md2j(Int64(tbuf[1]), month(dt), day(dt))
  else
    os = 1
    tbuf[2] = month(dt)
    tbuf[3] = day(dt)
  end
  tbuf[3+os] = hour(dt)
  tbuf[4+os] = minute(dt)
  tbuf[5+os] = second(dt)
  if digits == 3
    tbuf[6+os] = millisecond(dt)
  else
    N = max(min(digits, 6), 1)
    ts = div(dt.instant.periods.value,1000)*1000000-dtconst
    # if N ≤ 6
    tbuf[6+os] = div(t-ts, 10^(6-N))
    # else
    #   tbuf[6] = div((t-ts)*1000, 10^(9-N))
    # end
  end
  return nothing
end
