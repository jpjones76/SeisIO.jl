# save to disk/read from disk
savfile1 = "test.seis"
savfile2 = "test.hdr"
savfile3 = "test.evt"

S = randseisdata(c=false)
println("...SeisData file write...")
wseis(S, savfile1)

println("...SeisData file read...")
R = rseis(savfile1)
@test_approx_eq(R==S, true)

println("...SeisHdr file write...")
H = SeisHdr()
setfield!(H, :id, rand(0:1:2^62))
setfield!(H, :lat, rand(0.0:0.1:90.0))
setfield!(H, :lon, rand(0.0:0.1:180.0)*((-1)^rand(1:2)))
setfield!(H, :dep, rand(0.0:0.1:640.0))
setfield!(H, :mag, Float32(rand(-5.0:0.1:9.0)))
for i in [:mag_auth, :auth, :cat, :contrib]
  setfield!(H, i, randstring(rand(4:12)))
end
wseis(H, savfile2)

println("...SeisHdr file read...")
K = rseis(savfile2)
@test_approx_eq(K==H, true)

println("...SeisEvt file write...")
EV = SeisEvt(hdr=H, data=S)
wseis(EV, savfile3)

println("...SeisEvt file read...")
E2 = rseis(savfile3)

rm(savfile1)
rm(savfile2)
rm(savfile3)
println("...done!")
