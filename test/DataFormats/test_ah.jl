ah1_file = path*"/SampleFiles/ah1.f"
ahc_file = path*"/SampleFiles/lhz.ah"
ah_resp = path*"/SampleFiles/BRV.TSG.DS.lE21.resp"
ah2_file = path*"/SampleFiles/ah2.f"

printstyled("  AH (Ad Hoc)\n", color=:light_green)

printstyled("    v1\n", color=:light_green)
redirect_stdout(out) do
S = read_data("ah1", ah1_file)
S = read_data("ah1", ah1_file, full=true)
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
@test u2d(S.t[1][1,2]*1.0e-6) == DateTime("1984-04-20T06:42:00.12")
@test length(S.x[1]) == 720
@test eltype(S.x[1]) == Float32
@test isapprox(S.x[1][1:4], [-731.41247559, -724.41247559, -622.41247559, -470.4125061])

C = read_data("ah1", ahc_file, v=3, full=true)[1]

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
@test length(C.x) == 309
@test eltype(C.x) == Float32
@test C.fs == 1.0
@test u2d(C.t[1,2]*1.0e-6) == DateTime("1990-05-12T04:49:54.49")

# Event
@test isapprox(C.misc["ev_lat"], 49.037)
@test isapprox(C.misc["ev_lon"], 141.847)
@test isapprox(C.misc["ev_dep"], 606.0)
@test string(C.misc["ot"]) == "1990-05-12T04:50:00"
@test startswith(C.misc["data_comment"], "Streckeisen STS-1V/VBB Seismometer")
@test startswith(C.misc["event_comment"], "null")

C = read_data("ah1", ah_resp, full=true)[1]
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

printstyled("    v2\n", color=:light_green)
S = read_data("ah2", ah2_file, v=3)
S = read_data("ah2", ah2_file, v=3, full=true)
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
@test u2d(S.t[1][1,2]*1.0e-6) == DateTime("1984-04-20T06:42:00.12")
@test length(S.x[1]) == 720
@test eltype(S.x[1]) == Float32
@test isapprox(S.x[1][1:4], [-731.41247559, -724.41247559, -622.41247559, -470.4125061])

end
