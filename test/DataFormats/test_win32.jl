# win32 with gaps
# When merging and ungapping many same-channel files, are they mapped to one SeisData channel?
if Sys.islinux()
  printstyled("  win_32...\n", color=:light_green)
  @info(string(timestamp(), ": win_32 tests use an SSL-encrypted tarball."))
  fname = path*"/SampleFiles/Win32/2014092709*.cnt"
  cfile = path*"/SampleFiles/Win32/03_02_27_20140927.euc.ch"
  S = readwin32(fname, cfile)

  # There should be 8 channels
  @test S.n==8

  # There should be exactly 360000 points per channel (all are 100 Hz)
  nx = [length(S.x[i]) for i=1:1:S.n]
  @test minimum(nx)==360000
  @test maximum(nx)==360000

  # Check against SAC files
  printstyled("    ...checking read integrity against HiNet SAC files...\n", color=:light_green)
  testfiles = "/home/josh/SAC/" .* ["20140927000000.V.ONTA.E.SAC",
                                    "20140927000000.V.ONTA.H.SAC",
                                    "20140927000000.V.ONTA.N.SAC",
                                    "20140927000000.V.ONTA.U.SAC",
                                    "20140927000000.V.ONTN.E.SAC",
                                    "20140927000000.V.ONTN.H.SAC",
                                    "20140927000000.V.ONTN.N.SAC",
                                    "20140927000000.V.ONTN.U.SAC"]

  # SAC files prepared in SAC with these commands from day-long Ontake files
  # beginning at midnight Japan time converted to SAC with win32 precompiled
  # utilities
  #
  # SAC commands that generate these from day-long SAC files:
  # cut b 32400 35999.99
  # r /home/josh/SAC/20140927000000.V.*.SAC"
  # ch b 0 nzjday 270 nzhour 09
  # w over
  # q

  U = SeisData()
  for f in testfiles
    T = rsac(f)
    push!(U, T)
  end

  # ID correspondence
  j = Array{Int64,1}(undef, S.n)
  for (n,i) in enumerate(S.id)
    id = split(i, '.')
    id[3] = ""
    id[2] = "V"*id[2]
    c = id[4][3:3]
    if c == "Z"
      id[4] = "U"
    else
      id[4] = c
    end

    id = join(id, '.')
    j[n] = findid(id, U)
  end

  inds = Array{Array{Int64,1}}(undef, S.n)
  for (n,i) in enumerate(j)
    inds[n] = findall(abs.(S.x[n]-U.x[i]).>eps())
  end

  # The only time gaps should be what are in the logs:
  # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.H, beginning 2014-09-27T09:58:00)
  # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137
  # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.U, beginning 2014-09-27T09:58:00)
  # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137
  # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.N, beginning 2014-09-27T09:58:00)
  # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137
  # ┌ Warning: Time gap detected! (15.0 s at V.ONTA.E, beginning 2014-09-27T09:58:00)
  # └ @ SeisIO ~/.julia/dev/SeisIO/src/Formats/Win32.jl:137

  for i = 1:4
    @test length(inds[i]) == 1500
    @test div(first(inds[i]), 6000) == 58
    @test div(last(inds[i]), 6000) == 58
    r₀ = rem(first(inds[i]), 6000)
    r₁ = rem(last(inds[i]), 6000)
    @test round((r₁ - r₀)/100, digits=1) == 15.0
  end
else
  printstyled("  skipping win_32 test (Windows)...\n", color=:light_green)
end
