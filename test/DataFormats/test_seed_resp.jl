resp_file_0 = path*"/SampleFiles/SEED/YUK7.RESP"
resp_file_1 = path*"/SampleFiles/SEED/RESP.cat"
resp_file_2 = path*"/SampleFiles/SEED/RESP.*"
rtol = eps(Float32)

printstyled("  SEED RESP\n", color=:light_green)
printstyled("    single-record file\n", color=:light_green)
S = read_seed_resp(resp_file_0, units=true)

printstyled("    multi-record file\n", color=:light_green)
S = read_seed_resp(resp_file_1, units=true)

# Channel 1 =================================================================
# Station info
@test S.id[1] == "CO.HAW.00.HHZ"
@test S.units[1] == "m/s"

R = S.resp[1]
for f in fieldnames(MultiStageResp)
  @test length(getfield(R, f)) == 11
end

# First stage
@test typeof(R.stage[1]) == PZResp64
@test isapprox(R.stage[1].a0, 5.71404E+08, rtol=rtol)
@test isapprox(R.stage[1].f0, 1.0)
@test length(R.stage[1].z) == 2
@test length(R.stage[1].p) == 5
@test isapprox(R.stage[1].z[1], 0.0+0.0im)
@test isapprox(R.stage[1].z[2], 0.0+0.0im)
@test isapprox(R.stage[1].p[1], -3.70080E-02 + 3.70080E-02im)
@test isapprox(R.stage[1].p[2], -3.70080E-02 - 3.70080E-02im)
@test isapprox(R.stage[1].p[3], -5.02650E+02 + 0.0im)
@test isapprox(R.stage[1].p[4], -1.00500E+03 + 0.0im)
@test isapprox(R.stage[1].p[5], -1.13100E+03 + 0.0im)

# Second-to-last stage
@test typeof(R.stage[10]) == CoeffResp
@test length(R.stage[10].b) == 251
@test length(R.stage[10].a) == 0
@test isapprox(R.stage[10].b[1:5], [+2.18133E-08, +1.07949E-07, +2.97668E-07, +6.73280E-07, +1.29904E-06])
@test R.fac[10] == 5
@test R.os[10] == 0
@test R.delay[10] ≈ 2.5000E-01
@test R.corr[10] ≈ 2.5000E-01
@test R.gain[10] ≈ 1.0
@test R.fg[10] ≈ 1.0

# Last stage
@test typeof(R.stage[11]) == CoeffResp
@test length(R.stage[11].b) == 251
@test length(R.stage[11].a) == 0
@test isapprox(R.stage[11].b[end-4:end], [-2.22747E-02, -1.03605E-01, +2.25295E-02, +3.17473E-01, +4.77384E-01])
@test R.fac[11] == 2
@test R.os[11] == 0
@test R.delay[11] ≈ 1.25
@test R.corr[11] ≈ 1.25
@test R.gain[11] ≈ 1.0
@test R.fg[11] ≈ 1.0
@test S.fs[1] == R.fs[end]/R.fac[end]

# Channel 5 =================================================================
@test S.id[5] == "PD.NS04..HHZ"
@test S.units[5] == "m/s"
@test S.gain[5] ≈ 1.7e8

# Total stages
R = S.resp[5]
for f in fieldnames(MultiStageResp)
  @test length(getfield(R, f)) == 4
end

# First stage
@test typeof(R.stage[1]) == PZResp64
@test isapprox(R.stage[1].a0, 1.4142, rtol=rtol)
@test isapprox(R.stage[1].f0, 1.0)
@test length(R.stage[1].z) == 2
@test length(R.stage[1].p) == 2
@test isapprox(R.stage[1].z[1], 0.0+0.0im)
@test isapprox(R.stage[1].z[2], 0.0+0.0im)
@test isapprox(R.stage[1].p[1], -4.442900E+00 + 4.442900E+00im)
@test isapprox(R.stage[1].p[2], -4.442900E+00 - 4.442900E+00im)

# Second stage
@test typeof(R.stage[2]) == CoeffResp
@test isapprox(R.fs[2], 3.000000E+03)
@test R.fac[2] == 1
@test R.os[2] == 0
@test R.delay[2] ≈ 0.0
@test R.corr[2] ≈ 0.0
@test R.gain[2] ≈ 1.0e6
@test R.fg[2] ≈ 0.0

