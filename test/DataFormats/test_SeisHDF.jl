printstyled("  ASDF\n", color=:light_green)
printstyled("    read_hdf5\n", color=:light_green)

hdf       = path*"/SampleFiles/HDF5/2days-40hz.h5"
hdf_pat   = path*"/SampleFiles/HDF5/2days-40hz.h*"
hdf_out1  = "test1.h5"
hdf_out2  = "test2.h5"
hdf_out3  = "test3.h5"
hdf_out4  = "test4.h5"
hdf_evt   = path*"/SampleFiles/HDF5/example.h5"
safe_rm(hdf_out1)
safe_rm(hdf_out2)
safe_rm(hdf_out3)
safe_rm(hdf_out4)

id  = "CI.SDD..HHZ"
idr = "C*.SDD..HH?"
ts  = "2019-07-07T23:00:00"
te  = "2019-07-08T02:00:00"

# id_to_regex
@test id_to_regex("*.*.*.*") == r".*\.*\.*\.*"
@test id_to_regex("C*.SDD..") == r"C.*\.SDD\.\."
@test id_to_regex("CI.SDD..HHZ") == r"CI\.SDD\.\.HHZ"
@test id_to_regex("C*.SDD..HH?") == r"C.*\.SDD\.\.HH."

# id_match
S2 = SeisData(SeisChannel(), SeisChannel(id="CI.SDD..HHZ"))
@test id_match(id, S2) == id_match(idr, S2) == [2]

S1 = SeisData()
read_hdf5!(S1, hdf, ts, te, id = id)
S2 = read_hdf5(hdf, ts, te, id = id)
@test S1 == S2
S2 = read_asdf(hdf, id, ts, te, true, 0)
@test S1 == S2

# check file wildcards
S2 = read_hdf5(hdf_pat, ts, te, id = id)
@test S1 == S2

# check the default id
S2 = read_hdf5(hdf_pat, ts, te)
@test S1 == S2

# check that FDSN-style wildcards work
S2 = read_asdf(hdf, idr, ts, te, true, 0)
@test S1 == S2

# Check channel matching
S2 = SeisData(SeisChannel(id="CI.SDD..HHZ"))
read_asdf!(S2, hdf, idr, ts, te, true, 0)
@test S1 == S2

S2 = SeisData(SeisChannel(id="CI.SDD..HHZ",
                          fs=40.0,
                          t=[1 1562543940000000; 40 0],
                          x=randn(40)))
read_asdf!(S2, hdf, idr, ts, te, true, 0)
@test S1.x[1] == S2.x[1][41:end]
@test string(u2d(S2.t[1][1,2]*1.0e-6)) == "2019-07-07T23:59:00"

@test_throws ErrorException read_hdf5(hdf, ts, te, fmt="MatlabLol")

printstyled("    scan_hdf5\n", color=:light_green)
@test scan_hdf5(hdf) == ["CI.SDD"]
@test scan_hdf5(hdf, level="trace") == ["/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_", "/Waveforms/CI.SDD/StationXML"]
@test_throws ErrorException scan_hdf5(hdf, level="response")
@test_throws ErrorException scan_hdf5(hdf, fmt="MatlabLol")


# HDF event read
printstyled("    asdf_rqml\n", color=:light_green)
(H,R) = asdf_rqml(hdf_evt)
@test H[1].id == "20120404_0000041"
@test H[2].id == "20120404_0000038"
@test H[3].id == "20120404_0000039"
@test H[1].loc.lat ≈ 41.818
@test H[1].loc.lon ≈ 79.689
@test H[1].loc.dep ≈ 1.0
@test H[1].mag.val ≈ 4.4
@test H[1].mag.scale == "mb"
@test H[2].loc.lat ≈ 39.342
@test H[2].loc.dep ≈ 14.4
@test H[2].mag.val ≈ 4.3
@test H[2].mag.scale == "ML"

io = h5open(hdf_evt)
(H1, R1) = asdf_rqml(io)
@test H == H1
@test R == R1

# =========================================================
# HDF write
printstyled("    write_hdf5\n", color=:light_green)
@test_throws ErrorException write_hdf5(hdf_out1, S1, fmt="MatlabLol")
safe_rm(hdf_out1)

