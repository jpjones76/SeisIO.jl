# The file test.mseed comes from an older IRIS libmseed, found by anowacki
# It has a more complicated structure than the test.mseed file in more recent
# versions of libmseed, which reads with no issues
printstyled("  mini-SEED file read\n", color=:light_green)

@test_throws ErrorException readmseed(string(path, "/SampleFiles/nonexist.mseed"), v=0)

S = readmseed(string(path, "/SampleFiles/test.mseed"), v=0)
@test isequal(S.id[1], "NL.HGN.00.BHZ")
@test ≈(S.fs[1], 40.0)
@test ≈(S.gain[1], 1.0)
@test isequal(string(u2d(S.t[1][1,2]*1.0e-6)), "2003-05-29T02:13:22.043")
@test ≈(S.x[1][1:5], [ 2787, 2776, 2774, 2780, 2783 ])

if safe_isdir(path*"/SampleFiles/Restricted")
  printstyled("    file reads with many time gaps\n", color=:light_green)

  open("runtests.log", "a") do out
    redirect_stdout(out) do
      files = ls(path*"/SampleFiles/Restricted/*mseed")
      for f in files
        println(stdout, "attempting to read ", f)
        S = SeisData()
        readmseed!(S, f, v=3)
        @test isempty(S) == false

        if occursin("text-encoded", f)
          @test haskey(S.misc[1], "seed_ascii") == true
          str = split(S.misc[1]["seed_ascii"][1], "\n", keepempty=false)
          @test occursin("Quanterra Packet Baler Model 14 Restart.", str[1])

        elseif occursin("detection.record",f )
          ev_rec = get(S.misc[1], "seed_event", "no record")[1]
          @test ev_rec == "2004,7,28,20,28,6,185,80.0,0.39999998,18.0,dilatation,1,3,2,1,4,0,2,0,Z_SPWWSS"

        elseif occursin("SHW.UW", f)
          @test size(S.t[1],1) >= 158
          @test size(S.t[2],1) >= 8
          @test string(u2d(S.t[1][1,2]*1.0e-6)) == "1980-03-22T20:45:18.349"
          @test isequal(S.id, String[ "UW.SHW..EHZ", "UW.SHW..SHZ" ])
          @test ≈(S.fs, Float64[104.085000, 52.038997])
          @test ≈(S.x[1][1:5], Float64[-68.0, -57.0, -71.0, -61.0, -52.0])
          fnames = ls(path*"/SampleFiles/Restricted/1980*SHZ.D.SAC")

          C = S[2]
          @test w_time(t_win(C.t, C.fs), C.fs) == C.t
          t = t_win(C.t, C.fs)[:,1]
          W = Array{DateTime,1}(undef, 0)
          for i=1:length(t)
            # push!(W, round(u2d(t[i]*1.0e-6), Second))
            push!(W, u2d(t[i]*1.0e-6))
          end

          Y = Array{DateTime,1}(undef,0)
          for f in fnames
            seis = readsac(f)
            push!(Y, u2d(seis.t[1,2]*1.0e-6))
          end
          #[round(u2d(i*1.0e-6), Second) for i in t]
          Δ = [abs(.001*(W[i]-Y[i]).value)*C.fs for i=1:length(Y)]
          @test maximum(Δ) < 1.0
        else
          @test isempty(S) == false
        end
      end
    end
  end
else
  printstyled("  extended readmseed tests skipped. (files not found; is this Appveyor?)\n", color=:green)
end