# Third stage
@test typeof(R.stage[3]) == CoeffResp
@test length(R.stage[3].b) == 180
@test length(R.stage[3].a) == 0
@test isapprox(R.stage[3].b[1:3], [1.327638E-08, 4.137208E-08, 9.662694E-08])
@test R.fac[3] == 6
@test R.os[3] == 0
@test R.delay[3] ≈ 0.0
@test R.corr[3] ≈ 0.0
@test R.gain[3] ≈ 1.0
@test R.fs[3] ≈ 3000.0
@test R.fg[3] ≈ 0.0

# Fourth stage
@test typeof(R.stage[4]) == CoeffResp
@test length(R.stage[4].b) == 160
@test length(R.stage[4].a) == 0
@test isapprox(R.stage[4].b[1:3], [3.863808E-09, 2.261888E-09, -2.660399E-08])
@test R.fs[4] ≈ 500.0
@test R.fac[4] == 5
@test R.os[4] == 0
@test R.delay[4] ≈ 0.0
@test R.corr[4] ≈ 0.0
@test R.gain[4] ≈ 1.0
@test R.fg[4] ≈ 0.0

# Last Channel ===============================================================
n = lastindex(S.id)
@test S.id[n] == "XX.NS236..SHZ"
@test S.units[n] == "m/s"
@test S.gain[n] ≈ 3.450000e+02

# Total stages
R = S.resp[n]
for f in fieldnames(MultiStageResp)
  @test length(getfield(R, f)) == 2
end

# First stage
@test typeof(R.stage[1]) == PZResp64
@test isapprox(R.stage[1].a0, 1.0, rtol=rtol)
@test isapprox(R.stage[1].f0, 5.0)
@test length(R.stage[1].z) == 2
@test length(R.stage[1].p) == 2
@test isapprox(R.stage[1].z[1], 0.0 + 0.0im)
@test isapprox(R.stage[1].z[2], 0.0 + 0.0im)
@test isapprox(R.stage[1].p[1], -4.44 + 4.44im)
@test isapprox(R.stage[1].p[2], -4.44 - 4.44im)
@test R.fac[1] == 0
@test R.os[1] == 0
@test R.delay[1] ≈ 0.0
@test R.corr[1] ≈ 0.0
@test R.gain[1] ≈ 345.0
@test R.fg[1] ≈ 5.0

# Second stage
@test typeof(R.stage[2]) == CoeffResp
@test length(R.stage[2].b) == 1
@test length(R.stage[2].a) == 0
@test isapprox(R.stage[2].b[1], 1.0)
@test R.fac[2] == 1
@test R.os[2] == 0
@test R.delay[2] ≈ 0.0
@test R.corr[2] ≈ 0.0
@test R.gain[2] ≈ 1.0
@test R.fs[2] ≈ 40.0
@test R.fg[2] ≈ 5.0

# ===========================================================================
# Test that response start and end times are used correctly to determine
# which responses are kept

# These control values were extracted manually from RESP.cat
gain  = [1.007E+09, 8.647300E+08]
a0    = [62695.2, 86083]
f0    = [0.02, 0.02]
p1    = [-8.985E+01 + 0.0im, -5.943130E+01 + 0.0im]

#=
Target window 1:
B050F03     Station:     ANMO
B050F16     Network:     IU
B052F03     Location:    ??
B052F04     Channel:     BHZ
B052F22     Start date:  1989,241
B052F23     End date:    1991,023,22:25

Target window 2:
B050F03     Station:     ANMO
B050F16     Network:     IU
B052F03     Location:    ??
B052F04     Channel:     BHZ
B052F22     Start date:  1995,080,17:16
B052F23     End date:    1995,195
=#

for (i,t0) in enumerate([632188800000000,  # SeisIO.mktime(1990, 013, 0, 0, 0, 0)
                         801792000000000,  # SeisIO.mktime(1995, 150, 0, 0, 0, 0)
                         ])
  nx = 20000
  C = SeisChannel(id = "IU.ANMO..BHZ")
  C.t = [1 t0; nx 0]
  C.x = randn(nx)
  S = SeisData(C)
  read_meta!(S, "resp", resp_file_1)
  j = findid(S, "IU.ANMO..BHZ")
  @test S.gain[j] ≈ gain[i]
  @test S.resp[j].stage[1].a0 ≈ a0[i]
  @test S.resp[j].stage[1].f0 ≈ f0[i]
  @test S.resp[j].stage[1].p[1] ≈ p1[i]
