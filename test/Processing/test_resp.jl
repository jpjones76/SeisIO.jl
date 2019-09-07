printstyled("  resp\n", color=:light_green)
sac_pz_file = path*"/SampleFiles/test_sac.pz"
non_resp = PZResp(p = Complex{Float32}[complex(1.0, 1.0)], z = Complex{Float32}[2.0/Complex(1.0, -1.0)])
Nx = 1000000
C = randSeisChannel(s=true)
taper!(C)

printstyled("    fctoresp\n", color=:light_green)
r = fctoresp(0.2f0)
r2 = fctoresp(2.0f0)

printstyled("    translate_resp (SeisData)\n", color=:light_green)
S = randSeisData(3, s=1.0)
S.resp[1] = fctoresp(0.2f0)
S.resp[2] = fctoresp(0.2f0)
S.resp[3] = fctoresp(2.0f0)
S.x[1] = randn(Float32, S.t[1][end,1])
for i = 1:3
  S.units[i] = rand(["m", "m/s", "m/s2"])
end
detrend!(S)
taper!(S)
U = deepcopy(S)
T = translate_resp(S, r)
@test typeof(T.x[1]) == Array{Float32,1}
translate_resp!(S, r)
nanfill!(S)
nanfill!(T)
@test S==T

printstyled("    remove_resp (SeisData)\n", color=:light_green)
remove_resp!(S)
@test_logs (:info, Regex("nothing done")) remove_resp!(S)

T = translate_resp(T, non_resp)
for i = 1:S.n
  if isempty(findall(isnan.(S.x[i]))) && isempty(findall(isnan.(T.x[i])))
    @test isapprox(S.x[i], T.x[i])
  else
    @warn string("NaNs found! i = ", i)
  end
  @test S.resp[i] == non_resp
  @test T.resp[i] == non_resp
end

# unit tests
S = deepcopy(U)
update_resp_a0!(S)
fc = resptofc(S.resp[1])
@test isapprox(fc, 0.2f0)
fc = resptofc(S.resp[3])
@test isapprox(fc, 2.0f0)

# test for channel ranges
S = deepcopy(U)
S1 = remove_resp(S, chans=1:3)
for i = 1:S1.n
  @test (S1[i] == U[i]) == (i < 4 ? false : true)
end

# test for MultiStageResp
U = randSeisData(4, s=1.0)
U.resp[1] = fctoresp(0.2f0)
U.resp[2] = MultiStageResp(6)
U.resp[2].stage[1] = fctoresp(15.0f0)
U.resp[3] = fctoresp(2.0f0)
U.resp[4] = fctoresp(1.0f0)
ungap!(U)
detrend!(U)
update_resp_a0!(U)
S = deepcopy(U)
T = deepcopy(U)
S1 = translate_resp(S, r, chans=1:3)
T1 = translate_resp(T, r, chans=1:3)
@test S1[1] == T1[1]
@test S1[2] == T1[2]
@test S1[3] == T1[3]
@test S1[4] == T1[4] == U[4]
for i = 2:6
  @test S1.resp[2].stage[i] == T1.resp[2].stage[i] == U.resp[2].stage[i]
end
@test S1.resp[2].stage[1] != U.resp[2].stage[1]
@test S1.resp[2].stage[1] == T1.resp[2].stage[1]

# SeisChannel method extension
printstyled("    translate_resp (SeisChannel)\n", color=:light_green)
C = randSeisChannel(s=true)
C.t = [1 0; Nx 0]
C.x = randn(Nx)
C.resp = deepcopy(r2)
D = translate_resp(C, r)
translate_resp!(C, r)
@test C == D
@test C.x != zeros(eltype(C.x), lastindex(C.x))

# Here, we expect nothing to happen
translate_resp!(C, r)

C = randSeisChannel(s=true)
taper!(C)
D = deepcopy(C)
remove_resp!(C)
D = remove_resp(D)
@test C.resp == non_resp

# test on SeisData created from SACPZ file
printstyled("    compatibility with SACPZ responses\n", color=:light_green)
S = read_sacpz(sac_pz_file)
U = deepcopy(S)
for i = 1:S.n
  nx = round(Int64, S.fs[i]*3600)
  S.t[i] = [1 0; nx 0]
  S.x[i] = rand(eltype(S.x[i]), nx).-0.5
end
r = S.resp[1]
# f0 should not matter here; it should work
translate_resp!(S, r)
for i = 1:S.n
  @test S.resp[i] == U.resp[1]
end
