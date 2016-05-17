using Base.Test, Compat
include("../timeaux.jl")
println("timeaux...")

println("...parsetimewin...")
d0, d1 = parsetimewin(0, 600)
@test_approx_eq(600000, (d1-d0).value)
d0, d1 = parsetimewin("2016-02-29T23:30:00", "2016-03-01T00:30:00")
@test_approx_eq(3600000, (d1-d0).value)
t = DateTime(now())
s = t-Dates.Hour(2)
d0, d1 = parsetimewin(s, t)
@test_approx_eq(7200000, (d1-d0).value)
