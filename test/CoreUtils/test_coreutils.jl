import Dates:DateTime, Hour, now
printstyled("  ...time functions...\n", color=:light_green)

t0 = time()
ts1 = timestamp(t0)
ts2 = timestamp(u2d(t0))
ts3 = timestamp(DateTime(string(u2d(t0))))
@test ts1 == ts2 == ts3

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
@test ≈(T, SeisIO.t_collapse(SeisIO.t_expand(T, fs), fs))

T = hcat(cumsum(ones(Int64,size(T,1))), cumsum(T[:,2]))
fs = 0.0
@test ≈(T, SeisIO.t_collapse(SeisIO.t_expand(T, fs), fs))

printstyled("  safe_isfile...\n", color=:light_green)
@test SeisIO.safe_isfile("runtests.jl") == true
@test SeisIO.safe_isfile("foo.jl") == false

printstyled("  namestrip...\n", color=:light_green)
str = String(0x00:0xff)
S = randSeisData(3)
S.name[2] = str

for key in keys(SeisIO.bad_chars)
  test_str = namestrip(str, key)
  @test length(test_str) == 256 - (32 + length(SeisIO.bad_chars[key]))
end
namestrip!(S)
@test length(S.name[2]) == 210
