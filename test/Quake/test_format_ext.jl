printstyled("  SAC support extensions\n", color=:light_green)

printstyled("    writesac from SeisEvent\n", color=:light_green)
writesac(rse_wb(8))

sac_file    = path*"/SampleFiles/SAC/test_le.sac"
f_stub      = "1981.088.10.38.23.460"
f_out       = f_stub * "..CDV...R.SAC"
sacv7_out   = "v7_out.sac"

test_fs   = 50.0
test_lat  = 41.5764
test_lon  = -87.6194
test_ot   = -0.75
test_stla = 41.54
test_stlo = -87.64
test_mag  = 3.1f0

# Read test file
C = verified_read_data("sac", sac_file, full=true)[1]
ev_lat = C.misc["evla"]
ev_lon = C.misc["evlo"]
ev_dep = C.misc["evdp"]
ev_id  = "8108838" # taken from kevnm

Ev = SeisEvent()
Ev.data = convert(EventTraceData, SeisData(C))
Ev.hdr.mag.val = test_mag
Ev.hdr.loc.dep = ev_dep
Ev.hdr.loc.lat = ev_lat
Ev.hdr.loc.lon = ev_lon
Ev.hdr.id = ev_id

# Write to file
writesac(Ev)
@test safe_isfile(f_out)

# read unmodified file, check for preserved values
C = verified_read_data("sac", f_out, full=true)[1]
@test C.misc["evla"] == ev_lat
@test C.misc["evlo"] == ev_lon
@test C.misc["evdp"] == ev_dep
@test C.misc["mag"] == test_mag
@test string(C.misc["nevid"]) == ev_id

# Modify the original file
printstyled("    SAC v7\n", color=:light_green)
io = open(sac_file, "r")
sac_raw = read(io)
close(io)

# Set version to 7
sac_raw[305] = 0x07

# Set magnitude to test_mag
mag = reinterpret(UInt8, [test_mag])
sac_raw[157:160] .= mag

# Change some values
reset_sacbuf()
dv     = BUF.sac_dv
dv[1]  = 1.0/test_fs
dv[4]  = test_ot
dv[17] = test_lon
dv[18] = test_lat
dv[19] = test_stla
dv[20] = test_stlo
dv2 = deepcopy(dv)
sac_dbl_buf = reinterpret(UInt8, dv)
io = open(sacv7_out, "w")
write(io, sac_raw)
write(io, sac_dbl_buf)
close(io)

C = read_data("sac", sacv7_out, full=true)[1]
@test C.fs == test_fs

printstyled("    fill_sac_evh!\n", color=:light_green)
Ev = SeisEvent()
Ev.data = convert(EventTraceData, SeisData(C))

fill_sac_evh!(Ev, sacv7_out, k=1)
@test Ev.hdr.loc.lat == test_lat
@test Ev.hdr.loc.lon == test_lon
@test Ev.hdr.mag.val == test_mag
@test isapprox(d2u(Ev.hdr.ot) - Ev.data.t[1][1,2]*μs, test_ot, atol=0.001)

printstyled("      big-endian\n", color=:light_green)
sac_be_file = path*"/SampleFiles/SAC/test_be.sac"
io = open(sac_be_file, "r")
sac_raw = read(io)
close(io)
sac_raw[308] = 0x07

reset_sacbuf()
dv .= bswap.(dv2)
sac_dbl_buf = reinterpret(UInt8, dv)

io = open(sacv7_out, "w")
write(io, sac_raw)
write(io, sac_dbl_buf)
close(io)

C = read_data("sac", sacv7_out, full=true)[1]
Ev = SeisEvent()
Ev.data = convert(EventTraceData, SeisData(C))
fill_sac_evh!(Ev, sacv7_out, k=1)
@test Ev.hdr.loc.lat == test_lat
@test Ev.hdr.loc.lon == test_lon
@test isapprox(d2u(Ev.hdr.ot) - Ev.data.t[1][1,2]*μs, test_ot, atol=0.001)
