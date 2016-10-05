# save to disk/read from disk
savfile = "test.seis"

S = randseisdata(c=false)
println("...file write...")
wseis(S, savfile)

println("...file read...")
R = rseis(savfile)
@test_approx_eq(R==S, true)

rm(savfile)
println("...done!")
