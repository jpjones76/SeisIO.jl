println("...parsetimewin...")
d0, d1 = parsetimewin(0, 600)
@test ≈(600000, (Dates.DateTime(d1)-Dates.DateTime(d0)).value)
d0, d1 = parsetimewin("2016-02-29T23:30:00", "2016-03-01T00:30:00")
@test ≈(3600000, (Dates.DateTime(d1)-Dates.DateTime(d0)).value)
t = Dates.DateTime(now())
s = t-Dates.Hour(2)
d0, d1 = parsetimewin(s, t)
@test ≈(7200000, (Dates.DateTime(d1)-Dates.DateTime(d0)).value)

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

# t_collapse, t_expand
T = Int64[1 1451606400000000; 100001 30000000; 250001 12330000; 352303 99000000; 360001 0]
fs = 100.0
@test ≈(T, SeisIO.t_collapse(SeisIO.t_expand(T, fs), fs))
@test ≈(T, SeisIO.w_time(SeisIO.t_win(T, fs), fs))


println("...done!")
