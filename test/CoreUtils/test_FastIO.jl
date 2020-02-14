printstyled("  FastIO\n", color=:light_green)

# create testfile
testfile = "test.dat"
io = open(testfile, "w")
x = rand(UInt8, 1000)
x[255] = 0x0a
write(io, x)
close(io)

function fastio_test!(io::IO)
  T = [Bool, Int8, UInt8, Int16, UInt16, Float16, Int32, UInt32, Float32, Int64, UInt64, Float64]
  X = Array{Any, 1}(undef, length(T))
  Y = similar(X)
  r = rand(1:100)

  # =====================================================================
  # fastpos, fasteof
  @test fastpos(io) == position(io) == 0
  @test fasteof(io) == eof(io) == false
  seekend(io); p1=position(io); seekstart(io)
  fastseekend(io); p2=fastpos(io); seekstart(io)
  @test p1==p2

  # =====================================================================
  # test that a sequence of read, skip, and seek operations is identical
  skip(io, r)
  for (i,t) in enumerate(T)
    X[i] = read(io, t)
  end
  p1 = position(io)
  seek(io, r)
  p2 = position(io)
  seekstart(io)

  fastskip(io, r)
  for (i,t) in enumerate(T)
    Y[i] = fastread(io, t)
  end
  p3 = fastpos(io)
  fastseek(io, r)
  p4 = fastpos(io)

  @test p1==p3
  @test p2==p4
  for i=1:length(X)
    if isnan(X[i])
      @test isnan(Y[i])
    else
      @test X[i]==Y[i]
    end
  end

  seekstart(io)
  s1 = readline(io)
  seekstart(io)
  s2 = readline(io)
  @test s1 == s2
  return nothing
end

# =====================================================================
# done with file; read into buffer and repeat tests
printstyled("    IOStream\n", color=:light_green)
io = open(testfile, "r")
fastio_test!(io)
close(io)

printstyled("    generic IO\n", color=:light_green)
readbuf = read(testfile)
io = IOBuffer(readbuf)
fastio_test!(io)
close(io)

safe_rm(testfile)
