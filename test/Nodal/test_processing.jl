printstyled("  processing of NodalData\n", color=:light_green)

fstr = path*"/SampleFiles/Nodal/Node1_UTC_20200307_170738.006.tdms"
S1 = read_nodal(fstr)

# these should all work
for f in (:convert_seis!, :demean!, :detrend!, :filtfilt!, :merge!, :sync!, :taper!, :ungap!, :unscale!)
  printstyled(string("    ", f, "\n"), color=:light_green)
  getfield(SeisIO, f)(S1)
end
