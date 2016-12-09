# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = "SampleFiles/test.sac"

get_sac_fw(k::String) = ((F, I, C) = SeisIO.get_sac_keys(); findfirst(F .== k))
get_sac_iw(k::String) = ((F, I, C) = SeisIO.get_sac_keys(); findfirst(I .== k))

println("...header accuracy...")
@test_approx_eq(get_sac_fw("b"), 6)
@test_approx_eq(get_sac_fw("unused7"), 70)
@test_approx_eq(get_sac_iw("npts"), 10)
@test_approx_eq(get_sac_iw("iftype"), 16)

println("...file read to dict...")
SAC1 = readsac(sac_file)
@test_approx_eq(SAC1.fs, 100.0)
@test_approx_eq(length(SAC1.x), 1000)

println("...full file read...")
SAC2 = readsac(sac_file, fast=false)
@test_approx_eq(1/SAC1.fs, SAC2.misc["delta"])
@test_approx_eq(length(SAC1.x), SAC2.misc["npts"])

println("...writesac with missing headers...")
writesac(SAC2)
@test_approx_eq(isfile("1981.088.10.38.14.0009..CDV...R.SAC"), true)
rm("1981.088.10.38.14.0009..CDV...R.SAC")

println("...writesac with all headers...")
SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test_approx_eq(isfile("1981.088.10.38.14.0009.VU.CDV..NUL.R.SAC"), true)
rm("1981.088.10.38.14.0009.VU.CDV..NUL.R.SAC")

println("...done!")
