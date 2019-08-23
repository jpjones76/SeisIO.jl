using SeisIO.SUDS

vfname = "SampleFiles/SUDS/10081701.WVP"
sac_fstr = "SampleFiles/SUDS/20081701.sac-0*"
eq_wvm1_pat = "SampleFiles/SUDS/*1991191072247.wvm1.sac"
eq_wvm1_file = "SampleFiles/SUDS/eq_wvm1.sud"
eq_wvm2_pat = "SampleFiles/SUDS/*1991191072247.wvm2.sac"
eq_wvm2_file = "SampleFiles/SUDS/eq_wvm2.sud"
lsm_pat = "SampleFiles/SUDS/*1992187065409.sac"
lsm_file = "SampleFiles/SUDS/lsm.sud"
rot_pat = "SampleFiles/SUDS/*1993258220247.sac"
rot_file = "SampleFiles/SUDS/rotate.sud"

printstyled("  SUDS\n", color=:light_green)

printstyled("    readsudsevt\n", color=:light_green)
# read into SeisEvent
W = SUDS.readsudsevt(rot_file)
W = SUDS.readsudsevt(lsm_file)
W = SUDS.readsudsevt(eq_wvm1_file)
W = SUDS.readsudsevt(eq_wvm2_file)

printstyled("    in read_data\n", color=:light_green)
redirect_stdout(out) do
  SUDS.suds_support()
  S = read_data("suds", vfname, v=3, full=true)
  S = read_data("suds", eq_wvm1_file, v=3, full=true)
  S = read_data("suds", eq_wvm2_file, v=3, full=true)
  S = read_data("suds", lsm_file, v=3, full=true)
  S = read_data("suds", rot_file, v=3, full=true)
  S = read_data("suds", "SampleFiles/SUDS/eq_wvm*sud", v=3, full=true)
end

printstyled("    equivalence to SAC readsuds\n", color=:light_green)

# Volcano-seismic event supplied by W. McCausland
S = SUDS.read_suds(vfname, full=true)
S2 = read_data("sac", sac_fstr, full=true)
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

# SUDS sample files
# from eq_wvm1.sud
S = SUDS.read_suds(eq_wvm1_file)
S1 = read_data("sac", eq_wvm1_pat)
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
S1 = read_data("sac", eq_wvm2_pat)
for n = 1:S1.n
  i = findid(S1.id[n], S)
  if i > 0
    @test isapprox(S.x[i], S1.x[n])
  else
    @warn(string(S1.id[n], " not found in S; check id conversion!"))
  end
end

# from lsm.sud
S = SUDS.read_suds(lsm_file)
S1 = read_data("sac", lsm_pat)
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
S1 = read_data("sac", rot_pat)
for n = 1:S1.n
  i = findid(S1.id[n], S)
  if i > 0
    @test isapprox(S.x[i], S1.x[n])
  else
    @warn(string(S1.id[n], " not found in S; check id conversion!"))
  end
end


nothing