# ASDF write test 1: can we write to a new file?
printstyled("      write to new file\n", color=:light_green)
write_hdf5( hdf_out1, S1 )
S2 = read_hdf5(hdf_out1, ts, te, id = id)
for f in datafields
  (f in (:src, :notes)) && continue
  @test isequal(getfield(S1, f), getfield(S2, f))
end

# ASDF write test 2: can we overwrite parts of an existing file?
printstyled("      add to existing file\n", color=:light_green)
ts  = "2019-07-08T00:00:00"
te  = "2019-07-08T02:00:00"
S3 = read_hdf5(hdf_out1, ts, te, id = id)
for i in 1:S3.n
  S3.x[i] .= (2.0.*S3.x[i])
end
redirect_stdout(out) do
  write_hdf5( hdf_out1, S3, ovr=true, v=3 )
  push!(S3, SeisChannel(id="YY.ZZTOP.00.LEG", fs=50.0))

  # This should work but throw a warning
  write_hdf5( hdf_out1, S3, v=3 )

  # This should fail
  @test_throws ErrorException write_hdf5( hdf_out1, S3, ovr=true, v=3 )

  # GphysChannel extension
  C = S3[1]
  write_hdf5( hdf_out1, C, v=3 )
  safe_rm(hdf_out1)
  deleteat!(S3, 2)

  # Force write to channel with existing net.sta
  write_hdf5(hdf_out1, S3)
  ts  = "2019-07-08T10:00:00"
  te  = "2019-07-08T12:00:00"
  S4 = read_hdf5(hdf, ts, te)
  write_hdf5(hdf_out1, S4, ovr=true, add=true)
end
@test scan_hdf5(hdf_out1, level="trace") == [
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-08T00:00:00__2019-07-08T02:00:00__hhz",
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-08T00:00:00__2019-07-08T23:59:59.975__hhz",
  "/Waveforms/CI.SDD/StationXML"
  ]
safe_rm(hdf_out1)

# ASDF write test 3: write with gaps
printstyled("      write to new file with gaps\n", color=:light_green)
ts  = "2019-07-08T10:00:00"
te  = "2019-07-08T12:00:00"
read_hdf5!(S3, hdf, ts, te)
merge!(S3)
@test S3.n == 1 # fails if MultiStageResp merge! bug is back
write_hdf5( hdf_out1, S3 )
scan3 = scan_hdf5(hdf_out1, level="trace")
@test scan3 == [
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-08T00:00:00__2019-07-08T02:00:00__hhz",
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-08T10:00:00__2019-07-08T12:00:00__hhz",
  "/Waveforms/CI.SDD/StationXML"
  ]

