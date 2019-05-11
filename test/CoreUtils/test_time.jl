printstyled("  time\n", color=:light_green)

# Timestamp
t0 = time()
ts0 = String(split(string(u2d(t0)), '.')[1])
ts1 = String(split(timestamp(t0), '.')[1])
ts2 = String(split(timestamp(u2d(t0)), '.')[1])
ts3 = String(split(timestamp(string(u2d(t0))), '.')[1])
ts4 = String(split(timestamp(DateTime(string(u2d(t0)))), '.')[1])
@test ts1 == ts2 == ts3 == ts4 == ts0

# j2md
@test j2md(1, 1) == (1,1)
@test j2md(2000, 1) == (1,1)
@test j2md(2000, 60) == (2,29)
@test j2md(2000, 366) == (12,31)
@test_throws BoundsError j2md(2000, 367)
@test j2md(2012, 366) == (12,31)
@test j2md(2013, 60) == (3,1)
@test j2md(2015, 60) == (3,1)
@test j2md(2015, 365) == (12, 31)
@test j2md(2016, 61) == (3,1)
@test_throws BoundsError j2md(2013, 366)
@test_throws BoundsError j2md(2015, 366)
@test j2md(2100, 60) == (3,1)

# md2j
@test md2j(2000,1,1) == 1
@test md2j(2000,2,29) == 60
@test md2j(2013,3,1) == 60
@test md2j(2100,3,1) == 60
@test md2j(2001,1,1) == 1
@test 60 == md2j(2015,3,1)
@test 61 == md2j(2016,3,1)
@test 365 == md2j(2015,12,31)
@test 365 == md2j(1900,12,31)

# parsetimewin
t1 = t0 + 86400.0
dt0 = u2d(t0)
dt1 = u2d(t1)
st0 = string(dt0)
st1 = string(dt1)

d0, d1 = parsetimewin(dt0, dt1);  @test d1 > d0                      # dt, dt
d0, d1 = parsetimewin(dt0, t1);   @test d1 > d0                      # dt, r
d0, d1 = parsetimewin(dt0, st1);  @test d1 > d0                      # dt, s
d0, d1 = parsetimewin(t0, dt1);   @test d1 > d0                      # r, dt
d0, d1 = parsetimewin(t0, t1);    @test d1 > d0                      # r, r
d0, d1 = parsetimewin(t0, st1);   @test d1 > d0                      # r, s
d0, d1 = parsetimewin(st0, dt1);  @test d1 > d0                      # s, dt
d0, d1 = parsetimewin(st0, t1);   @test d1 > d0                      # s, r
d0, d1 = parsetimewin(st0, st1);  @test d1 > d0                      # s, s

# Checking that parsetimewin sorts correctly; type mismatch intentional
d0, d1 = parsetimewin(0, -600);  @test d1 > d0
d0, d1 = parsetimewin(-600.0, 0);  @test d1 > d0
d0, d1 = parsetimewin(600, 0.0);  @test d1 > d0
d0, d1 = parsetimewin(0.0, 600.0);  @test d1 > d0

@test ≈(600000, (DateTime(d1)-DateTime(d0)).value)
d0, d1 = parsetimewin("2016-02-29T23:30:00", "2016-03-01T00:30:00")
@test ≈(3600000, (DateTime(d1)-DateTime(d0)).value)
t = DateTime(now())
s = t-Hour(2)
d0, d1 = parsetimewin(s, t)
@test ≈(7200000, (DateTime(d1)-DateTime(d0)).value)

# t_collapse, t_expand
T = Int64[1 1451606400000000; 100001 30000000; 250001 12330000; 352303 99000000; 360001 0]
fs = 100.0
Δ = round(Int64, sμ/fs)
t_long = t_expand(T, fs)
@test ≈(T, t_collapse(t_long, fs))

T1 = hcat(cumsum(ones(Int64,size(T,1))), cumsum(T[:,2]))
fs1 = 0.0
@test ≈(T1, t_collapse(t_expand(T1, fs1), fs1))

