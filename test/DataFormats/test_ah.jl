printstyled("  AH (Ad Hoc)\n", color=:light_green)
ah1_file  = path*"/SampleFiles/AH/ah1.f"
ah1_fstr  = path*"/SampleFiles/AH/ah1.*"
ahc_file  = path*"/SampleFiles/AH/lhz.ah"
ah_resp   = path*"/SampleFiles/AH/BRV.TSG.DS.lE21.resp"
ah2_file  = path*"/SampleFiles/AH/ah2.f"
ah2_fstr  = path*"/SampleFiles/AH/ah2.*"

printstyled("    v1\n", color=:light_green)
redirect_stdout(out) do
  S = verified_read_data("ah1", ah1_file, v=3)
  S = verified_read_data("ah1", ah1_file, full=true)
  S = verified_read_data("ah1", ah1_fstr, full=true, v=3, strict=false)
  @test S.n == 3

  S = read_data("ah1", ah1_fstr, full=true, v=3, strict=true)
  @test S.n == 4
  @test S.fs[1] == 4.0
  @test isapprox(S.gain[1], 64200.121094)
  @test isapprox(S.loc[1].lat, 35.599899)
  @test isapprox(S.loc[1].lon, -85.568802)
  @test isapprox(S.loc[1].el, 481.0)
  @test any([occursin("gdsn_tape",s) for s in S.notes[1]])
  @test any([occursin("demeaned",s) for s in S.notes[1]])
  @test length(S.resp[1].p) == 24
  @test length(S.resp[1].z) == 7
  @test u2d(S.t[1][1,2]*μs) == DateTime("1984-04-20T06:42:00.12")
  @test length(S.x[1]) == 720
  @test eltype(S.x[1]) == Float32
  @test isapprox(S.x[1][1:4], [-731.41247559, -724.41247559, -622.41247559, -470.4125061])

  C = verified_read_data("ah1", ahc_file, v=1, full=true)[1]

  # Station
  @test isapprox(C.loc.lat, 36.5416984)
  @test isapprox(C.loc.lon, 138.2088928)
  @test isapprox(C.loc.el, 422.0)
  @test isapprox(C.gain, 1.178e8)
  @test length(C.resp.p) == 10
  @test isapprox(C.resp.p[1], -0.0123f0 + 0.0123f0im)
  @test isapprox(C.resp.p[2], -0.0123f0 - 0.0123f0im)
  @test length(C.resp.z) == 3

  # Data
  @test length(C.x) == 1079
  @test eltype(C.x) == Float32
  @test C.fs == 1.0
  @test u2d(C.t[1,2]*μs) == DateTime("1990-05-12T04:49:54.49")

  # Event
  @test isapprox(C.misc["ev_lat"], 49.037)
  @test isapprox(C.misc["ev_lon"], 141.847)
  @test isapprox(C.misc["ev_dep"], 606.0)
  teststr = VERSION < v"1.6" ? "1990-05-12T04:50:08.7" : "1990-05-12T04:50:08.700"
  @test string(u2d(C.misc["ot"]*μs)) == teststr
  @test startswith(C.misc["data_comment"], "Streckeisen STS-1V/VBB Seismometer")
  @test startswith(C.misc["event_comment"], "null")

  C = verified_read_data("ah1", ah_resp, full=true, vl=true)[1]
  @test isapprox(C.loc.lat, 53.058060)
  @test isapprox(C.loc.lon, 70.282799)
  @test isapprox(C.loc.el, 300.0)
  @test isapprox(C.gain, 0.05)
  @test isapprox(C.resp.a0, 40.009960)
  @test length(C.resp.p) == 7
  @test isapprox(C.resp.p[1], -0.1342653f0 + 0.1168836f0im)
  @test length(C.resp.z) == 4
  @test startswith(C.misc["data_comment"], "DS response in counts/nm")
  @test startswith(C.misc["event_comment"], "Calibration_for_hg_TSG")
  @test any([occursin("brv2ah: ahtedit",s) for s in C.notes])
  @test any([occursin("demeaned",s) for s in C.notes])
  @test any([occursin("modhead",s) for s in C.notes])
  @test any([occursin("ahtedit",s) for s in C.notes])
end
printstyled("      append existing channel\n", color=:light_green)
test_chan_ext(ah1_file, "ah1", "nu.RSN..IPZ", 4.0, 1, 451291110190001)
test_chan_ext(ah1_file, "ah1", "nu.RSC..IPZ", 4.0, 1, 451291320120000)

printstyled("    v2\n", color=:light_green)
redirect_stdout(out) do
  S = verified_read_data("ah2", ah2_file, v=3)
  S = verified_read_data("ah2", ah2_file, v=3, full=true)
  S = verified_read_data("ah2", ah2_fstr, v=3, full=true, vl=true, strict=false)
  @test S.n == 1

  S = read_data("ah2", ah2_fstr, v=3, full=true, strict=true, vl=true)
  @test S.n == 4
  @test S.fs[1] == 4.0
  @test isapprox(S.gain[1], 64200.121094)
  @test isapprox(S.loc[1].lat, 35.599899)
  @test isapprox(S.loc[1].lon, -85.568802)
  @test isapprox(S.loc[1].el, 481.0)
  @test any([occursin("gdsn_tape",s) for s in S.notes[1]])
  @test any([occursin("demeaned",s) for s in S.notes[1]])
  @test length(S.resp[1].p) == 24
  @test length(S.resp[1].z) == 7
  @test u2d(S.t[1][1,2]*μs) == DateTime("1984-04-20T06:42:00.12")
  @test length(S.x[1]) == 720
  @test eltype(S.x[1]) == Float32
  @test isapprox(S.x[1][1:4], [-731.41247559, -724.41247559, -622.41247559, -470.4125061])
end
printstyled("      append existing channel\n", color=:light_green)
test_chan_ext(ah2_file, "ah2", "nu.RS..IP", 4.0, 1, 451291320120000)

printstyled("      custom user attributes\n", color=:light_green)
tmp_ah = "tmp.ah"
io = open(ah2_file, "r")
buf = read(io, 10636)
skip(io, 4)
append!(buf, reinterpret(UInt8, [bswap(Int32(1))]))
append!(buf, reinterpret(UInt8, [bswap(Int32(6))]))
append!(buf, codeunits("PEBKAC\0\0"))
append!(buf, reinterpret(UInt8, [bswap(Int32(41))]))
append!(buf, codeunits("problem exists between keyboard and chair\0\0\0"))
append!(buf, read(io))
close(io)

ah_out = open(tmp_ah, "w")
write(ah_out, buf)
close(ah_out)

S = read_data("ah2", tmp_ah, strict=true)
@test haskey(S.misc[4], "PEBKAC")
@test S.misc[4]["PEBKAC"] == "problem exists between keyboard and chair"
safe_rm(tmp_ah)
