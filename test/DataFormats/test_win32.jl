import SeisIO:safe_isfile, findhex

hexIDs = UInt16[0x0001, 0x0002, 0x0003]
@test findhex(0x0000, hexIDs) == -1
@test findhex(0x0001, hexIDs) == 1
@test findhex(0x0002, hexIDs) == 2
@test findhex(0x0003, hexIDs) == 3

# win32 with gaps
cfile = path*"/SampleFiles/Restricted/03_02_27_20140927.euc.ch"
if safe_isfile(cfile)
  printstyled("  win32\n", color=:light_green)
  @info(string(timestamp(), ": win32 tests use an SSL-encrypted tarball."))
  open("runtests.log", "a") do out
    redirect_stdout(out) do
      fname = path*"/SampleFiles/Restricted/2014092709*.cnt"
      cfile = path*"/SampleFiles/Restricted/03_02_27_20140927.euc.ch"
      S = readwin32(fname, cfile, v=1)

      # There should be 8 channels
      @test S.n==8

      # There should be exactly 360000 points per channel (all are 100 Hz)
      nx = [length(S.x[i]) for i=1:1:S.n]
      @test minimum(nx)==360000
      @test maximum(nx)==360000

      # Check against SAC files
      printstyled("    checking read integrity against HiNet SAC files\n", color=:light_green)
      testfiles = path*"/SampleFiles/Restricted/" .* ["20140927000000.V.ONTA.E.SAC",
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
        id[1] = "JP"
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

      for k = 1:S.n
        i = j[k]
        if !isempty(inds[i])
          @test length(inds[i]) == 1500
          @test div(first(inds[i]), 6000) == 58
          @test div(last(inds[i]), 6000) == 58
          r₀ = rem(first(inds[i]), 6000)
          r₁ = rem(last(inds[i]), 6000)
          @test round((r₁ - r₀)/100, digits=1) == 15.0
        end
      end
    end
  end

  # Converting the mean to single-point precision gives exactly the same
  # result as SAC conversion from win32; however, the average computed
  # over an hour will be slightly different.
  #
  # This can be verified using the script "ontake_test.jl" in ../../internal_tests/

  # Now test the other two bits types, 4-bit Int ...
  printstyled("    testing Int4 and Int24 handling\n", color=:light_green)
  fname = path*"/SampleFiles/Restricted/2014092700000302.cnt"
  S = SeisData()
  open("runtests.log", "a") do out
    redirect_stdout(out) do
      readwin32!(S, fname, cfile, v=1)
    end
  end
  @test length(S.x[1]) == 60*S.fs[1]
  @test maximum(S.x[1]) == 11075.0
  @test minimum(S.x[1]) == -5026.0

  # ...and 24-bit bigendian Int...
  fname = path*"/SampleFiles/Restricted/2014092712000302.cnt"
  readwin32!(S, fname, cfile)
  @test length(S.x[1]) == round(Int64, 60*S.fs[1]) == S.t[1][end,1]
  ii = findlast(S.id.=="V.ONTA.23.EHH")
  @test maximum(S.x[ii]) == 14896.0
  @test minimum(S.x[ii]) == -12651.0
  for id in unique(S.id)
    @test length(findall(S.id.==id))==2
  end

  # ...and 32-bit bigendian Int ...
  cfile = path*"/SampleFiles/Restricted/chandata_20140927.txt"
  fname = path*"/SampleFiles/Restricted/2014092712370207VM.cnt"
  readwin32!(S, fname, cfile)

else
  printstyled("  win32 data format skipped. (files not found; is this Appveyor?)\n", color=:light_green)
end
