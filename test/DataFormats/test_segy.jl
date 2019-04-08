import SeisIO: safe_isfile
segy_file_1 = string(path, "/SampleFiles/test_PASSCAL.segy")
segy_file_2 = string(path, "/SampleFiles/Restricted/test_rev_1.segy")

printstyled("  SEG Y\n", color=:light_green)
printstyled("    PASSCAL/NMT SEG Y\n", color=:light_green)
SEG = readsegy(segy_file_1, passcal=true, full=true)

printstyled("      header integrity\n", color=:light_green)

SEG = readsegy(segy_file_1, passcal=true, full=true)
@test 1/SEG.gain[1] == SEG.misc[1]["scale_fac"] == 4.80184e+08
@test SEG.fs[1] == 100.0 == 1.0e6 / SEG.misc[1]["delta"]
@test SEG.misc[1]["trace_seq_line"] == 1
@test SEG.misc[1]["trace_seq_file"] == 1
@test SEG.misc[1]["event_no"] == 1
@test SEG.misc[1]["channel_no"] == 1
@test SEG.misc[1]["trace_id_code"] == 1
@test SEG.misc[1]["h_units_code"] == 2
@test SEG.misc[1]["nx"] == 32767
@test SEG.misc[1]["samp_rate"] == 0
@test SEG.misc[1]["gain_type"] == 1
@test SEG.misc[1]["gain_const"] == 1
@test SEG.misc[1]["year"] == 2014
@test SEG.misc[1]["day"] ==  158
@test SEG.misc[1]["hour"] == 0
@test SEG.misc[1]["minute"] == 0
@test SEG.misc[1]["second"] == 0
@test SEG.misc[1]["ms"] == 0
@test SEG.misc[1]["time_code"] == 2
@test SEG.misc[1]["trigyear"] == 0
@test SEG.misc[1]["trigday"] == 0
@test SEG.misc[1]["trighour"] == 0
@test SEG.misc[1]["trigminute"] == 0
@test SEG.misc[1]["trigsecond"] == 0
@test SEG.misc[1]["trigms"] == 0
@test SEG.misc[1]["data_form"] == 1
@test SEG.misc[1]["inst_no"] == 0x0000
@test SEG.misc[1]["station_name"] == "TDH"
@test SEG.misc[1]["sensor_serial"] == ""
@test SEG.misc[1]["channel_name"] == "EHZ"

# Location
printstyled("      sensor position\n", color=:light_green)
h_sc = Float64(get(SEG.misc[1], "h_sc", 1.0))
h_sc = abs(h_sc)^(h_sc < 0.0 ? -1 : 1)
z_sc = Float64(get(SEG.misc[1], "z_sc", 1.0))
z_sc = abs(z_sc)^(z_sc < 0.0 ? -1 : 1)
x = get(SEG.misc[1], "rec_x", 0.0)
y = get(SEG.misc[1], "rec_y", 0.0)
z = get(SEG.misc[1], "rec_ele", 0.0)
@test SEG.loc[1][1] == y*h_sc == 45.2896      # 45.2896 in wash.sta
@test SEG.loc[1][2] == x*h_sc == -121.7915    # 121.791496 in wash.sta
@test SEG.loc[1][3] == z*z_sc == 1541.0       # 1541.0 in wash.sta

printstyled("      data integrity\n", color=:light_green)
@test Float64(SEG.misc[1]["max"]) == maximum(SEG.x[1]) == 2047.0
@test Float64(SEG.misc[1]["min"]) == minimum(SEG.x[1]) == -2048.0
@test ≈(SEG.x[1][1:10], [47.0, 46.0, 45.0, 44.0, 51.0, 52.0, 57.0, 59.0, 40.0, 34.0])
@test length(SEG.x[1]) == SEG.misc[1]["num_samps"] == 8640047

open("runtests.log", "a") do out
  redirect_stdout(out) do
    segyhdr(segy_file_1, passcal=true)
  end
end

if safe_isfile(segy_file_2)
 printstyled("    SEG Y rev 1\n", color=:light_green)
  SEG = readsegy(segy_file_2)
  open("runtests.log", "a") do out
    redirect_stdout(out) do
      segyhdr(segy_file_2)
    end
  end
else
  printstyled("    Skipped SEG Y rev 1\n", color=:light_green)
end
