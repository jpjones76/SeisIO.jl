# The file test.mseed comes from an older IRIS libmseed, found by anowacki
# It has a more complicated structure than the test.mseed file in more recent
# versions of libmseed, which reads with no issues
printstyled("  mini-SEED\n", color=:light_green)

printstyled("    sample rate\n", color=:light_green)

# Tests from SEED manual v2.4 page 110
import SeisIO.SEED.update_dt!
r1 = [33, 330, 3306, -60, 1, -10, -1]
r2 = [10, 1, -10, 1, -10, 1, -10]
fs = [330.0, 330.0, 330.6, 1.0/60.0, 0.1, 0.1, 0.1]

for i = 1:length(r1)
  BUF.r1 = r1[i]
  BUF.r2 = r2[i]
  update_dt!(BUF)
  @test isapprox(1.0/BUF.dt, fs[i])
end

test_sac_file     = string(path, "/SampleFiles/SAC/test_le.sac")
test_mseed_file   = string(path, "/SampleFiles/SEED/test.mseed")
test_mseed_pat    = string(path, "/SampleFiles/SEED/t*.mseed")
mseed_vals_file   = string(path, "/SampleFiles/SEED/test_mseed_vals.txt")

printstyled("    file read\n", color=:light_green)

@test_throws ErrorException verified_read_data("mseed", test_sac_file)

S = verified_read_data("mseed", test_mseed_file, v=0, strict=false)
@test isequal(S.id[1], "NL.HGN.00.BHZ")
@test ≈(S.fs[1], 40.0)
@test ≈(S.gain[1], 1.0)
@test isequal(string(u2d(S.t[1][1,2]*μs)), "2003-05-29T02:13:22.043")
@test ≈(S.x[1][1:5], [ 2787, 2776, 2774, 2780, 2783 ])

# mseed with mmap
printstyled("    file read with mmap\n", color=:light_green)
Sm = read_data("mseed", test_mseed_file, v=0, memmap=true)
@test Sm == S

# Test breaks if memory-resident SeisIOBuf structure SEED is not reset
S1 = verified_read_data("mseed", test_mseed_file, v=0, strict=false)
if Sys.iswindows() == false
  S2 = verified_read_data("mseed", test_mseed_pat, v=0, strict=false)
  @test S2.src[1] == abspath(test_mseed_pat)
  S2.src = S1.src
  @test S == S1 == S2
end


mseed_vals = readdlm(mseed_vals_file, ',', comments=true, comment_char='#')
seedvals = Dict{String,Any}()
ntest = size(mseed_vals,1)
for i = 1:ntest
  seedvals[mseed_vals[i,1]] = Float32.(mseed_vals[i, 2:end])
end

if safe_isdir(path*"/SampleFiles/Restricted")
  printstyled("    mseed test files (time gaps, blockette types)\n", color=:light_green)
  redirect_stdout(out) do
    seed_support()
    files = ls(path*"/SampleFiles/Restricted/*mseed")
    for f in files
      println(stdout, "attempting to read ", f)
      S = SeisData()
      ae = any([occursin(i, f) for i in ("blkt2000", "detection.record", "text-encoded", "timing.500s")])
      if ae
        verified_read_data!(S, "mseed", f, v=3, allow_empty=true, strict=false)
      else
        verified_read_data!(S, "mseed", f, v=2, strict=false)
      end

      # Test that our encoders return the expected values
      (tmp, fname) = splitdir(f)
      if haskey(seedvals, fname)
        x = get(seedvals, :fname, Float32[])
        nx = lastindex(x)
        y = getindex(getfield(S, :x), 1)[1:nx]
        @test isapprox(x,y)
      end

      if occursin("text-encoded", f)
        @test haskey(S.misc[1], "seed_ascii") == true
        str = split(S.misc[1]["seed_ascii"][1], "\n", keepempty=false)
        @test occursin("Quanterra Packet Baler Model 14 Restart.", str[1])

      elseif occursin("detection.record",f )
        ev_rec = get(S.misc[1], "seed_event", "no record")[1]
        @test ev_rec == "2004,7,28,20,28,6,185,80.0,0.39999998,18.0,dilatation,1,3,2,1,4,0,2,0,Z_SPWWSS"

      elseif occursin("SHW.UW", f)
        println("testing read accuracy of SHW.UW with ", f)
        @test size(S.t[1],1) >= 158
        @test size(S.t[2],1) >= 8
        @test string(u2d(S.t[1][1,2]*μs)) == "1980-03-22T20:45:18.349"
        @test isequal(S.id, String[ "UW.SHW..EHZ", "UW.SHW..SHZ" ])
        @test ≈(S.fs, Float64[104.085000, 52.038997])
        @test ≈(S.x[1][1:5], Float64[-68.0, -57.0, -71.0, -61.0, -52.0])
        fnames = ls(path*"/SampleFiles/Restricted/1980*SHZ.D.SAC")

        C = S[2]
        @test w_time(t_win(C.t, C.fs), C.fs) == C.t
        t = t_win(C.t, C.fs)[:,1]
        W = Array{DateTime,1}(undef, 0)
        for i=1:length(t)
          # push!(W, round(u2d(t[i]*μs), Second))
          push!(W, u2d(t[i]*μs))
        end

        Y = Array{DateTime,1}(undef,0)
        for f in fnames
          seis = verified_read_data("sac", f)[1]
          push!(Y, u2d(seis.t[1,2]*μs))
        end
        #[round(u2d(i*μs), Second) for i in t]
        # println("W = ", string.(W))
        # println("Y = ", string.(Y))
        Δ = [abs(.001*(W[i]-Y[i]).value)*C.fs for i=1:length(Y)]
        @test maximum(Δ) < 1.0
      else
        @test isempty(S) == false
      end
    end
  end
else
  printstyled("  extended SEED tests skipped. (files not found; is this Appveyor?)\n", color=:green)
end

# Tests for unparseable blockette and data format
mseed_out = "test2.mseed"
io = open(test_mseed_file, "r")
buf = read(io)
close(io)

buf[40] = 0x03                # 3 blockettes follow
buf[53] = 0x13                # 19 = Steim-3
buf[67:68] .= [0x00, 0x54]    # byte 84
buf[85:86] .= [0x01, 0x90]    # [400]
buf[87:88] .= [0x00, 0x00]    # next blockette at "byte 0" means we're done
write(mseed_out, buf)

S1 = read_data("mseed", test_mseed_file, v=0)[1]
S2 = read_data("mseed", mseed_out, v=0)[1]

# Check that skipping an unparseable data type on a new channel doesn't
# affect channel start time or data read-in
printstyled("    unparseable data\n", color=:light_green)
δx = length(S1.x)-length(S2.x)
@test div(S2.t[1,2]-S1.t[1,2], round(Int64, sμ/S1.fs)) == length(S1.x)-length(S2.x)
@test S1.x[δx+1:end] == S2.x

# Check that bytes skipped are accurately logged
printstyled("    unparseable blockettes\n", color=:light_green)
@test any([occursin("3968 bytes skipped", i) for i in S2.notes])

# Done
rm(mseed_out)
