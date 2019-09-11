# test_le.sac was generated in SAC 101.6a with "fg seismogram; write test_le.sac"
sac_file = path*"/SampleFiles/test_le.sac"
sac_be_file = path*"/SampleFiles/test_be.sac"
sac_pz_file = path*"/SampleFiles/test_sac.pz"
sac_pz_wc = path*"/SampleFiles/test_sac.*"

printstyled("  SAC\n", color=:light_green)
printstyled("    read\n", color=:light_green)
@test_throws ErrorException read_data("sac", path*"/SampleFiles/99011116541W")

SAC1 = read_data("sac", sac_file)[1]
@test ≈(SAC1.fs, 100.0)
@test ≈(length(SAC1.x), 1000)

SAC2 = read_data("sac", sac_file, full=true)[1]
@test ≈(1/SAC1.fs, SAC2.misc["delta"])
@test ≈(length(SAC1.x), SAC2.misc["npts"])

printstyled("    wildcard read\n", color=:light_green)
SAC = read_data("sac", path*"/SampleFiles/*.sac", full=true)

printstyled("    bigendian read\n", color=:light_green)
SAC3 = read_data("sac", sac_be_file, full=true)[1]
@test ≈(1/SAC3.fs, SAC3.misc["delta"])
@test ≈(length(SAC3.x), SAC3.misc["npts"])


redirect_stdout(out) do
  sachdr(sac_be_file)
end

printstyled("    write\n", color=:light_green)
writesac(SeisData(SAC2)) # change 2019-07-15 to cover writesac on GphysData
@test safe_isfile("1981.088.10.38.14.009..CDV...R.SAC")
rm("1981.088.10.38.14.009..CDV...R.SAC")

SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")

# testing custom naming formats
writesac(SAC1, fname="test_write_1.sac")
@test safe_isfile("test_write_1.sac")
rm("test_write_1.sac")

# testing that appending ".sac" to a file string works
writesac(SAC1, fname="test_write_2", v=1)
@test safe_isfile("test_write_2.sac")
rm("test_write_2.sac")

redirect_stdout(out) do
  writesac(SAC1, ts=true, v=1)
end
@test safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
rm("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")

# SACPZ
printstyled("    SACPZ\n", color=:light_green)
S = read_meta("sacpz", sac_pz_file)
writesacpz(S, "local_sac.pz")
T = read_meta("sacpz", "local_sac.pz")
for f in (:n, :id, :name, :loc, :fs, :gain, :units)
  @test isequal(getfield(S, f), getfield(T, f))
end
for f in fieldnames(typeof(S.resp[1]))
  for i = 1:S.n
    @test isapprox(getfield(S.resp[i], f), getfield(T.resp[i], f))
  end
end
rm("local_sac.pz")

# For the H^HCoverage!
S = read_meta("sacpz", sac_pz_wc)
