# test_le.sac was generated in SAC 101.6a with "fg seismogram; write test_le.sac"
sac_file    = path*"/SampleFiles/SAC/test_le.sac"
sac_be_file = path*"/SampleFiles/SAC/test_be.sac"
sac_pz_file = path*"/SampleFiles/SAC/test_sac.pz"
sac_pz_wc   = path*"/SampleFiles/SAC/test_sac.*"
uw_file     = path*"/SampleFiles/UW/00012502123W"
sac_pat     = path*"/SampleFiles/SAC/*.sac"
sac_pz_out1 = path*"/local_sac_1.pz"
sac_pz_out2 = path*"/local_sac_2.pz"
sac_pz_out3 = path*"/local_sac_3.pz"
sac_pz_out4 = path*"/local_sac_4.pz"

printstyled("  SAC\n", color=:light_green)
printstyled("    read\n", color=:light_green)
@test_throws ErrorException verified_read_data("sac", uw_file)

SAC1 = verified_read_data("sac", sac_file)[1]
@test ≈(SAC1.fs, 100.0)
@test ≈(length(SAC1.x), 1000)

# SAC with mmap
printstyled("    with mmap\n", color=:light_green)
SACm = read_data("sac", sac_file, memmap=true)[1]
@test SAC1 == SACm

SAC2 = verified_read_data("sac", sac_file, full=true)[1]
@test ≈(1/SAC1.fs, SAC2.misc["delta"])
@test ≈(length(SAC1.x), SAC2.misc["npts"])

printstyled("    wildcard read\n", color=:light_green)
SAC = verified_read_data("sac", sac_pat, full=true)

printstyled("    bigendian read\n", color=:light_green)
SAC3 = verified_read_data("sac", sac_be_file, full=true)[1]
@test ≈(1/SAC3.fs, SAC3.misc["delta"])
@test ≈(length(SAC3.x), SAC3.misc["npts"])


redirect_stdout(out) do
  sachdr(sac_be_file)
end

printstyled("    write\n", color=:light_green)
S = SeisData(SAC2)
writesac(S) # change 2019-07-15 to cover writesac on GphysData
@test safe_isfile("1981.088.10.38.14.009..CDV...R.SAC")
@test any([occursin("wrote to file 1981.088.10.38.14.009..CDV...R.SAC", S.notes[1][i]) for i in 1:length(S.notes[1])])
safe_rm("1981.088.10.38.14.009..CDV...R.SAC")

fn = "81.088.10.38.14.009..CDV...R.SAC"
writesac(S, fname=fn, xy=true)
@test safe_isfile(fn)
safe_rm(fn)

SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
writesac(SAC1, fname="POTATO.SAC")
@test safe_isfile("POTATO.SAC")

# testing custom naming formats
writesac(SAC1, fname="test_write_1.sac")
@test safe_isfile("test_write_1.sac")
rm("test_write_1.sac")

# testing that appending ".sac" to a file string works
writesac(SAC1, fname="test_write_2", v=1)
@test safe_isfile("test_write_2.sac")
rm("test_write_2.sac")

redirect_stdout(out) do
  writesac(SAC1, xy=true, v=1)
end
@test safe_isfile("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")
rm("1981.088.10.38.14.009.VU.CDV..NUL.R.SAC")

# SACPZ
printstyled("    SACPZ\n", color=:light_green)
S = read_meta("sacpz", sac_pz_wc)
S = read_meta("sacpz", sac_pz_file)
writesacpz(S, sac_pz_out1)
T = read_meta("sacpz", sac_pz_out1)
for f in (:n, :id, :name, :loc, :fs, :gain, :units)
  @test isequal(getfield(S, f), getfield(T, f))
end
for f in fieldnames(typeof(S.resp[1]))
  for i = 1:S.n
    @test isapprox(getfield(S.resp[i], f), getfield(T.resp[i], f))
  end
end
U = deepcopy(S)
for i = 1:U.n
  U.resp[i] = MultiStageResp(3)
  U.resp[i].stage[1] = S.resp[i]
end
writesacpz(U, sac_pz_out2)
T = read_meta("sacpz", sac_pz_out2)
for f in (:n, :id, :name, :loc, :fs, :gain, :units)
  @test isequal(getfield(S, f), getfield(T, f))
end
for f in fieldnames(typeof(S.resp[1]))
  for i = 1:S.n
    @test isapprox(getfield(S.resp[i], f), getfield(T.resp[i], f))
  end
end
U[1] = SeisChannel(id = "UW.HOOD..ENE")
writesacpz(U, sac_pz_out3)
read_meta!(S, "sacpz", sac_pz_out3)
for f in (:n, :id, :name, :loc, :fs, :gain, :units)
  @test isequal(getfield(S, f), getfield(T, f))
end
S = breaking_seis()[1:3]
S.resp[1].resp = rand(ComplexF64, 12, 2)
S.resp[3].stage[2] = nothing
writesacpz(S, sac_pz_out4)

safe_rm(sac_pz_out1)
safe_rm(sac_pz_out2)
safe_rm(sac_pz_out3)
safe_rm(sac_pz_out4)
