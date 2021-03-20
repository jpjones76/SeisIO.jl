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
sac_pz_out5 = path*"/local_sac_5.pz"
f_stub      = "1981.088.10.38.23.460"
f_out       = f_stub * "..CDV...R.SAC"
f_out_new   = f_stub * ".VU.CDV..NUL.R.SAC"
sacv7_out   = "v7_out.sac"

printstyled("  SAC\n", color=:light_green)
printstyled("    read\n", color=:light_green)
@test_throws ErrorException verified_read_data("sac", uw_file)

SAC1 = verified_read_data("sac", sac_file)[1]
@test ≈(SAC1.fs, 100.0)
@test ≈(length(SAC1.x), 1000)

# SAC with mmap
printstyled("      mmap\n", color=:light_green)
SACm = read_data("sac", sac_file, memmap=true)[1]
@test SAC1 == SACm

SAC2 = verified_read_data("sac", sac_file, full=true)[1]
@test ≈(1/SAC1.fs, SAC2.misc["delta"])
@test ≈(length(SAC1.x), SAC2.misc["npts"])

printstyled("      wildcard\n", color=:light_green)
SAC = verified_read_data("sac", sac_pat, full=true)

printstyled("      bigendian\n", color=:light_green)
SAC3 = verified_read_data("sac", sac_be_file, full=true)[1]
@test ≈(1/SAC3.fs, SAC3.misc["delta"])
@test ≈(length(SAC3.x), SAC3.misc["npts"])

redirect_stdout(out) do
  sachdr(sac_be_file)
end

printstyled("    write\n", color=:light_green)
S = SeisData(SAC2)
writesac(S) # change 2019-07-15 to cover writesac on GphysData
@test safe_isfile(f_out)
@test any([occursin(string("wrote to file ", f_out), S.notes[1][i]) for i in 1:length(S.notes[1])])

printstyled("      reproducibility\n", color=:light_green)
SAC4 = verified_read_data("sac", f_out, full=true)[1]
for f in SeisIO.datafields
  (f in [:src, :notes, :misc]) && continue
  @test isequal(getfield(SAC2, f), getfield(SAC4, f))
end
fn = f_out[3:end]
writesac(SAC4, fname=fn)
@test safe_isfile(fn)
SAC5 = verified_read_data("sac", fn, full=true)[1]
for f in SeisIO.datafields
  (f in [:src, :notes, :misc]) && continue
  @test isequal(getfield(SAC2, f), getfield(SAC4, f))
  @test isequal(getfield(SAC4, f), getfield(SAC5, f))
end
safe_rm(fn)

printstyled("      logging\n", color=:light_green)
@test any([occursin("write", n) for n in S.notes[1]])
redirect_stdout(out) do
  show_writes(S, 1)
  show_writes(S[1])
  show_writes(S)
end

SAC1.id = "VU.CDV..NUL"
SAC1.name = "VU.CDV..NUL"
writesac(SAC1)
@test safe_isfile(f_out_new)
writesac(SAC1, fname="POTATO.SAC")
@test safe_isfile("POTATO.SAC")

# testing custom naming formats
writesac(SAC1, fname="test_write_1.sac")
@test safe_isfile("test_write_1.sac")
safe_rm("test_write_1.sac")

# testing that appending ".sac" to a file string works
writesac(SAC1, fname="test_write_2", v=1)
@test safe_isfile("test_write_2.sac")
safe_rm("test_write_2.sac")

redirect_stdout(out) do
  writesac(SAC1, v=1)
end
@test safe_isfile(f_out_new)
safe_rm(f_out_new)

printstyled("      skip if fs==0.0\n", color=:light_green)
SAC1.id = "VU.FS0..NUL"
SAC1.fs = 0.0
writesac(SAC1)
@test safe_isfile(f_stub*"VU.FS0..NUL.R.SAC") == false

# SACPZ
printstyled("    SACPZ\n", color=:light_green)
printstyled("      read\n", color=:light_green)
S = read_meta("sacpz", sac_pz_wc)
S = read_meta("sacpz", sac_pz_file)
writesacpz(sac_pz_out1, S)
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

printstyled("      write\n", color=:light_green)
writesacpz(sac_pz_out2, U)
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
writesacpz(sac_pz_out3, U)
read_meta!(S, "sacpz", sac_pz_out3)
for f in (:n, :id, :name, :loc, :fs, :gain, :units)
  @test isequal(getfield(S, f), getfield(T, f))
end
S = breaking_seis()[1:3]
S.resp[1].resp = rand(ComplexF64, 12, 2)
S.resp[3].stage[2] = nothing
writesacpz(sac_pz_out4, S)

printstyled("        GphysChannel\n", color=:light_green)
writesacpz(sac_pz_out5, S[1])

safe_rm(sac_pz_out1)
safe_rm(sac_pz_out2)
safe_rm(sac_pz_out3)
safe_rm(sac_pz_out4)
safe_rm(sac_pz_out5)

printstyled("    SAC file v7 (SAC v102.0)\n", color=:light_green)
test_fs = 62.5
test_lat = 48.7456
test_lon = -122.4126

printstyled("      writesac(..., nvhdr=N)\n", color=:light_green)
C = read_data("sac", sac_file)[1]

writesac(C, fname=sacv7_out, nvhdr=6)
sz6 = stat(sacv7_out).size

writesac(C, fname=sacv7_out, nvhdr=7)
sz7 = stat(sacv7_out).size

# The only difference should be the addition of a length-22 Vector{Float64
@test sz7-sz6 == 176

# In fact, we can open the file, skip to byte sz6, and read in the array
io = open(sacv7_out, "r")
seek(io, sz6)
sac_buf_tmp = read(io)
close(io)
dv = reinterpret(Float64, sac_buf_tmp)

# ...and the variables we write to the header should be identical
@test C.fs == 1.0/dv[1]
@test C.loc.lon == dv[19]
@test C.loc.lat == dv[20]

printstyled("      big endian\n", color=:light_green)
io = open(sac_be_file, "r")
sac_raw = read(io)
close(io)
sac_raw[308] = 0x07

reset_sacbuf()
dv     = BUF.sac_dv
dv[1]  = 1.0/test_fs
dv[19] = test_lon
dv[20] = test_lat
dv    .= bswap.(dv)
sac_dbl_buf = reinterpret(UInt8, dv)

io = open(sacv7_out, "w")
write(io, sac_raw)
write(io, sac_dbl_buf)
close(io)

C = read_data("sac", sacv7_out, full=true)[1]
@test C.fs == test_fs
@test C.loc.lat == test_lat
@test C.loc.lon == test_lon

printstyled("      little endian\n", color=:light_green)
io = open(sac_file, "r")
sac_raw = read(io)
close(io)
sac_raw[305] = 0x07

reset_sacbuf()
dv[1]  = 1.0/test_fs
dv[19] = test_lon
dv[20] = test_lat
sac_dbl_buf = reinterpret(UInt8, dv)

io = open(sacv7_out, "w")
write(io, sac_raw)
write(io, sac_dbl_buf)
close(io)

C = read_data("sac", sacv7_out, full=true)[1]
@test C.fs == test_fs
@test C.loc.lat == test_lat
@test C.loc.lon == test_lon
