# save to disk/read from disk
savfile1 = "test.seis"
savfile2 = "test.hdr"
savfile3 = "test.evt"

S = randseisdata(c=false)
println("...SeisData file write...")
wseis(savfile1, S)

println("...SeisData file read...")
R = rseis(savfile1, v=true)
@assert(R[1]==S)

println("...SeisHdr file write...")
H = SeisHdr()
setfield!(H, :id, rand(0:2^62))
setfield!(H, :loc, [rand(0.0:0.1:90.0)*((-1)^rand(1:2)), rand(0.0:0.1:180.0)*((-1)^rand(1:2)), rand(0.0:0.1:640.0)])
setfield!(H, :mag, (Float32(rand(-5.0:0.1:9.0)), "M_"*Random.randstring(2)))
wseis(savfile2, H)

println("...SeisHdr file read...")
K = rseis(savfile2)
@assert(K[1]==H)

println("...SeisEvent file write...")
EV = SeisEvent(hdr=H, data=S)
wseis(savfile3, EV)

println("......a more complicated write involving one of each object type...")
wseis(savfile3, EV, S, H)

println("...SeisEvt file read...")
E2 = rseis(savfile3, v=true)
@assert(E2[1]==EV)

rm(savfile1)
rm(savfile2)
rm(savfile3)
println("...done!")