end

# ===========================================================================
# Test that mutli-file read commands work
n += 1
printstyled("    multi-file read\n", color=:light_green)
S = read_meta("resp", resp_file_2, units=true)

# Channel 1, file 2 =========================================================
# Station info
@test S.id[n] == "AZ.DHL..BS1"
@test S.units[n] == "m/m"

R = S.resp[n]
for f in fieldnames(MultiStageResp)
  @test length(getfield(R, f)) == 9
end

# First stage
@test typeof(R.stage[1]) == PZResp64
@test R.fac[1] == 0
@test R.os[1] == 0
@test R.delay[1] ≈ 0.0
@test R.corr[1] ≈ 0.0
@test R.gain[1] ≈ 3.23
@test R.fg[1] ≈ 1.0
@test R.fs[1] ≈ 0.0

# Second stage
@test typeof(R.stage[2]) == CoeffResp
@test length(R.stage[2].b) == 0
@test length(R.stage[2].a) == 0
@test R.fac[2] == 1
@test R.os[2] == 0
@test R.delay[2] ≈ 0.0
@test R.corr[2] ≈ 0.0
@test R.gain[2] ≈ 5.263200E+05
@test R.fg[2] ≈ 1.0
@test R.fs[2] ≈ 1.28e5

# Third stage
@test typeof(R.stage[3]) == CoeffResp
@test length(R.stage[3].b) == 29
@test length(R.stage[3].a) == 0
@test R.stage[3].b[1:3] ≈ [2.441410E-04, 9.765620E-04, 2.441410E-03]
@test R.fac[3] == 8
@test R.os[3] == 0
@test R.delay[3] ≈ 8.750000E-04
@test R.corr[3] ≈ 8.750000E-04
@test R.gain[3] ≈ 1.0
@test R.fg[3] ≈ 1.0
@test R.fs[3] ≈ 1.28e5

# Strain channel
n = findid(S, "PB.CHL1.LM.LS1")
@test S.units[n] == "m/m"

R = S.resp[n]
for f in fieldnames(MultiStageResp)
  @test length(getfield(R, f)) == 4
end

# First stage
@test typeof(R.stage[1]) == PZResp64
@test R.stage[1].a0 ≈ 1.0
@test R.stage[1].f0 ≈ 0.0
@test isempty(R.stage[1].z)
@test isempty(R.stage[1].p)
@test R.fac[1] == 0
@test R.os[1] == 0
@test R.delay[1] ≈ 0.0
@test R.corr[1] ≈ 0.0
@test R.gain[1] ≈ 5.901050E-07
@test R.fg[1] ≈ 0.0
@test R.fs[1] ≈ 0.0

# Second stage
@test typeof(R.stage[2]) == PZResp64
@test R.stage[2].a0 ≈ 1.0
@test R.stage[2].f0 ≈ 0.0
@test length(R.stage[2].z) == 0
@test length(R.stage[2].p) == 4
@test R.stage[2].p[1:2] ≈ [-8.3E-02+0.0im, -8.4E-02+0.0im]
@test R.fac[2] == 0
@test R.os[2] == 0
@test R.delay[2] ≈ 0.0
@test R.corr[2] ≈ 0.0
@test R.gain[2] ≈ 1.0
@test R.fg[2] ≈ 0.0
@test R.fs[2] ≈ 0.0

# Third stage
@test typeof(R.stage[3]) == CoeffResp
@test length(R.stage[3].b) == 0
@test length(R.stage[3].a) == 0
@test R.fac[3] == 1
@test R.os[3] == 0
@test R.delay[3] ≈ 0.0
@test R.corr[3] ≈ 0.0
@test R.gain[3] ≈ 3.052E-04
@test R.fg[3] ≈ 0.0
@test R.fs[3] ≈ 10.0

# Fourth stage
@test typeof(R.stage[4]) == CoeffResp
@test length(R.stage[4].b) == 10
@test length(R.stage[4].a) == 1
@test R.stage[4].a[1] ≈ 1.0
for i = 1:10
  @test R.stage[4].b[i] ≈ 0.1
end
@test R.fac[4] == 10
@test R.os[4] == 4
@test R.delay[4] ≈ 0.5
@test R.corr[4] ≈ 0.0
@test R.gain[4] ≈ 1.0
@test R.fg[4] ≈ 0.0
@test R.fs[4] ≈ 10.0
