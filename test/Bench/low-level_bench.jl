using BenchmarkTools, Printf, SeisIO, Statistics
import SeisIO: fastread, fastread1, fastskip, fast_readbytes!
BenchmarkTools.DEFAULT_PARAMETERS.samples   = 1000
BenchmarkTools.DEFAULT_PARAMETERS.gcsample  = false
testfile = "test.dat"
io = open(testfile, "w")
N = 10000
write(io, rand(UInt8, N))
close(io)

# establish test values
T = [Bool, Int8, UInt8, Int16, UInt16, Float16, Int32, UInt32, Float32, Int64, UInt64, Float64]

# read tests
println("read tests begin")

# println("single val")
# io = open(testfile, "r")
# seekstart(io)
# @printf("%9s |  %9s |  %9s |  %9s\n", "Type", "read", "fastread", "fastread1")
# for i in 1:length(T)
#   V = T[i]
#   b1 = @benchmark (read($io, $V); skip($io, -1*sizeof($V)))
#   b2 = @benchmark (fastread($io, $V); skip($io, -1*sizeof($V)))
#   b3 = @benchmark (fastread1($io, $V); skip($io, -1*sizeof($V)))
#   @printf("%9s |  %9.3f    %9.3f    %9.3f    \n", string(V), median(b1.times), median(b2.times), median(b3.times))
# end
# close(io)

println("array")
io = open(testfile, "r")
seekstart(io)
T = [UInt8]
@printf("%9s | %9s | %9s \n", "Type", "read", "fastread")
println("----------+-----------+----------")
for i in 1:length(T)
  X = Array{T[i],1}(undef, div(N,sizeof(T[i])))

  b1 = @benchmark (readbytes!($io, $X, $N); seekstart($io))
  b2 = @benchmark (fast_readbytes!($io, $X, $N); seekstart($io))
  @printf("%9s | %9.3f | %9.3f\n", string(T[i]), median(b1.times), median(b2.times))
end
close(io)
