import Dates:DateTime, Hour, now
import SeisIO:t_collapse, t_expand, endtime
printstyled("  time\n", color=:light_green)

t0 = time()
ts0 = String(split(string(u2d(t0)), '.')[1])
ts1 = String(split(timestamp(t0), '.')[1])
ts2 = String(split(timestamp(u2d(t0)), '.')[1])
ts3 = String(split(timestamp(string(u2d(t0))), '.')[1])
ts4 = String(split(timestamp(DateTime(string(u2d(t0)))), '.')[1])
@test ts1 == ts2 == ts3 == ts4 == ts0

m,d = j2md(2000,1); @test m == 1 && d == 1
m,d = j2md(2000,60); @test m == 2 && d == 29
m,d = j2md(2013,60); @test m == 3 && d == 1
m,d = j2md(2100,60); @test m == 3 && d == 1
m,d = j2md(2012,366)
@test_throws BoundsError j2md(2013,366)

j = md2j(2000,1,1); @test j == 1
j = md2j(2000,2,29); @test j == 60
j = md2j(2013,3,1); @test j == 60
j = md2j(2100,3,1); @test j == 60

@test ≈([1,1], collect(j2md(1,1)))
@test ≈([3,1], collect(j2md(2015, 60)))
@test ≈([3,1], collect(j2md(2016, 61)))
@test ≈([12,31], collect(j2md(2015, 365)))
@test ≈([12,31], collect(j2md(2000, 366)))
@test ≈(1, md2j(2001,1,1))
@test ≈(60, md2j(2015,3,1))
@test ≈(61, md2j(2016,3,1))
@test ≈(365, md2j(2015,12,31))
@test ≈(365, md2j(1900,12,31))

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
t_long = t_expand(T, fs)
@test ≈(T, t_collapse(t_long, fs))

T1 = hcat(cumsum(ones(Int64,size(T,1))), cumsum(T[:,2]))
fs1 = 0.0
@test ≈(T1, t_collapse(t_expand(T1, fs1), fs1))

# endtime
@test endtime(T, fs) == last(t_long)

printstyled(stdout, "    t_win, w_time\n", color=:light_green)
printstyled(stdout, "      Faithful representation of gaps\n", color=:light_green)
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

printstyled(stdout, "      Arbitrary windows containing gaps\n", color=:light_green)
t = [1 999999998990000; 101 10000; 297 0]
@test w_time(t_win(t, Δ), Δ) == t

t = [1 999999998990000; 101 10000; 297 1000000; 303 40000; 500 1000000; 10000 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      Length-0 gaps\n", color=:light_green)
t = [1 0; 6 0; 8 0; 10 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      Negative gaps\n", color=:light_green)
t = [1 0; 6 -2Δ; 8 -10Δ; 10 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      Single-point gap\n", color=:light_green)
t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 0]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      Non-null gap at end\n", color=:light_green)
t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 Δ]
@test w_time(t_win(t, Δ), Δ) == t

printstyled(stdout, "      Negative gap at end\n", color=:light_green)
t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 -5Δ]
@test w_time(t_win(t, Δ), Δ) == t
