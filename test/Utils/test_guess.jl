printstyled("  guess\n", color=:light_green)

# This should error
@test_throws ErrorException guess("www.google.com")

# These should work
printstyled("    ability to determine file types unambiguously\n", color=:light_green)
ah1f = path*"/SampleFiles/ah1.f"
ah2f = path*"/SampleFiles/ah2.f"
pasf = path*"/SampleFiles/test_PASSCAL.segy"
sac = [ path*"/SampleFiles/one_day.sac",
        path*"/SampleFiles/test_be.sac",
        path*"/SampleFiles/test_le.sac" ]
sudsf = path*"/SampleFiles/SUDS/10081701.WVP"
uw = path*"/SampleFiles/" .* ["00012502123W", "99011116541W"]
geocsv1 = path*"/SampleFiles/FDSNWS.IRIS.geocsv"
geocsv2 = path*"/SampleFiles/geocsv_slist.csv"
lennf = path*"/SampleFiles/0215162000.c00"

redirect_stdout(out) do
  @test guess(ah1f, v=3) == (true, "ah1")
end
@test guess(ah2f) == (true, "ah2")
[@test guess(i) == (false, "bottle") for i in ls(path*"/SampleFiles/Bottle/*")]
@test guess(pasf) == (false, "passcal")
[@test guess(i) == (false, "mseed") for i in ls(path*"/SampleFiles/*seed")]
[@test guess(i) == (false, "sac") for i in sac]
[@test guess(i) == (false, "sac") for i in ls(path*"/SampleFiles/SUDS/*sac")]
@test guess(sudsf) == (false, "suds")
[@test guess(i) == (true, "uw") for i in uw]
@test guess(geocsv1) == (false, "geocsv")
@test guess(geocsv2) == (false, "geocsv.slist")
@test guess(lennf) == (false, "lennasc")

# Restricted files
if safe_isdir(path*"/SampleFiles/Restricted")
  path2 = (path*"/SampleFiles/Restricted/")
  [@test guess(i) == (false, "mseed") for i in ls(path2*"*seed")]
  [@test guess(i) == (true, "win32") for i in ls(path2*"*cnt")]
  @test guess(path2*"test_rev_1.segy") == (true, "segy")
end

# Does the method for read_data with guess actually work?
printstyled("    read_data with guess(); no file format given...\n", color=:light_green)
segy_file_1 = path * "/SampleFiles/test_PASSCAL.segy"
Sg = read_data(segy_file_1, full=true)
@test Sg.gain[1] == Sg.misc[1]["scale_fac"] == 4.80184e+08
@test Sg.fs[1] == 100.0 == 1.0e6 / Sg.misc[1]["delta"]
@test lastindex(Sg.x[1]) == 8640047
@test Sg.misc[1]["trace_seq_line"] == 1
@test Sg.misc[1]["trace_seq_file"] == 1
@test Sg.misc[1]["event_no"] == 1
@test Sg.misc[1]["channel_no"] == 1
@test Sg.misc[1]["trace_id_code"] == 1
@test Sg.misc[1]["h_units_code"] == 2
@test Sg.misc[1]["nx"] == 32767
@test Sg.misc[1]["samp_rate"] == 0
@test Sg.misc[1]["gain_type"] == 1
@test Sg.misc[1]["gain_const"] == 1
@test Sg.misc[1]["year"] == 2014
@test Sg.misc[1]["day"] ==  158
@test Sg.misc[1]["hour"] == 0
@test Sg.misc[1]["minute"] == 0
@test Sg.misc[1]["second"] == 0
@test Sg.misc[1]["ms"] == 0
@test Sg.misc[1]["time_code"] == 2
@test Sg.misc[1]["trigyear"] == 0
@test Sg.misc[1]["trigday"] == 0
@test Sg.misc[1]["trighour"] == 0
@test Sg.misc[1]["trigminute"] == 0
@test Sg.misc[1]["trigsecond"] == 0
@test Sg.misc[1]["trigms"] == 0
@test Sg.misc[1]["data_form"] == 1
@test Sg.misc[1]["inst_no"] == 0x0000
@test strip(Sg.misc[1]["sensor_serial"]) == ""
@test strip(Sg.misc[1]["station_name"]) == "TDH"
@test strip(Sg.misc[1]["channel_name"]) == "EHZ"
h_sc = Float64(get(Sg.misc[1], "h_sc", 1.0))
h_sc = abs(h_sc)^(h_sc < 0.0 ? -1 : 1)
z_sc = Float64(get(Sg.misc[1], "z_sc", 1.0))
z_sc = abs(z_sc)^(z_sc < 0.0 ? -1 : 1)
x = get(Sg.misc[1], "rec_x", 0.0)
y = get(Sg.misc[1], "rec_y", 0.0)
z = get(Sg.misc[1], "rec_ele", 0.0)
@test Sg.loc[1].lat == y*h_sc == 45.2896      # 45.2896 in wash.sta
@test Sg.loc[1].lon == x*h_sc == -121.7915    # 121.791496 in wash.sta
@test Sg.loc[1].el == z*z_sc == 1541.0       # 1541.0 in wash.sta
@test Float64(Sg.misc[1]["max"]) == maximum(Sg.x[1]) == 2047.0
@test Float64(Sg.misc[1]["min"]) == minimum(Sg.x[1]) == -2048.0
@test ≈(Sg.x[1][1:10], [47.0, 46.0, 45.0, 44.0, 51.0, 52.0, 57.0, 59.0, 40.0, 34.0])
@test length(Sg.x[1]) == Sg.misc[1]["num_samps"] == 8640047
