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
ts = 1451606400000000
T = Int64[1 ts; 100001 30000000; 250001 12330000; 352303 99000000; 360001 0]
fs = 100.0
Δ = round(Int64, sμ/fs)
t_long = t_expand(T, fs)
@test ≈(T, t_collapse(t_long, fs))

T1 = hcat(cumsum(ones(Int64,size(T,1))), cumsum(T[:,2]))
fs1 = 0.0
@test ≈(T1, t_collapse(t_expand(T1, fs1), fs1))

# starttime
printstyled(stdout, "    starttime\n", color=:light_green)
@test starttime(T, fs) == first(t_long)
@test starttime(T, Δ) == starttime(T, fs)
@test starttime(Array{Int64,2}(undef, 0, 0), Δ) == 0
@test starttime(Array{Int64,2}(undef, 0, 0), 100Δ) == 0
@test starttime(Array{Int64,2}(undef, 0, 0), fs) == 0

# why starttime exists: it handles segments that aren't in chronological order
printstyled(stdout, "      non-chronological\n", color=:light_green)
Tnco = Int64[1 ts; 1000 -2000Δ; 120000 0]
t_long = t_expand(Tnco, fs);
@test minimum(t_long) != first(t_long)
@test starttime(Tnco, fs) == starttime(Tnco, Δ) == ts - 1001Δ == minimum(t_expand(Tnco, fs))

# endtime
printstyled(stdout, "    endtime\n", color=:light_green)
T = Int64[1 ts; 100001 30000000; 250001 12330000; 352303 99000000; 360001 0]
t_long = t_expand(T, fs)
@test endtime(T, fs) == last(t_long)
@test endtime(T, Δ) == endtime(T, fs)
@test endtime(Array{Int64,2}(undef, 0, 0), Δ) == 0
@test endtime(Array{Int64,2}(undef, 0, 0), 100Δ) == 0
@test endtime(Array{Int64,2}(undef, 0, 0), fs) == 0

# endtime must also handle segments that aren't in chronological order
printstyled(stdout, "      non-chronological\n", color=:light_green)
nx = 120000
igap = 1000
tgap = 10000
Tnco = Int64[1 ts; nx-2000 tgap*Δ; nx-(igap-1) -8000Δ; nx 0]
t_long = t_expand(Tnco, fs);
@test maximum(t_long) != last(t_long)
@test endtime(Tnco, fs) == endtime(Tnco, Δ) == ts + (nx-igap)*Δ + (tgap-1)*Δ == maximum(t_long)

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
 # first      last
 # sample     sample
 # time       time
 #       0    40000 ===> so that collect(w[i,1]:Δ:w[i,2]) for each window == t_expand
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

printstyled(stdout, "    t_bounds\n", color=:light_green)
function test_t_bounds(t::Array{Int64, 2}, Δ::Int64)
  (t0, t1) = t_bounds(t, Δ)
  W = t_win(t, Δ)
  @assert t0 == minimum(W)
  @assert t1 == maximum(W)
  return nothing
end

fs = 100.0
Δ = round(Int64, sμ/fs)
t = [1 0; 6 980000; 8 100000; 10 0]
test_t_bounds(t, Δ)

t = [1 999999998990000; 101 10000; 297 0]
test_t_bounds(t, Δ)

t = [1 999999998990000; 101 10000; 297 1000000; 303 40000; 500 1000000; 10000 0]
test_t_bounds(t, Δ)

t = [1 0; 6 0; 8 0; 10 0]
test_t_bounds(t, Δ)

t = [1 0; 6 -2Δ; 8 -10Δ; 10 0]
test_t_bounds(t, Δ)

t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 0]
test_t_bounds(t, Δ)

t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 Δ]
test_t_bounds(t, Δ)

t = [1 0; 6 2Δ; 7 4Δ; 8 Δ; 10 -5Δ]
test_t_bounds(t, Δ)

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

printstyled(stdout, "    sort_segs!\n", color=:light_green)
Δ = 20000
ts = 1583455810004000
nx = 40000
gi = 10
gl = 6
W = ts .+ Δ.*[    0     gi-1
                -gl       -1
                 gi  nx-gl-1]
W0 = deepcopy(W)
sort_segs!(W)
@test W == W0[[2,1,3], :]

t = sort_segs(w_time(W0, Δ), Δ)
@test t == w_time(W, Δ)

printstyled(stdout, "    t_extend\n", color=:light_green)
printstyled(stdout, "      time-series\n", color=:light_green)
nx = 6000
Δ = 10000
g = 300000
fs = 100.0
t0 = 1411776000000000
t = [1 t0; nx 0]
ts = t[1,2] + nx*Δ
t2 = [1 ts; nx 0]

# should have only 2 rows
t1 = deepcopy(t)
@test t_extend(t1, ts, nx, fs) == nothing
@test t1 == [1 t0; 2nx 0]

# should have a gap of Δ at point nx+1
@test t_extend(t, ts + Δ, nx, fs) == [1 t0; nx+1 Δ; 2nx 0]

# should correctly log the gaps at nx and nx+1
t1 = [1 t0; nx g]
@test t_extend(t1, ts+g+Δ, nx, fs) == [1 t0; nx g; nx+1 Δ; 2nx 0]

# should only extend the expected length of nx to incorporate new start time
for ts1 in ts : 100Δ : ts + nx
  t1 = deepcopy(t)
  # @test t_extend(t, ts1, 0, fs) == [1 t[1,2]; nx + div(ts1-endtime(t, Δ), Δ) 0]
  @test t_extend(t1, ts1, 0, fs) == nothing
  @test t1 == [1 t[1,2]; nx-1 + div(ts1-endtime(t, Δ), Δ) 0]
