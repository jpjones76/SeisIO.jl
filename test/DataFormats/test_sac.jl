# test.sac was generated in SAC 101.6a with "fg seismogram; write test.sac"
sac_file = path*"/SampleFiles/test.sac"
sac_be_file = path*"/SampleFiles/060123130000.CON.1.sac"

printstyled("  SAC...\n", color=:light_green)
printstyled("    read...\n", color=:light_green)
@test_throws ErrorException readsac(path*"/SampleFiles/99062109485W")

SAC1 = readsac(sac_file)
@test ≈(SAC1.fs, 100.0)
@test ≈(length(SAC1.x), 1000)

SAC2 = readsac(sac_file, full=true)
@test ≈(1/SAC1.fs, SAC2.misc["delta"])
@test ≈(length(SAC1.x), SAC2.misc["npts"])

printstyled("    bigendian read...\n", color=:light_green)
SAC3 = readsac(sac_be_file, full=true)
@test ≈(1/SAC3.fs, SAC3.misc["delta"])
@test ≈(length(SAC3.x), SAC3.misc["npts"])

open("show.log", "w") do out
  redirect_stdout(out) do
    sachdr(sac_be_file)
  end
end

printstyled("    write...\n", color=:light_green)
writesac(SAC2)
@test SeisIO.safe_isfile("1981.088.10.38.14.009..CDV...R.SAC")
rm("1981.088.10.38.14.009..CDV...R.SAC")

SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test SeisIO.safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")

open("show.log", "w") do out
  redirect_stdout(out) do
    writesac(SAC1, ts=true, v=1)
  end
end
@test SeisIO.safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
rm("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
