module SEED
using Dates, Printf, SeisIO, SeisIO.Formats
import SeisIO.Formats: formats, FmtVer, FormatDesc, HistVec
import SeisIO:
  BUF,
  InstrumentResponse,
  KW,
  SeedBlk,
  SeisIOBuf,
  TimeSpec,
  check_for_gap!,
  checkbuf!,
  checkbuf_8!,
  endtime,
  fix_units,
  is_u8_digit,
  buf_to_double,
  mktime,
  sμ,
  trunc_x!,
  buf_to_int,
  stream_int,
  y2μs,
  μs

const id_positions  = Int8[11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const id_spacer     = 0x2e
const steim         = reverse(collect(0x00000000:0x00000002:0x0000001e), dims=1)
const responses     = Dict{Int64, Any}()
const units_lookup  = Dict{Int64, String}()
const comments      = Dict{Int64, String}()
const abbrev        = Dict{Int64, String}()

include("SEED/0_seed_read_utils.jl")
include("SEED/1_mSEEDblk.jl")
include("SEED/1_mSEEDdec.jl")
include("SEED/1_dataless_blk.jl")
include("SEED/2_parserec.jl")
include("SEED/dataless.jl")
include("SEED/mseed_support.jl")
include("SEED/readmseed.jl")
include("SEED/seed_resp.jl")

# exports
export  formats,
        mseed_support,
        parsemseed!,
        read_dataless,
        read_mseed_file,
        read_seed_resp!,
        read_seed_resp,
        seed_support
end
