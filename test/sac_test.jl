println("SAC IO...")
# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = "SampleFiles/test.sac"

println("...header accuracy...")
@test_approx_eq(get_sac_fw("b"), 6)
@test_approx_eq(get_sac_fw("unused7"), 70)
@test_approx_eq(get_sac_iw("npts"), 10)
@test_approx_eq(get_sac_iw("iftype"), 16)

println("...file read...")
SAC1 = rsac(sac_file)
@test_approx_eq(SAC1["delta"], 0.01)
@test_approx_eq(SAC1["b"], 9.459999e+00)
@test_approx_eq(SAC1["e"], 1.945000e+01)
@test_approx_eq(SAC1["npts"], length(SAC1["data"]))

println("...data stream read...")
f = open(sac_file,"r")
SAC2 = psac(f)
@test_approx_eq(SAC1["delta"], SAC2["delta"])
@test_approx_eq(SAC1["b"], SAC2["b"])
@test_approx_eq(SAC1["e"], SAC2["e"])
@test_approx_eq(SAC1["npts"], SAC2["npts"])

println("...pruning...")
prunesac!(SAC1)

println("...wsac with missing headers...")
wsac(SAC2)
@test_approx_eq(isfile("sacfile.SAC"), true)

println("...wsac with all headers...")
SAC1["kcmpnm"] = "NUL"
SAC1["knetwk"] = "VU"
wsac(SAC1)
@test_approx_eq(isfile("1981.088.10.38.14.0000.VU.CDV..NUL.R.SAC"), true)

rm("sacfile.SAC")
rm("1981.088.10.38.14.0000.VU.CDV..NUL.R.SAC")

println("...done!")