end

# should initialize a new starter time array at ts
@test t_extend(Array{Int64,2}(undef,0,2), ts, 0, fs) == [1 ts]

t = [1 12356; 1231 333; 14134 0]
ts_new = 8348134123
nx_new = 65536
dt = 20000
fs = 50.0
t2 = deepcopy(t)
t_extend(t2, ts_new, 0, dt)
t1 = t_extend(t, ts_new, nx_new, dt)
 #     1       12356
 #  1231         333
 # 14135  8065441434
 # 79670           0
@test size(t1) == (4,2)
@test t1[end,1] == 79670
@test endtime(t1, dt) == t_expand(t1, fs)[end]
@test t1[1:end-2,:] == t2[1:end-1,:]

t = [1 3301; 505 1200; 1024 3]
ts_new = 1181381433
nx_new = 3000
t2 = t_extend(t, ts_new, 1, dt)
t1 = t_extend(t, ts_new, nx_new, dt)
# 1           3301
# 505         1200
# 1024           3
# 1025  1160896929
# 4024           0
@test endtime(t1, dt) == t_expand(t1, fs)[end]
@test t1[1:end-1,:] == t2

t1 = Array{Int64,2}(undef, 0, 0)
t2 = Array{Int64,2}(undef, 0, 2)
@test t_extend(t1, ts_new, nx_new, dt) == t_extend(t2, ts_new, nx_new, dt) == [1 ts_new; nx_new 0]
@test t_extend(t1, ts_new, 0, dt) == t_extend(t2, ts_new, 0, dt) == [1 ts_new]

printstyled(stdout, "      irregular\n", color=:light_green)
nx = 200
nn = 120
t1 = zeros(Int64, nx, 2)
t1[1:nx, 1] .= 1:nx
t1[1:nx, 2] .= sort(abs.(rand(1262304000000000:t0, nx)))
t2 = zeros(Int64, nn, 2)
t2[1:nn, 1] .= 1:nn
t2[1:nn, 2] .= sort(abs.(rand(t0+1:1583020800000000, nn)))
t1o = deepcopy(t1)
t2o = deepcopy(t2)
t3 = t_extend(t1, t2[1,2], nn, 0.0)
@test t1 == t1o
@test t2 == t2o
@test size(t3, 1) == nx+nn
@test t3[:, 1] == collect(1:1:nx+nn)
@test t3[nx+1, 2] == t2[1,2]

# These were in test_time_utils.jl
buf = BUF.date_buf
dstr = "2019-06-01T03:50:04.02"
dt = DateTime(dstr)
t = round(Int64, d2u(dt)*sμ)
nx = 12345

# Tests for mk_t
printstyled("    mk_t\n", color=:light_green)
C = randSeisChannel(s=true)
C.x = randn(nx)
mk_t!(C, nx, t)
@test C.t == [1 t; nx 0]
@test C.t == mk_t(nx, t)

# Tests for t_arr
printstyled("    t_arr!\n", color=:light_green)
t_arr!(buf, t)
@test buf[1:6] == Int32[2019, 152, 3, 50, 4, 20]
t = round(Int64, d2u(DateTime("2020-03-01T13:49:00.3"))*sμ)
t_arr!(buf, t)
@test buf[1:6] == Int32[2020, 61, 13, 49, 0, 300]
t = round(Int64, d2u(DateTime("2020-03-01T13:49:00.030"))*sμ)
t_arr!(buf, t)
@test buf[1:6] == Int32[2020, 61, 13, 49, 0, 30]
t = round(Int64, d2u(DateTime("2020-03-01T13:49:00.003"))*sμ)
t_arr!(buf, t)
@test buf[1:6] == Int32[2020, 61, 13, 49, 0, 3]

# Tests for x_inds
printstyled("    x_inds\n", color=:light_green)
function test_xinds(t::Array{Int64, 2})
  # Check that the sets of indices match what's in :t
  xi = x_inds(t)
  nt = size(t, 1)
  @test xi[1:nt-1,1] == t[1:nt-1,1]

  # Check that the length is what we expect
  @test size(xi, 1) == nt - (t[nt,2] == 0 ? 1 : 0)

  # Check xi and t_win(t, dt) have the same content
  for i in 1:size(xi,1)-1
    @test xi[i,2] == xi[i+1,1]-1
    for dt in ([250, 500, 1000, 10000, 20000, 100000])
      w = t_win(t, dt)
      @test xi[i,2]-xi[i,1] == div(w[i,2]-w[i,1], dt)
    end
  end
end

ts = 1583455810004000
for t in [[1  ts; 639000 0],
          [1  ts; 639000 57425593],
          [1  ts; 638999 300; 639000 57425593],
          [1  ts; 638998 1234; 638999 300; 639000 57425593],
          [1  ts; 638998 -1234525827; 639000 0],
          [1  ts; 638998 1234; 639000 0],
          [1 ts; 8 1234; 9 100000; 10 134123; 11 12; 2400 -3; 3891 3030303; 3892 -30000000; 3893 1234; 3894 57425593],
          [1 ts; 3894 0],
          [1 ts; 10 13412300; 11 123123123; 184447 3030303; 184448 -30000000; 184449 12300045; 184450 57425593]]
  test_xinds(t)
end
for i in 1:100
  t = breaking_tstruct(ts, 39000, 100.0)
  test_xinds(t)
end
