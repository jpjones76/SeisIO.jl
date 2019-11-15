printstyled("  guess\n", color=:light_green)

# This should error
@test_throws ErrorException guess("www.google.com")

# These should work
printstyled("    ability to determine file types unambiguously\n", color=:light_green)
ah1f    = path*"/SampleFiles/AH/ah1.f"
ah2f    = path*"/SampleFiles/AH/ah2.f"
pasf    = path*"/SampleFiles/SEGY/03.334.12.09.00.0362.1"
sac     = path .* [ "/SampleFiles/SAC/test_be.sac",
                    "/SampleFiles/SAC/test_le.sac" ]
segyf   = path*"/SampleFiles/SEGY/03.334.12.09.00.0362.1"
segpat  = path*"/SampleFiles/SEGY/03*"
sudsf   = path*"/SampleFiles/Restricted/10081701.WVP"
uw      = path*"/SampleFiles/UW/" .* ["00012502123W"]
geocsv1 = path*"/SampleFiles/ASCII/geo-tspair.csv"
geocsv2 = path*"/SampleFiles/ASCII/geo-slist.csv"
lennf   = path*"/SampleFiles/ASCII/0215162000.c00"
seisf   = path*"/SampleFiles/SEIS/2019_M7.1_Ridgecrest.seis"
# xml_stfile = path*"/SampleFiles/fdsnws-station_2017-01-12T03-17-42Z.xml"
# resp_file = path*"/SampleFiles/RESP.cat"
self = path*"/Utils/test_guess.jl"

redirect_stdout(out) do
  @test guess(ah1f, v=3) == ("ah1", true)
end
@test guess(ah2f) == ("ah2", true)
[@test guess(i) == ("bottle", false) for i in ls(path*"/SampleFiles/Bottle/*")]
@test guess(pasf) == ("passcal", false)
[@test guess(i) == ("mseed", false) for i in ls(path*"/SampleFiles/SEED/*seed")]
[@test guess(i) == ("sac", false) for i in sac]
[@test guess(i) == ("sac", false) for i in ls(path*"/SampleFiles/SUDS/*sac")]
if safe_isfile(sudsf)
  @test guess(sudsf) == ("suds", false)
end
[@test guess(i) == ("uw", true) for i in uw]
@test guess(geocsv1) == ("geocsv", false)
@test guess(geocsv2) == ("geocsv.slist", false)
@test guess(lennf) == ("lennartz", false)
# @test guess(xml_stfile) == ("sxml", false)
# @test guess(resp_file) == ("resp", false)
@test guess(seisf) == ("seisio", false)
@test guess(self) == ("unknown", false)

# Restricted files
if safe_isdir(path*"/SampleFiles/Restricted")
  path2 = (path*"/SampleFiles/Restricted/")
  [@test guess(i) == ("mseed", false) for i in ls(path2*"*seed")]
  [@test guess(i) == ("win32", true) for i in ls(path2*"*cnt")]
  @test guess(path2*"test_rev_1.segy") == ("segy", true)
end

# Does the method for read_data with guess actually work?
printstyled("    read_data with guess()\n", color=:light_green)
SEG = read_data(segyf, full=true)
@test SEG.misc[1]["gain_const"] == 32
@test SEG.gain[1] == SEG.misc[1]["scale_fac"]
@test isapprox(1.0/SEG.gain[1], 4.47021e-07/SEG.misc[1]["gain_const"], atol=eps(Float32))
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

St = SeisData()
read_data!(St, segyf, full=true)
if Sys.iswindows() == false
  Su = SeisData()
  read_data!(Su, segpat, full=true)
  # @test SEG == St == Su
  # BUG: path inconsistency with symlinks leads to different :src strings
end
