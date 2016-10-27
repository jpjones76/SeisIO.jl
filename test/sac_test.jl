# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = "SampleFiles/test.sac"

get_sac_fw(k::String) = ((F, I, C) = get_sac_keys(); findfirst(F .== k))
get_sac_iw(k::String) = ((F, I, C) = get_sac_keys(); findfirst(I .== k))

println("...header accuracy...")
@test_approx_eq(get_sac_fw("b"), 6)
@test_approx_eq(get_sac_fw("unused7"), 70)
@test_approx_eq(get_sac_iw("npts"), 10)
@test_approx_eq(get_sac_iw("iftype"), 16)

println("...file read...")
SAC1 = rsac(sac_file)
@test_approx_eq(SAC1.fs, 100.0)
@test_approx_eq(length(SAC1.x), 1000)

println("...data stream read...")
f = open(sac_file,"r")
SAC2 = psac(f)
@test_approx_eq(1/SAC1.fs, SAC2["delta"])
@test_approx_eq(length(SAC1.x), SAC2["npts"])

println("...writesac with missing headers...")
writesac(SAC2)
@test_approx_eq(isfile("sacfile.SAC"), true)

println("...writesac with all headers...")
SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test_approx_eq(isfile("1981.088.10.38.14.0000.VU.CDV..NUL.R.SAC"), true)

rm("sacfile.SAC")
rm("1981.088.10.38.14.0000.VU.CDV..NUL.R.SAC")

println("...done!")