# ASDF write test 4: file with multiple stations and channels
if has_restricted
  S = read_data("sac", path*"/SampleFiles/Restricted/20140927000000*SAC")
  redirect_stdout(out) do
    write_hdf5( hdf_out1, S, v=3 )
  end
  id = S.id[3]
  ts = "2014-09-27T09:00:00"

  # Test for intended read behavior
  printstyled("        are written traces the right length?\n", color=:light_green)
  te = "2014-09-27T10:00:00"
  C = read_hdf5(hdf_out1, ts, te, id = id)[1]
  @test length(C.x) == 360000 # Stop at last available sample

  te = "2014-09-27T09:59:59.99"
  C = read_hdf5(hdf_out1, ts, te, id = id)[1]
  @test length(C.x) == 360000 # Exact

  ts = "2014-09-27T09:00:00.01"
  te = "2014-09-27T09:59:59.90"
  C2 = read_hdf5(hdf_out1, ts, te, id = id)[1]
  @test length(C2.x) == 359990 # Exact, ten samples shorter
  @test C.x[2:5] == C2.x[1:4]

  # test 1: are the right trace names created?
  printstyled("        are the right trace names created?\n", color=:light_green)
  S1 = SeisData()
  read_hdf5!(S1, hdf, "2019-07-07T23:00:00", "2019-07-08T02:00:00", id = "CI.SDD..HHZ")

  append!(S, S1)
  safe_rm(hdf_out1)
  redirect_stdout(out) do
    write_hdf5(hdf_out1, S, add=true, ovr=true, v=3, tag="raw")
  end
  @test scan_hdf5(hdf_out1, level="trace") == [
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-07T23:59:59.975__raw",
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-08T00:00:00__2019-07-08T23:59:59.975__raw",
  "/Waveforms/CI.SDD/StationXML",
  "/Waveforms/JP.VONTA/JP.VONTA..E__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTA/JP.VONTA..H__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTA/JP.VONTA..N__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTA/JP.VONTA..U__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTA/StationXML",
  "/Waveforms/JP.VONTN/JP.VONTN..E__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTN/JP.VONTN..H__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTN/JP.VONTN..N__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTN/JP.VONTN..U__2014-09-27T00:00:00__2014-09-27T23:59:59.99__raw",
  "/Waveforms/JP.VONTN/StationXML"
  ]

  # test 2: ONLY write CI.SDD..HHZ, JP.VONTA..H, JP.VONTA..N, JP.VONTA..U
  printstyled("        write with a channel sublist\n", color=:light_green)
  redirect_stdout(out) do
    write_hdf5(hdf_out2, S, chans=[2,3,4,9], add=true, ovr=true, v=3)
  end
  @test scan_hdf5(hdf_out2, level="trace") == [
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-07T23:59:59.975__hhz",
  "/Waveforms/CI.SDD/CI.SDD..HHZ__2019-07-08T00:00:00__2019-07-08T23:59:59.975__hhz",
  "/Waveforms/CI.SDD/StationXML",
  "/Waveforms/JP.VONTA/JP.VONTA..H__2014-09-27T00:00:00__2014-09-27T23:59:59.99__h",
  "/Waveforms/JP.VONTA/JP.VONTA..N__2014-09-27T00:00:00__2014-09-27T23:59:59.99__n",
  "/Waveforms/JP.VONTA/JP.VONTA..U__2014-09-27T00:00:00__2014-09-27T23:59:59.99__u",
  "/Waveforms/JP.VONTA/StationXML"
  ]

  # ensure the right trace data were written to these names
  S1 = read_hdf5(hdf_out2, "2014-09-27T09:00:00", "2014-09-27T09:59:59.99", id="*.VONTA..*", msr=false)
  S2 = S[[2,3,4]]
  for f in (:id, :loc, :fs, :gain, :resp, :t, :x)
    @test getfield(S1,f) == getfield(S2,f)
  end

  # ensure what's read back in are the correct traces with NaNs in the right places
  printstyled("        trace indexing with ovr=true\n", color=:light_green)
  S1 = read_hdf5(hdf_out2, "2014-09-27T08:00:00.00", "2014-09-27T10:00:00.00", id="*.VONTA..*")
  for i in 1:S1.n
    x = S1.x[i]
    @test length(x) == 720001
    @test isnan(last(x))
    @test eltype(x) == Float32
    for j in 1:360000
      @test isnan(x[j])
    end
  end

  # only an hour of non-NaN data; 24 hours of data created
  S1 = read_hdf5(hdf_out2, "2014-09-27T00:00:00.00", "2014-09-28T00:00:00.00", id="JP.VONTA..H")
  @test length(S1.x[1]) == 8640000
  @test length(S1.x[1])-length(findall(isnan.(S1.x[1]))) == 360000

  # data from CI.SDD should have no NaNs in this range; it's the exact range of S.x[9]
  S1 = read_hdf5(hdf_out2, "2019-07-07T23:00:00", "2019-07-08T02:00:00")
  @test S1.x[1] == S.x[9]
end

# HDF write with SeisEvent
Ev = Array{SeisEvent,1}(undef,3)
for i in 1:3
  Ev[i] = rse_wb(3)
end

printstyled("      asdf_wqml\n", color=:light_green)

printstyled("        append mode\n", color=:light_green)
SHDR = [Ev[i].hdr for i in 1:3]
SSRC = [Ev[i].source for i in 1:3]
asdf_wqml(hdf_out2, Ev[1].hdr, Ev[1].source)
asdf_wqml(hdf_out2, Ev[2])
asdf_wqml(hdf_out2, Ev)
asdf_wqml(hdf_out2, SHDR, SSRC)
(H,R) = asdf_rqml(hdf_out2)
@test length(H) == length(R) == 8

