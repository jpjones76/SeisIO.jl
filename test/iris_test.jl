using Base.Test, Compat
include("../IRIS.jl")
println("IRIS tests...(creates up to 6 SAC files)")

f_irisws = "out1.sac"
f_irisget = "out2.sac"
ts = "2016-03-23T23:10:00"
te = "2016-03-23T23:17:00"
chans = ["UW.TDH.EHZ"; "UW.VLL.EHZ"; "CC.TIMB.EHZ"]

println("...IRISws...")
SAC = irisws(net="CC", sta="TIMB", cha="EHZ", s=ts, t=te, fmt="sacbl")
S = irisws(net="CC", sta="TIMB", cha="EHZ", s=ts, t=te, fmt="miniseed")
@test_approx_eq(SAC["data"][1], S.Data[1][1])
@test_approx_eq(SAC["npts"], length(S.Data[1]))
@test_approx_eq(SAC["npts"], length(S.Time[1]))
wsac(SAC)

println("...IRISget...")
S = IRISget(chans, t=300, v=true)
for i = 1:1:S.Nc
  for j = i:1:S.Nc
    @test_approx_eq(length(S.Data[i]), length(S.Time[j]))
    @test_approx_eq(S.Start[i], S.Start[j])
    @test_approx_eq(S.End[i], S.End[j])
  end
end
wsac(S)
