path = Base.source_dir()

# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = path*"/SampleFiles/test.sac"

println("...fast file read...")
SAC1 = readsac(sac_file)
@test ≈(SAC1.fs, 100.0)
@test ≈(length(SAC1.x), 1000)

println("...full file read...")
SAC2 = readsac(sac_file, full=true)
@test ≈(1/SAC1.fs, SAC2.misc["delta"])
@test ≈(length(SAC1.x), SAC2.misc["npts"])

println("...writesac with missing headers...")
writesac(SAC2)
@assert(SeisIO.safe_isfile("1981.088.10.38.14.009..CDV...R.SAC"))
rm("1981.088.10.38.14.009..CDV...R.SAC")

println("...writesac with all headers...")
SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@assert(SeisIO.safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC"))
rm("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")

println("To test for faithful SAC write of SeisIO in SAC:")
println("     (1) Type `wsac(SL)` at the Julia prompt.")
println("     (2) Open a terminal, change to the current directory, and start SAC.")
println("     (4) type `r *GPW*SAC *MBW*SAC; qdp off; plot1; lh default`.")
println("     (5) Report any irregularities.")

println("...done!")