# Check that data are appended in the right order
inds = [1,2,1,2,3,1,2,3]
for i in 1:length(H)
  j = inds[i]
  compare_SeisHdr(Ev[j].hdr, H[i])
  compare_SeisSrc(Ev[j].source, R[i])
end

printstyled("        overwrite mode\n", color=:light_green)
asdf_wqml(hdf_out2, Ev[2].hdr, Ev[2].source, ovr=true, v=1)
(H,R) = asdf_rqml(hdf_out2)
@test length(H) == length(R) == 1
compare_SeisHdr(Ev[2].hdr, H[1])
compare_SeisSrc(Ev[2].source, R[1])

printstyled("        to new file\n", color=:light_green)
asdf_wqml(hdf_out4, SHDR, SSRC)
(H,R) = asdf_rqml(hdf_out4)
for i in 1:3
  compare_SeisHdr(SHDR[i], H[i])
  compare_SeisSrc(SSRC[i], R[i])
end

printstyled("        append file with incompatible QML\n", color=:light_green)

# Create incompatible QML in file
xml_evfile1 = path*"/SampleFiles/XML/fdsnws-event_2017-01-12T03-18-55Z.xml"
xml_buf = read(xml_evfile1)
io = h5open(hdf_out4, "r+")
o_delete(io, "QuakeML")
io["QuakeML"] = xml_buf
close(io)

# Now try to write to the file...does it work?
asdf_wqml(hdf_out4, SHDR, SSRC)
(H,R) = asdf_rqml(hdf_out4)
L = length(H)
H = H[L-2:L]
R = R[L-2:L]
for i in 1:3
  compare_SeisHdr(SHDR[i], H[i])
  compare_SeisSrc(SSRC[i], R[i])
end

printstyled("      write SeisEvent\n", color=:light_green)
printstyled("        to new file\n", color=:light_green)
write_hdf5(hdf_out3, Ev[1])

printstyled("        to existing file\n", color=:light_green)
write_hdf5(hdf_out3, Ev[2], chans=[1,2])

printstyled("        to appended file\n", color=:light_green)
write_hdf5(hdf_out3, Ev[3], chans=[3])

printstyled("      read_asdf_evt\n", color=:light_green)
EvCat = read_asdf_evt(hdf_out3, Ev[1].hdr.id, msr=false)

printstyled("        accuracy of SeisEvent i/o\n", color=:light_green)

printstyled("          single-event read\n", color=:light_green)
W = EvCat[1]
Ev1 = deepcopy(Ev[1])
compare_events(Ev1, W)

EvCat = read_asdf_evt(hdf_out3, Ev[2].hdr.id, msr=false)
W = EvCat[1]
Ev2 = deepcopy(Ev[2])
Ev2.data = Ev2.data[1:2]
compare_events(Ev2, W)

EvCat = read_asdf_evt(hdf_out3, Ev[3].hdr.id, msr=false)
W = EvCat[1]
Ev3 = deepcopy(Ev[3])
Ev3.data = Ev3.data[3]
compare_events(Ev3, W)

printstyled("          multi-event read\n", color=:light_green)
EvCat = read_asdf_evt(hdf_out3, msr=false)
compare_events(EvCat[1], Ev1)
compare_events(EvCat[2], Ev2)
compare_events(EvCat[3], Ev3)

if Sys.iswindows() == false
  printstyled("          multi-file read\n", color=:light_green)
  write_hdf5(hdf_out4, Ev1)
  EC2 = read_asdf_evt("test[3-4].h5", msr=true)
  inds = [1, 2, 3, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 1]
  for i in 1:length(EC2)
    j = inds[i]
    if j > 0
      compare_SeisHdr(EC2[i].hdr, EvCat[j].hdr)
      compare_SeisSrc(EC2[i].source, EvCat[j].source)
    end
  end
end

# HDF write cleanup
safe_rm(hdf_out1)
safe_rm(hdf_out2)
safe_rm(hdf_out3)
safe_rm(hdf_out4)
