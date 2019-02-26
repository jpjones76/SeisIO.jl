# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = path*"/SampleFiles/test.sac"

printstyled("  SAC...\n", color=:light_green)
printstyled("    read...\n", color=:light_green)
SAC1 = readsac(sac_file)
@test ≈(SAC1.fs, 100.0)
@test ≈(length(SAC1.x), 1000)

SAC2 = readsac(sac_file, full=true)
@test ≈(1/SAC1.fs, SAC2.misc["delta"])
@test ≈(length(SAC1.x), SAC2.misc["npts"])

printstyled("    write...\n", color=:light_green)
writesac(SAC2)
@test SeisIO.safe_isfile("1981.088.10.38.14.009..CDV...R.SAC")
rm("1981.088.10.38.14.009..CDV...R.SAC")

SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test SeisIO.safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
rm("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
