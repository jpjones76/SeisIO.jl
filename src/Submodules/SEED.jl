module SEED
using Dates, Markdown, Mmap, Printf, SeisIO, SeisIO.FastIO, SeisIO.Formats
path = Base.source_dir()

const id_positions  = Int8[11, 12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const id_spacer     = 0x2e
const steim         = reverse(collect(0x00000000:0x00000002:0x0000001e), dims=1)
const responses     = Dict{Int64, Any}()
const units_lookup  = Dict{Int64, String}()
const comments      = Dict{Int64, String}()
const abbrev        = Dict{Int64, String}()

# imports
include("SEED/imports.jl")

# files that should be loaded in order
include("SEED/0_seed_read_utils.jl")
include("SEED/1_mSEEDblk.jl")
include("SEED/1_mSEEDdec.jl")
include("SEED/1_dataless_blk.jl")
include("SEED/2_parserec.jl")

# other
include("SEED/dataless.jl")
include("SEED/readmseed.jl")
include("SEED/seed_resp.jl")
include("SEED/seed_support.jl")

# Utils
for i in ls(path*"/SEED/Utils/")
  if endswith(i, ".jl")
    include(i)
  end
end

# exports
include("SEED/exports.jl")

end
