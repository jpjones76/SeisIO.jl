printstyled("  time test with synthetic timeseries data\n", color=:light_green)

ts = round(Int64, sμ*d2u(DateTime("2020-03-01T00:00:00")))
fs = 100.0
gain = 32.0
id = "XX.STA..BHZ"
loc = GeoLoc( lat = 45.560121,
              lon = -122.617068,
              el = 53.04 )
Δ = 10000
files = ["1.sac", "2.sac", "3.sac", "4.sac", "5.sac", "6.sac", "7.sac"]
tos   = [    0.0,    10.0,   20.01,   20.02,    30.0,    40.0,    60.0]
nx    = [   1000,     999,       1,     100,       1,    1000,    1000]

C = SeisChannel(id = id,
                gain = gain,
                loc = loc,
                fs = fs )
S0 = SeisData()

printstyled("    creating files\n", color=:light_green)
for i = 1:length(files)
  fname = files[i]
  C.x = randn(Float32, nx[i])
  C.t = [1 ts+round(Int64, tos[i]*1000000); nx[i] 0]
  push!(S0, C)
  writesac(C, fname=fname)
end

# Read back in
printstyled("    reading to test all channel-extension cases\n", color=:light_green)
S = SeisData()
read_data!(S, "sac", files[1])
xi = cumsum(nx)
δt = round.(Int64, tos.*sμ) .+ (nx.-1).*Δ

# Expect:
# no gaps, precise read
@test S.t[1] == [1 ts; nx[1] 0]
@test endtime(S.t[1], S.fs[1]) == Δ*(nx[1]-1)+ts
@test S0.x[1] == S.x[1]
@test S0.gain[1] == S.gain[1]

# append file 2 to create case 1
read_data!(S, "sac", files[2])
@test S.t[1] == [1 ts; xi[2] 0]
@test S0.x[2] == S.x[1][nx[1]+1:xi[2]]

# append file 3 to create case 4
read_data!(S, "sac", files[3])
@test S.t[1] == [1 ts; xi[3] 20000]
@test S0.x[3] == S.x[1][xi[2]+1:xi[3]]

# append file 4 to create case 2
read_data!(S, "sac", files[4])
@test S.t[1] == [1 ts; xi[3] 20000; xi[4] 0]
@test S0.x[4] == S.x[1][xi[3]+1:xi[4]]

# append file 5 to create case 3
δt0 = round(Int64, sμ*(tos[5]-tos[4]-nx[4]/fs)) # I canceled a +Δ and a -Δ
read_data!(S, "sac", files[5])
@test S.t[1] == [1 ts; xi[3] 20000; xi[5] δt0]
@test S0.x[5] == S.x[1][xi[4]+1:xi[5]]

# append file 6 to create case 6
t_old = copy(S.t[1])
δt0 = round(Int64, sμ*(tos[6]-tos[5]-nx[5]/fs)) # I canceled a +Δ and a -Δ
read_data!(S, "sac", files[6])
@test S.t[1] == vcat(t_old, [xi[5]+1 δt0; xi[6] 0])
@test S0.x[6] == S.x[1][xi[5]+1:xi[6]]

# append file 7 to create case 5
t_old = copy(S.t[1])
read_data!(S, "sac", files[7])
δt0 = round(Int64, sμ*(tos[7]-tos[6]-nx[7]/fs))
@test S.t[1] == vcat(t_old[1:end-1,1:2], [t_old[end,1]+1 δt0], [xi[7] 0])

# finally, did we get it all right?
printstyled("    final checks\n", color=:light_green)
T = t_collapse(vcat([t_expand(i, fs) for i in S0.t]...), fs)
X = vcat([i for i in S0.x]...)
@test T == S.t[1]
@test X == S.x[1]
@test gain == S.gain[1]
@test fs == S.fs[1]
@test id == S.id[1]
@test ≈(loc.lat, S.loc[1].lat, rtol=2eps(Float32))
@test ≈(loc.lon, S.loc[1].lon, rtol=2eps(Float32))
@test ≈(loc.el, S.loc[1].el, rtol=2eps(Float32))

printstyled("    cleanup\n", color=:light_green)
for i in files
  safe_rm(i)
end
