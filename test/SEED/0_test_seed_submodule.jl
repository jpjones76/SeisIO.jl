# The file test.mseed comes from an older IRIS libmseed, found by anowacki
# It has a more complicated structure than the test.mseed file in more recent
# versions of libmseed, which reads with no issues
printstyled("SEED submodule\n", color=:light_green)
using SeisIO.SEED

printstyled("  info dump\n", color=:light_green)
redirect_stdout(out) do
  dataless_support()
  mseed_support()
  seed_support()
  resp_wont_read()
end

printstyled("  internals\n", color=:light_green)

printstyled("    seed_time\n", color=:light_green)
u16 = ones(UInt16, 3)
u16[3] = 0x0000
@test u2d(1.0e-6*SEED.seed_time(u16, 0x00, 0x00, 0x00, 0)) == DateTime("0001-01-01T00:00:00")

u16[1] = 0x0640 # 1600
u16[2] = 0x003c # 60
@test u2d(1.0e-6*SEED.seed_time(u16, 0x00, 0x00, 0x00, 0)) == DateTime("1600-02-29T00:00:00")

u16[1] = 0x076c # 1900
@test u2d(1.0e-6*SEED.seed_time(u16, 0x00, 0x00, 0x00, 0)) == DateTime("1900-03-01T00:00:00")

u16[1] = 0x07d0 # 2000
@test u2d(1.0e-6*SEED.seed_time(u16, 0x00, 0x00, 0x00, 0)) == DateTime("2000-02-29T00:00:00")

# 23, 59, 59
@test u2d(1.0e-6*SEED.seed_time(u16, 0x17, 0x3b, 0x3b, 0)) == DateTime("2000-02-29T23:59:59")
@test u2d(1.0e-6*SEED.seed_time(u16, 0x17, 0x3b, 0x3b, -110000000)) == DateTime("2000-02-29T23:58:09")
@test u2d(1.0e-6*SEED.seed_time(u16, 0x17, 0x3b, 0x3b, -115900000)) == DateTime("2000-02-29T23:58:03.1")
@test u2d(1.0e-6*SEED.seed_time(u16, 0x17, 0x3b, 0x3b, Int64(typemax(Int32)))) == DateTime("2000-03-01T00:35:46.484")
