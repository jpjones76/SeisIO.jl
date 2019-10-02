segy_file_1   = string(path, "/SampleFiles/SEGY/03.334.12.09.00.0362.1")
segy_file_2   = string(path, "/SampleFiles/Restricted/test_rev_1.segy")
segy_be_file  = string(path, "/SampleFiles/SEGY/02.104.00.00.08.7107.2")
segy_fpat     = string(path, "/SampleFiles/SEGY/02.104.00.00.08.7107.2")

printstyled("  SEG Y\n", color=:light_green)
printstyled("    PASSCAL/NMT SEG Y\n", color=:light_green)
SEG = read_data("passcal", segy_file_1, full=true)

printstyled("      header integrity\n", color=:light_green)

SEG = read_data("passcal", segy_file_1, full=true)
@test SEG.misc[1]["gain_const"] == 32
@test SEG.gain[1] == SEG.misc[1]["scale_fac"]
@test isapprox(SEG.gain[1], 4.47021e-07/SEG.misc[1]["gain_const"], atol=eps(Float32))
@test SEG.fs[1] == 100.0 == 1.0e6 / SEG.misc[1]["delta"]
@test lastindex(SEG.x[1]) == 247698
@test SEG.misc[1]["trace_seq_line"] == 3
@test SEG.misc[1]["trace_seq_file"] == 3
@test SEG.misc[1]["event_no"] == 1
@test SEG.misc[1]["channel_no"] == 2
@test SEG.misc[1]["trace_id_code"] == 3
@test SEG.misc[1]["h_units_code"] == 2
@test SEG.misc[1]["nx"] == 32767
@test SEG.misc[1]["samp_rate"] == 10000
@test SEG.misc[1]["gain_type"] == 1
@test SEG.misc[1]["year"] == 2003
@test SEG.misc[1]["day"] ==  334
@test SEG.misc[1]["hour"] == 12
@test SEG.misc[1]["minute"] == 9
@test SEG.misc[1]["second"] == 0
@test SEG.misc[1]["ms"] == 5
@test SEG.misc[1]["time_code"] == 2
@test SEG.misc[1]["trigyear"] == 2003
@test SEG.misc[1]["trigday"] == 334
@test SEG.misc[1]["trighour"] == 12
@test SEG.misc[1]["trigminute"] == 9
@test SEG.misc[1]["trigsecond"] == 0
@test SEG.misc[1]["trigms"] == 5
@test SEG.misc[1]["data_form"] == 1
@test SEG.misc[1]["inst_no"] == 0x016a # 0362
@test strip(SEG.misc[1]["sensor_serial"]) == "UNKNOWN"
@test strip(SEG.misc[1]["station_name"]) == "362"
@test strip(SEG.misc[1]["channel_name"]) == "N"

# Location
printstyled("      sensor position\n", color=:light_green)
h_sc = Float64(get(SEG.misc[1], "h_sc", 1.0))
h_sc = abs(h_sc)^(h_sc < 0.0 ? -1 : 1)
z_sc = Float64(get(SEG.misc[1], "z_sc", 1.0))
z_sc = abs(z_sc)^(z_sc < 0.0 ? -1 : 1)
x = get(SEG.misc[1], "rec_x", 0.0)
y = get(SEG.misc[1], "rec_y", 0.0)
z = get(SEG.misc[1], "rec_ele", 0.0)
# @test SEG.loc[1].lat == y*h_sc == 45.2896      # 45.2896 in wash.sta
# @test SEG.loc[1].lon == x*h_sc == -121.7915    # 121.791496 in wash.sta
# @test SEG.loc[1].el == z*z_sc == 1541.0       # 1541.0 in wash.sta

printstyled("      data integrity\n", color=:light_green)
@test Float64(SEG.misc[1]["max"]) == maximum(SEG.x[1]) == 396817
@test Float64(SEG.misc[1]["min"]) == minimum(SEG.x[1]) == -416512
# @test ≈(SEG.x[1][1:10], [47.0, 46.0, 45.0, 44.0, 51.0, 52.0, 57.0, 59.0, 40.0, 34.0])
@test length(SEG.x[1]) == SEG.misc[1]["num_samps"] == 247698

redirect_stdout(out) do
  segyhdr(segy_file_1, passcal=true)
end

printstyled("      big-endian support\n", color=:light_green)

SEG = read_data("passcal", segy_be_file, full=true, swap=true)
@test SEG.n == 1
@test SEG.id ==  ["...spn"] # lol, WHY BOB
@test isapprox(SEG.gain[1], 5.92346875e-8, atol=eps(Float32))
@test SEG.misc[1]["trigyear"] == SEG.misc[1]["year"] == 2002

printstyled("    wildcard support\n", color=:light_green)

SEG = read_data("passcal", segy_fpat, full=true, swap=true)
@test SEG.n == 1
@test Float64(SEG.misc[1]["max"]) == maximum(SEG.x[1]) == 49295.0
@test Float64(SEG.misc[1]["min"]) == minimum(SEG.x[1]) == -54454.0
@test ≈(SEG.x[1][1:5], [-615.0, -3994.0, -4647.0, -895.0, 190.0])
@test length(SEG.x[1]) == SEG.misc[1]["num_samps"] == 180027

if has_restricted
 printstyled("    SEG Y rev 1\n", color=:light_green)
  SEG = read_data("segy", segy_file_2)
  redirect_stdout(out) do
    segyhdr(segy_file_2)
  end
else
  printstyled("    Skipped SEG Y rev 1\n", color=:red)
end
