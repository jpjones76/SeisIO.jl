# save to disk/read from disk
savfile = "test.seis"

println("randseis and native file IO...")
S = randseisdata(c=false)
wseis(S, savfile)

R = rseis(savfile)
@test_approx_eq(R==S, true)

rm(savfile)
println("...done!")
