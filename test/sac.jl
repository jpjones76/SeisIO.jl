path = Base.source_dir()

# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = path*"/SampleFiles/test.sac"

println("...fast file read...")
SAC1 = readsac(sac_file)
@test_approx_eq(SAC1.fs, 100.0)
@test_approx_eq(length(SAC1.x), 1000)

println("...full file read...")
SAC2 = readsac(sac_file, full=true)
@test_approx_eq(1/SAC1.fs, SAC2.misc["delta"])
@test_approx_eq(length(SAC1.x), SAC2.misc["npts"])

println("...writesac with missing headers...")
writesac(SAC2)
@assert(isfile("1981.088.10.38.14.009..CDV...R.SAC"))
rm("1981.088.10.38.14.009..CDV...R.SAC")

println("...writesac with all headers...")
SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@assert(isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC"))
rm("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")

println("...done!")
