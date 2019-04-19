# Test: cycle through a phase catalog, getting phase times and requesting data
# This test works identically to the old FDSNevt without the data query
import SeisIO: pcat_start, pcat_end, phase_time, next_phase, parse_chstr, minreq!, first_phase
spad = 10.0
epad = 10.0
to = 30
src = "IRIS"
sta = "PB.B004..EH?,PB.B004..BS?,PB.B001..BS?,PB.B001..EH?"

# First, a well-formatted string
H = FDSNevq("2018-11-30T17:29:29.00", nev=1, src="IRIS")[1]

# Now, not so hot
H = FDSNevq("201103110547", mag=[3.0, 9.9], nev=1, src="IRIS")[1]

# Create channel data
s = H.ot                                      # Start time for FDSNsta is event origin time
t = u2d(d2u(s) + 3600.0)                      # End time is 60 minutes later; we'll truncate
S = FDSNsta(sta, s=s, t=t, to=to)

# Initialize SeisEvent structure
Ev = SeisEvent(hdr = H, data = S)
distaz!(Ev)

# Actual test begins
ot = d2u(Ev.hdr.ot)

for i = 1:Ev.data.n
  if i == 1
    pdat = get_pha(Ev.data.misc[i]["dist"], Ev.hdr.loc[3], pha="", model="do.my.little.dance.on.the.catwalk", to=to) # should break
    pdat = get_pha(Ev.data.misc[i]["dist"], Ev.hdr.loc[3], pha="", to=to)
  elseif i == 2
    pdat = get_pha(Ev.data.misc[i]["dist"], Ev.hdr.loc[3], pha="all", to=to)
  else
    pdat = get_pha(Ev.data.misc[i]["dist"], Ev.hdr.loc[3], pha="ttall", to=to)
  end
  # Check that there's a P phase and an S phase
  for p in String["P","S"]
    j = findfirst(pdat[:,3].==p)
    @test (typeof(j) == Nothing) == false
  end

  # get the start and end of the phase catalog and S arrival time, apply sanity check
  s0 = pcat_start(pdat)
  t0 = pcat_end(pdat)
  ts = phase_time("S", pdat)
  @test s0 ≤ ts ≤ t0
  @test_throws ErrorException phase_time("HEXONXONX", pdat)

  if i == 1
    pdat2 = [pdat; pdat[1:1,:]]
    pha = pdat[1,3]
    t_duplicate = phase_time(pha, pdat2)
  end

  # Get phases
  (p1, s) = first_phase(pdat)
  (p2, t) = next_phase(p1, pdat)
  @test p1 in ["P", "pP"]
  pha_str = string(p1, " : ", p2)

  # Save to Ev.data.misc
  Ev.data.misc[i]["pha_str"] = pha_str
  Ev.data.misc[i]["pha"] = pdat

  # get time window
  s0 = u2d(ot + s - spad)
  t0 = u2d(ot + t + epad)
  (d0, d1) = parsetimewin(s0, t0)
  @test (t0-s0).value < 300000     # Should be short for this test

  # This should not be necessary
  # fill Ev.data with event data
  # S = get_data("FDSN", Ev.data.id[i], s=d0, t=d1, si=false, src=src)
  # Ev.data.t[i] = S.t[1]
  # Ev.data.x[i] = S.x[1]
  # Ev.data.src[i] = S.src[1]
  # @test occursin("fdsnws/dataselect", Ev.data.src[i])
end

# Check that channels contain identical phase arrival estimates
for str in ["pha_str", "pha"]
  @test Ev.data.misc[1][str] == Ev.data.misc[2][str] == Ev.data.misc[3][str] == Ev.data.misc[4][str] == Ev.data.misc[5][str] == Ev.data.misc[6][str] == Ev.data.misc[7][str]
  @test Ev.data.misc[8][str] == Ev.data.misc[9][str] == Ev.data.misc[10][str] == Ev.data.misc[11][str] == Ev.data.misc[12][str] == Ev.data.misc[13][str] == Ev.data.misc[14][str]
end

# These tests are superfluous
# wseis("tohoku.seis", Ev)
# R = rseis("tohoku.seis")[1]
# @test R == Ev
# R = [];
# rm("tohoku.seis");
