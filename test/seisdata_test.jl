using Base.Test, Compat
include("../SeisData.jl")
addc1(S) = AddSeisChan(S, fs = 50.0, gain = 10.0, name = "DEAD.STA.EHZ",
            t=0.02*cat(1, 0, ones(99)), x=randn(100), ts=0.02, te=2.00)
addc2(S) = AddSeisChan(S, fs = 100.0, gain = 5.0, name = "DEAD.STA.EHE",
            t=0.01*cat(1, 0, ones(49), 100, ones(49)), x=rand(100)-0.5, ts=0.0, te=1.99)
addc3(S) = AddSeisChan(S, fs = 50.0, gain = 10.0, name = "DEAD.STA.EHZ",
            t=0.02*cat(1, 0, ones(149)), x=randn(150), ts=1.02, te=4.00)


println("seisdata...")
println("...init...")
S = SeisData();
for i in (S.Fs, S.Loc, S.Name, S.RespN, S.End, S.Gain, S.LocN, S.Start, S.Time, S.Data, S.Resp, S.Picks)
  @test_approx_eq(isempty([]), isempty(i))
end

println("...channel add...")
addc1(S)
@test_approx_eq(S.Nc, 1)
@test_approx_eq(length(S.Fs), 1)
@test_approx_eq(length(S.Gain), 1)
@test_approx_eq(length(S.Name), 1)
@test_approx_eq(length(S.Time),1)
@test_approx_eq(length(S.Data),1)
@test_approx_eq(S.Fs[1], 50.0)
@test_approx_eq(S.Gain[1], 10.0)
@test_approx_eq(true, S.Name[1]=="DEAD.STA.EHZ")
@test_approx_eq(length(S.Time[1]), 100)
@test_approx_eq(length(S.Data[1]), 100)
@test_approx_eq(length(S.Resp), 0)

println("...channel delete...")
RmSeisChan(S, 1)
for i in (S.Fs, S.Loc, S.Name, S.RespN, S.End, S.Gain, S.LocN, S.Start, S.Time, S.Data, S.Resp, S.Picks)
  @test_approx_eq(isempty([]), isempty(i))
end

# Test pick add, set, remove
println("...merge...")
addc1(S)
addc2(S)
T = SeisData()
addc3(T)
addc2(T)
U = MergeSeis(S,T,v=true)
@test_approx_eq(length(U.Data[1]), 200)
@test_approx_eq(length(U.Data[1]), length(U.Time[1]))
@test_approx_eq(length(U.Data[2]), length(S.Data[2]))
@test_approx_eq(length(U.Data[2]), length(T.Data[2]))
@test_approx_eq(length(U.Resp), 0)

# Test location add, set, remove
println("...location add/remove...")
loc1 = [13.597867  40.666833  511.0]
loc2 = [52.640278,-114.233889, 930]
loc3 = [-77.529722 167.153333 3794]
AddSLoc(U, loc1, chans=2)
AddSLoc(U, loc2, chans=[1])
AddSLoc(U, loc3)
@test_approx_eq(U.LocN[1], 2)
@test_approx_eq(U.LocN[2], 1)
@test_approx_eq(isempty(find(U.LocN .== 3)), true)
RmSLoc(U, 1)
@test_approx_eq(U.LocN[2], 0)
@test_approx_eq(U.LocN[1], 1)
RmSLoc(U, 1)
@test_approx_eq(U.LocN[1], 0)
@test_approx_eq(U.LocN[2], 0)
AddSLoc(U, loc1, chans=[2])
AddSLoc(U, loc2, chans=1)
@test_approx_eq(U.LocN[1], 3)
@test_approx_eq(U.LocN[2], 2)
@test_approx_eq(length(U.Resp), 0)

# Test response add, set, remove
println("...resp add/remove...")
l22 = [0.0 -8.88+8.88*im;
       0.0 -8.88-8.88*im]
le3d_20 = [   0.0 -0.220+0.235*im;
              0.0 -0.220-0.235*im;
              0.0 -0.230+0.0*im]
le3d_5 = [0.0 -0.888+0.888*im;
          0.0 -0.888-0.888*im]
AddSResp(U, l22, chans=2)
@test_approx_eq(U.RespN[2], 1)
AddSResp(U, le3d_20, chans=[1])
@test_approx_eq(U.RespN[1], 2)
AddSResp(U, le3d_5)
@test_approx_eq(U.RespN[1], 2)
@test_approx_eq(U.RespN[2], 1)
@test_approx_eq(isempty(find(U.RespN .== 3)), true)
RmSResp(U, 1)
@test_approx_eq(U.RespN[2], 0)
@test_approx_eq(U.RespN[1], 1)
RmSResp(U, 1)
@test_approx_eq(U.RespN[1], 0)
@test_approx_eq(U.RespN[2], 0)
AddSResp(U, l22, chans=[2])
AddSResp(U, le3d_20, chans=1)
@test_approx_eq(U.RespN[1], 3)
@test_approx_eq(U.RespN[2], 2)

# Test pick add, set, remove
println("...pick add/remove...")
p1 = "P"
p2 = "S"
p3 = "Rn"
tp1 = 3.5
tp2 = 2.3
ts = [6.1 5.5]
AddPick(U, p1, [0 tp2])
@test_approx_eq(haskey(U.Picks,p1), true)
AddPick(U, p1, tp1)
@test_approx_eq(U.Picks[p1][1], tp1)
@test_approx_eq(U.Picks[p1][2], tp2)
AddPick(U, p2, ts)
@test_approx_eq(U.Picks[p2][2], ts[2])
RmPick(U, p2, chans=2)
@test_approx_eq(U.Picks[p2][2], 0)
U.Picks[p2][2] = tp2
@test_approx_eq(U.Picks[p1][2], tp2)
AddPick(U, p3)
@test_approx_eq(haskey(U.Picks,p3), true)
@test_approx_eq(length(collect(keys(U.Picks))), 3)

println("...filtering...")
S = deepcopy(U)
T = FiltSeis(U, F=BitArray([false,true]), ftype='h', fl=1, fh=20.0)
@test_approx_eq(S.Data[1][1],T.Data[1][1])
@test_approx_eq(S.Data[2][1]==T.Data[2][1],false)
T = FiltSeis(U, F=true, ftype='b')
T = FiltSeis(U, ftype='l', fh=10.0)
T = FiltSeis(S, ftype='s', fl=1, fh=20.0)
S = FiltSeis(U)
FiltSeis!(U)
@test_approx_eq(S.Data[1][1], U.Data[1][1])

println("...pad...")
PadSeis!(U)
@test_approx_eq(U.End[2]-U.Start[2],length(U.Data[2])/U.Fs[2])

println("...sync...")
SyncSeis!(U)
for i = 1:1:S.Nc
  for j = i:1:S.Nc
    @test_approx_eq(length(U.Data[i]), length(U.Time[j]))
    @test_approx_eq(U.Start[i], U.Start[j])
    @test_approx_eq(U.End[i], U.End[j])
  end
end

#println("...screen dump...")
#PrintSeis(U, nx = 10, np = 2, na = "NA")
WriteSeis(T);
S = ReadSeis("save.seis");
@test_approx_eq(findfirst(T.Time[2].>1/T.Fs[2]), findfirst(S.Time[2].>1/S.Fs[2]))
println("...done.")
