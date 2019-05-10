printstyled("  taper!\n", color=:light_green)

# Unit tests
# mktaper!
N = 20
fs = 100.0
W = Array{Float32,1}(undef, N)
L = length(W)
mktaper!(W, N)
@test eltype(W) == Float32

# taper_seg
X = randn(Float32, N)
X = X.-mean(X)
Y = deepcopy(X)
μ = Float32(mean(X))
taper_seg!(X, W, L, μ, rev=true)
X = deepcopy(Y)
taper_seg!(X, W, L, μ)
@test isapprox(abs.(X)./abs.(Y), W)

# Test that tapering works on SeisData objects
S = randSeisData(24, s=1.0)
deleteat!(S, findall(S.fs.<1.0))
taper!(S)

# Test that tapering works on SeisChannel objects
C = randSeisChannel(s=true)
ungap!(C)
taper!(C)

C = randSeisChannel(s=true)
taper!(C)

# Test that tapering ignores fs=0
S = randSeisData(10, c=1.0, s=0.0)[2:10]
i = findall(S.fs.==0.0)
S = S[i]
U = deepcopy(S)
taper!(S)
@test S==U

C = S[1]
U = deepcopy(C)
taper!(C)
@test C==U

# Test for L_tap < L in a SeisChannel
C = randSeisChannel()
nx = length(C.x)
ny = round(Int, 2*fs)
C.t = vcat(C.t[1:end-1,:], [nx+1 1000000], [nx + ny 0])
append!(C.x, randn(eltype(C.x), ny))
taper!(C)

# test on SeisEvent
V = randSeisEvent()
taper!(V)

# Test for out-of-place tapering
C = randSeisChannel()
S = randSeisData(10, c=1.0, s=0.0)[2:10]
V = randSeisEvent()
D = taper(C)
T = taper(S)
W = taper(V)
