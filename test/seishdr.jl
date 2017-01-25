using Base.Test, Compat

println(STDOUT, "SeisHdr test (seishdr_test.jl)...")
H = randseishdr()
wseis("seis.hdr", H)
H2 = rseis("seis.hdr")[1]
@test_approx_eq(H==H2, true)
rm("seis.hdr")

#  What is this...? Comes up in randseishdr()
# ERROR: LoadError: MethodError: no method matching rand(::MersenneTwister, ::Type{String})
# Closest candidates are:
#   rand(::AbstractRNG, ::Type{T}, ::Tuple{Vararg{Int64,N}}) at random.jl:300
#   rand(::AbstractRNG, ::Type{T}, ::Integer, ::Integer...) at random.jl:301
#   rand{I<:Base.Random.FloatInterval}(::MersenneTwister, ::Type{I<:Base.Random.FloatInterval}) at random.jl:122
#   ...
#  in rand!(::MersenneTwister, ::Array{String,1}) at .\random.jl:308
#  in rand(::Type{T}, ::Int64) at .\random.jl:232
#  in pop_rand!(::Dict{String,Any}, ::Int64) at D:\Code\SeisIO_Stable\src\Misc\randseis.jl:17
#  in randseishdr() at D:\Code\SeisIO_Stable\src\Misc\randseis.jl:249
#  in include_from_node1(::String) at .\loading.jl:488
# while loading D:\Code\SeisIO_Stable\test\seishdr_test.jl, in expression starting on line 2
