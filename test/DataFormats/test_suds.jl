vfname        = "SampleFiles/Restricted/10081701.WVP"
sac_fstr      = "SampleFiles/Restricted/20081701.sac-0*"
eq_wvm1_pat   = "SampleFiles/SUDS/*1991191072247.wvm1.sac"
eq_wvm1_file  = "SampleFiles/SUDS/eq_wvm1.sud"
eq_wvm2_pat   = "SampleFiles/SUDS/*1991191072247.wvm2.sac"
eq_wvm2_file  = "SampleFiles/SUDS/eq_wvm2.sud"
lsm_pat       = "SampleFiles/SUDS/*1992187065409.sac"
lsm_file      = "SampleFiles/SUDS/lsm.sud"
rot_pat       = "SampleFiles/SUDS/*1993258220247.sac"
rot_file      = "SampleFiles/SUDS/rotate.sud"

printstyled("  SUDS\n", color=:light_green)

printstyled("    readsudsevt\n", color=:light_green)
# read into SeisEvent
W = SUDS.readsudsevt(rot_file)
W = SUDS.readsudsevt(lsm_file)
W = SUDS.readsudsevt(eq_wvm1_file)
W = SUDS.readsudsevt(eq_wvm2_file)

printstyled("    in read_data\n", color=:light_green)
if safe_isfile(vfname)
  redirect_stdout(out) do
    SUDS.suds_support()
    S = verified_read_data("suds", vfname, v=3, full=true)
    S = verified_read_data("suds", eq_wvm1_file, v=3, full=true)
    S = verified_read_data("suds", eq_wvm2_file, v=3, full=true)
    S = verified_read_data("suds", lsm_file, v=3, full=true)
    S = verified_read_data("suds", rot_file, v=3, full=true)
    S = verified_read_data("suds", "SampleFiles/SUDS/eq_wvm*sud", v=3, full=true)
  end
end

printstyled("    equivalence to SAC readsuds\n", color=:light_green)
# Volcano-seismic event supplied by W. McCausland
if has_restricted
  S = SUDS.read_suds(vfname, full=true)
  S2 = verified_read_data("sac", sac_fstr, full=true)
  for n = 1:S2.n
    id = S2.id[n]
    if startswith(id, ".")
      id = "OV"*id
    end
    i = findid(id, S)
    if i > 0
      @test isapprox(S.x[i], S2.x[n])
      @test isapprox(Float32(S2.fs[n]), Float32(S.fs[i]))
      @test abs(S.t[i][1,2] - S2.t[i][1,2]) < 2000 # SAC only has ~1 ms precision
    end
  end
else
  printstyled("      skipped volcano-seismic test file\n", color=:red)
end

# SUDS sample files
# from eq_wvm1.sud
S = SUDS.read_suds(eq_wvm1_file)
S1 = verified_read_data("sac", eq_wvm1_pat)
for n = 1:S1.n
  i = findid(S1.id[n], S)
  if i > 0
    @test isapprox(S.x[i], S1.x[n])
  else
    @warn(string(S1.id[n], " not found in S; check id conversion!"))
  end
end

# from eq_wvm2.sud
S = SUDS.read_suds(eq_wvm2_file)
S1 = verified_read_data("sac", eq_wvm2_pat)
for n = 1:S1.n
  i = findid(S1.id[n], S)
  if i > 0
    @test isapprox(S.x[i], S1.x[n])
  else
    @warn(string(S1.id[n], " not found in S; check id conversion!"))
  end
end

# from lsm.sud
S = SeisData()
SUDS.read_suds!(S, lsm_file)
S1 = verified_read_data("sac", lsm_pat)
for n = 1:S1.n
  i = findid(S1.id[n], S)
  if i > 0
    @test isapprox(S.x[i], S1.x[n])
  else
    @warn(string(S1.id[n], " not found in S; check id conversion!"))
  end
end

# from rot.sud
S = SUDS.read_suds(rot_file)
S1 = verified_read_data("sac", rot_pat)
for n = 1:S1.n
  i = findid(S1.id[n], S)
  if i > 0
    @test isapprox(S.x[i], S1.x[n])
  else
    @warn(string(S1.id[n], " not found in S; check id conversion!"))
  end
end

printstyled("    data types not yet seen in real samples\n", color=:light_green)
f_out = string("fake_suds.sud")
id_buf = codeunits("UWSPORTSBALL")
nb = Int32(3200)
n_unreadable = Int32(60)
suds_types = (Int32, Complex{Float32}, Float64, Float32, Complex{Float64})

# skeleton: 0x53, 0x00, struct_id, struct_size, nbytes_following_struct
suds_struct_tag = (0x53, 0x00, zero(Int16), zero(Int32), zero(Int32))
suds_unreadable = (0x53, 0x36, Int16(4), n_unreadable, zero(Int32))
suds_5 = (0x53, 0x36, Int16(5), Int32(76), zero(Int32))
suds_readable = (0x53, 0x36, Int16(7), Int32(62), nb)

for (j, data_code) in enumerate([0x32, 0x63, 0x64, 0x66, 0x74])
  T = suds_types[j]

  x = rand(T, div(nb, sizeof(T)))
  io = open(f_out, "w")

  # Unreadable packet
  [write(io, i) for i in suds_unreadable]
  write(io, rand(UInt8, n_unreadable))

  # Packet 5
  [write(io, i) for i in suds_5]
  p = position(io)
  write(io, id_buf)
  write(io, rand(Int16, 2))
  write(io, 45.55)
  write(io, 122.62)
  write(io, 77.1f0)
  write(io, rand(UInt8, 7))
  write(io, 0x76)
  write(io, data_code)
  write(io, rand(UInt8, 3))
  write(io, 1.152f8, 0.0f0, 0.0f0)
  write(io, Int16[2, 32])
  skip(io, 4)
  write(io, 0.0f0, -32767.0f0)

  # Packet 7
  [write(io, i) for i in suds_readable]
  p = position(io)
  write(io, id_buf)
  write(io, d2u(now()))
  write(io, zero(Int16))
  write(io, data_code)
  write(io, 0x00)
  skip(io, 4)
  write(io, Int32(div(nb, sizeof(T))))
  write(io, 50.0f0)
  skip(io, 16)
  write(io, zero(Float64))
  write(io, 0.0f0)
  write(io, x)
  close(io)

  if j < 5
    S = verified_read_data("suds", f_out)
    if data_code == 0x63
      @test isapprox(S.x[1], real(x))
    else
      @test isapprox(S.x[1], x)
    end
  else
    @test_throws ErrorException read_data("suds", f_out)
  end
end
safe_rm(f_out)
