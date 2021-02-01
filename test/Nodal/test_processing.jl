printstyled("  processing of NodalData\n", color=:light_green)

fstr = path*"/SampleFiles/Nodal/Node1_UTC_20200307_170738.006.tdms"
S1 = read_nodal("silixa", fstr)

# these should all work
for f in (:convert_seis!, :demean!, :detrend!, :sync!, :taper!, :ungap!, :unscale!)
  printstyled(string("    ", f, "\n"), color=:light_green)
  getfield(SeisIO, f)(S1)
end

@test_throws ErrorException merge!(S1)
@test Nodal.merge_ext!(S, 1, collect(2:S1.n)) == nothing

# test resampling
printstyled(string("    ", "resample!", "\n"), color=:light_green)
f0 = 500.
S2 = resample(S1,f0)
resample!(S1,f0)
@test S2.data == S1.data

# test filtering
printstyled(string("    ", "filtfilt!", "\n"), color=:light_green)
S2 = filtfilt(S1,rt="Bandpass",fl=100.,fh=200.)
filtfilt!(S1,rt="Bandpass",fl=100.,fh=200.)
@test S2.data == S1.data