# endtime
printstyled(stdout, "    endtime\n", color=:light_green)
@test endtime(T, fs) == last(t_long)
@test endtime(T, Δ) == endtime(T, fs)
@test endtime(Array{Int64,2}(undef, 0, 0), Δ) == 0
@test endtime(Array{Int64,2}(undef, 0, 0), 100Δ) == 0
@test endtime(Array{Int64,2}(undef, 0, 0), fs) == 0

printstyled(stdout, "    t_win, w_time\n", color=:light_green)
printstyled(stdout, "      faithful representation of gaps\n", color=:light_green)
fs = 100.0
Δ = round(Int64, sμ/fs)
t = [1 0; 6 980000; 8 100000; 10 0]
# t1 = t_expand(t, fs)
 #       0
 #   10000
 #   20000
 #   30000
 #   40000
 # 1030000
 # 1040000
 # 1150000
 # 1160000
 # 1170000

t2 = t_win(t, Δ)
 #       0    40000
 # 1030000  1040000
 # 1150000  1170000
 #
@test t2[1,2] == 40000
@test t2[2,:] == [1030000, 1040000]
@test t2[3,:] == [1150000, 1170000]

printstyled(stdout, "      arbitrary windows containing gaps\n", color=:light_green)
t = [1 999999998990000; 101 10000; 297 0]
@test w_time(t_win(t, Δ), Δ) == t

t = [1 999999998990000; 101 10000; 297 1000000; 303 40000; 500 1000000; 10000 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      length-0 gap\n", color=:light_green)
t = [1 0; 6 0; 8 0; 10 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      negative gap\n", color=:light_green)
t = [1 0; 6 -2Δ; 8 -10Δ; 10 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      single-point gap\n", color=:light_green)
t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      non-null gap at end\n", color=:light_green)
t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 Δ]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      negative gap at end\n", color=:light_green)
t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 -5Δ]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "    mktime\n", color=:light_green)
fv = 0.0005
iv = Array{Int32,1}([1980, 082, 10, 35, 39, 890])
(m,d) = j2md(iv[1], iv[2])

ts_0 = round(Int64, d2u(DateTime(iv[1], m, d, iv[3], iv[4], iv[5]))*sμ) +
       iv[6]*1000 +
       round(Int64,fv*1000.0)
ts_1 = Date(iv[1], m, d).instant.periods.value * 86400000000 +
       div(Time(iv[3], iv[4], iv[5]).instant.value, 1000) +
       iv[6]*1000 +
       round(Int64,fv*1000.0) -
       SeisIO.dtconst
ts_2 = mktime(iv[1], iv[2], iv[3], iv[4], iv[5], iv[6]*Int32(1000)) +
       round(Int64, fv*1000.0)
iv[6] *= Int32(1000)
ts_3 = mktime(iv) + round(Int64, fv*1000.0)
@test ts_0 == ts_1 == ts_2 == ts_3
# timespec()

printstyled(stdout, "    int2tstr, tstr2int\n", color=:light_green)
s = "2018-01-01T00:00:00.000001"
t = "2018-01-04T00:00:00.003900"
si = tstr2int(s)
ti = tstr2int(t)
j = loop_time(si, ti)

t = "2018-01-04T00:00:00.39"
for (n,s) in enumerate(["2018-01-01T00:00:00.000001",
                        "2018-01-01T00:00:00",
                        "2018-01-01T00:00:00.035",
                        "2016-02-29T00:00:00.02",
                        "2018-02-28T00:00:00.33"])

  s_str = identity(s)
  if length(s) == 19
    s_str *= "."
  end
  s_str = rpad(s_str, 26, '0')
  @test (int2tstr(tstr2int(s))) == s_str
  if n < 4
    @test loop_time(tstr2int(s), tstr2int(t)) == 4
    @test loop_time(tstr2int(s), tstr2int(t), ti=43200000000) == 7
    @test loop_time(tstr2int(s), tstr2int(t), ti=3600000000) == 73
  elseif n == 4
    @test loop_time(tstr2int(s), tstr2int("2016-03-02T00:00:02")) == 3
  elseif n == 5
    @test loop_time(tstr2int(s), tstr2int("2018-03-02T00:00:02")) == 3
  end
end
